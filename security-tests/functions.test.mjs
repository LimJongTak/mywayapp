// Cloud Functions 통합 테스트 (Auth + Firestore + Functions 에뮬레이터)
import assert from "node:assert/strict";
import { after, before, describe, test } from "node:test";
import { initializeApp, deleteApp } from "firebase/app";
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth, signOut } from "firebase/auth";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";
import { initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { GeoPoint, doc, getDoc, setDoc } from "firebase/firestore";

let app, auth, fns, env;
const call = (name, data) => httpsCallable(fns, name)(data).then((r) => r.data);
const admin = async (fn) => {
  let out;
  await env.withSecurityRulesDisabled(async (ctx) => {
    out = await fn(ctx.firestore());
  });
  return out;
};
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

before(async () => {
  app = initializeApp({ projectId: "demo-myway", apiKey: "fake-key" }, "fn-test");
  auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  fns = getFunctions(app, "asia-northeast3");
  connectFunctionsEmulator(fns, "127.0.0.1", 5001);
  env = await initializeTestEnvironment({ projectId: "demo-myway", firestore: { host: "127.0.0.1", port: 8080 } });
  await env.clearFirestore();
});
after(async () => {
  await env?.cleanup();
  await deleteApp(app);
});

describe("회원가입 / 추천인", () => {
  let aliceUid, aliceCode;

  test("가입 보너스 500P", async () => {
    const cred = await createUserWithEmailAndPassword(auth, `alice${Date.now()}@t.com`, "abcd1234");
    aliceUid = cred.user.uid;
    const res = await call("initProfile", { nickname: "앨리스" });
    assert.equal(res.created, true);
    assert.equal(res.points, 500);
    const snap = await admin((db) => getDoc(doc(db, `users/${aliceUid}`)));
    aliceCode = snap.get("referralCode");
    assert.match(aliceCode, /^[A-Z2-9]{7}$/);
  });

  test("initProfile 멱등 (중복 지급 없음)", async () => {
    const res = await call("initProfile", { nickname: "앨리스" });
    assert.equal(res.created, false);
  });

  test("닉네임 중복/형식 검증", async () => {
    await signOut(auth);
    await createUserWithEmailAndPassword(auth, `dup${Date.now()}@t.com`, "abcd1234");
    await assert.rejects(call("initProfile", { nickname: "앨리스" }), /이미 사용 중/);
    await assert.rejects(call("initProfile", { nickname: "<script>" }), /닉네임/);
    await assert.rejects(call("initProfile", { nickname: "바비", referralCode: "ZZZZZZZ" }), /추천인/);
  });

  test("추천인 코드: 양쪽 300P", async () => {
    const res = await call("initProfile", { nickname: "바비", referralCode: aliceCode });
    assert.equal(res.points, 800);
    const alice = await admin((db) => getDoc(doc(db, `users/${aliceUid}`)));
    assert.equal(alice.get("points"), 800);
  });

  test("비로그인 호출 거부", async () => {
    await signOut(auth);
    await assert.rejects(call("initProfile", { nickname: "익명" }), /로그인/);
  });
});

describe("산책 완료 보상", () => {
  const path = Array.from({ length: 20 }, (_, i) => ({ lat: 37.576 + i * 0.00047, lng: 126.977 }));

  before(async () => {
    await createUserWithEmailAndPassword(auth, `walker${Date.now()}@t.com`, "abcd1234");
    await call("initProfile", { nickname: "워커" });
    await admin((db) =>
      setDoc(doc(db, "trails/walkTrail"), {
        ownerId: "someone",
        ownerName: "x",
        title: "테스트 산책로",
        path: path.map((p) => new GeoPoint(p.lat, p.lng)),
        distanceM: 1000,
        walkCount: 0,
      }),
    );
  });

  test("정상 산책 → 포인트 적립", async () => {
    const now = Date.now();
    const r = await call("completeWalk", { trailId: "walkTrail", path, startedAt: now - 15 * 60_000, endedAt: now });
    assert.equal(r.verified, true);
    assert.equal(r.points, 19); // 10 + floor(0.99km * 10)
  });

  test("같은 산책로 당일 재보상 없음", async () => {
    const now = Date.now();
    const r = await call("completeWalk", { trailId: "walkTrail", path, startedAt: now - 15 * 60_000, endedAt: now });
    assert.equal(r.points, 0);
  });

  test("차량 속도 → 미인정", async () => {
    const now = Date.now();
    const r = await call("completeWalk", { trailId: "walkTrail", path, startedAt: now - 60_000, endedAt: now });
    assert.equal(r.verified, false);
    assert.equal(r.points, 0);
  });

  test("잘못된 입력 거부", async () => {
    await assert.rejects(call("completeWalk", { trailId: "../x", path, startedAt: 1, endedAt: 2 }));
    await assert.rejects(call("completeWalk", { trailId: "walkTrail", path: [{ lat: 999, lng: 0 }], startedAt: 1, endedAt: 2 }));
  });
});

describe("리워드 교환", () => {
  before(async () => {
    await admin((db) =>
      setDoc(doc(db, "rewards/coffee"), { title: "커피", partnerName: "카페", cost: 300, stock: 1, active: true }),
    );
  });

  test("교환 성공 → 포인트/재고 차감", async () => {
    const r = await call("redeemReward", { rewardId: "coffee" });
    assert.match(r.code, /^MW-/);
    const reward = await admin((db) => getDoc(doc(db, "rewards/coffee")));
    assert.equal(reward.get("stock"), 0);
  });

  test("재고 소진 시 실패", async () => {
    await assert.rejects(call("redeemReward", { rewardId: "coffee" }), /소진/);
  });
});

describe("조회수", () => {
  test("사용자당 1회만 증가", async () => {
    await admin((db) => setDoc(doc(db, "posts/vp"), { title: "t", viewCount: 0 }));
    await call("viewPost", { postId: "vp" });
    await call("viewPost", { postId: "vp" });
    const p = await admin((db) => getDoc(doc(db, "posts/vp")));
    assert.equal(p.get("viewCount"), 1);
  });
});

describe("관리자 함수", () => {
  test("일반 사용자는 setAdmin 불가", async () => {
    await assert.rejects(call("setAdmin", { uid: auth.currentUser.uid, admin: true }), /관리자/);
  });
});

describe("집계 트리거", () => {
  test("리뷰 작성 → 평균 평점 갱신", async () => {
    await admin(async (db) => {
      await setDoc(doc(db, "trails/walkTrail/reviews/u1"), { rating: 5 });
      await setDoc(doc(db, "trails/walkTrail/reviews/u2"), { rating: 4 });
    });
    let avg;
    for (let i = 0; i < 20; i++) {
      await sleep(500);
      const t = await admin((db) => getDoc(doc(db, "trails/walkTrail")));
      avg = t.get("ratingAvg");
      if (t.get("ratingCount") === 2) break;
    }
    assert.equal(avg, 4.5);
  });
});
