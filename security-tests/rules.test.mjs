// Firestore / Storage 보안 규칙 테스트 (에뮬레이터)
import { readFileSync } from "node:fs";
import { after, before, beforeEach, describe, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  GeoPoint,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
  deleteDoc,
  addDoc,
  collection,
  increment,
} from "firebase/firestore";
import { ref, uploadBytes } from "firebase/storage";

let env;
const verified = { email: "a@test.com", email_verified: true, firebase: { sign_in_provider: "password" } };
const unverified = { email: "b@test.com", email_verified: false, firebase: { sign_in_provider: "password" } };

const trail = (uid, extra = {}) => ({
  ownerId: uid,
  ownerName: "alice",
  title: "경복궁 한바퀴",
  description: "좋아요",
  tags: ["궁궐"],
  category: "general",
  path: [new GeoPoint(37.57, 126.97), new GeoPoint(37.58, 126.97)],
  distanceM: 1100,
  durationMin: 16,
  startLocation: new GeoPoint(37.57, 126.97),
  photoUrl: null,
  photoPath: null,
  ratingAvg: 0,
  ratingCount: 0,
  favoriteCount: 0,
  walkCount: 0,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

const post = (uid, extra = {}) => ({
  board: "free",
  title: "안녕하세요",
  content: "첫 글",
  authorId: uid,
  authorName: "alice",
  viewCount: 0,
  commentCount: 0,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-myway",
    firestore: { rules: readFileSync("../firestore.rules", "utf8") },
    storage: { rules: readFileSync("../storage.rules", "utf8") },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "users/alice"), { nickname: "alice", points: 500 });
    await setDoc(doc(db, "users/bob"), { nickname: "bob", points: 500 });
    await setDoc(doc(db, "trails/t1"), trail("alice", { createdAt: new Date(), updatedAt: new Date() }));
    await setDoc(doc(db, "posts/p1"), post("alice", { createdAt: new Date(), updatedAt: new Date() }));
  });
});

const alice = () => env.authenticatedContext("alice", verified).firestore();
const bob = () => env.authenticatedContext("bob", { ...verified, email: "bob@test.com" }).firestore();
const anon = () => env.unauthenticatedContext().firestore();

describe("users", () => {
  test("본인만 프로필 읽기", async () => {
    await assertSucceeds(getDoc(doc(alice(), "users/alice")));
    await assertFails(getDoc(doc(bob(), "users/alice")));
  });
  test("클라이언트는 포인트를 수정할 수 없음", async () => {
    await assertFails(updateDoc(doc(alice(), "users/alice"), { points: 999999 }));
    await assertFails(updateDoc(doc(alice(), "users/alice"), { points: increment(10) }));
  });
  test("클라이언트는 프로필을 직접 생성할 수 없음", async () => {
    await assertFails(setDoc(doc(env.authenticatedContext("carol", verified).firestore(), "users/carol"), { nickname: "c", points: 1e9 }));
  });
  test("포인트 내역은 서버만 기록", async () => {
    await assertFails(addDoc(collection(alice(), "users/alice/pointLogs"), { amount: 1000 }));
  });
});

describe("trails", () => {
  test("누구나 읽기 가능", async () => {
    await assertSucceeds(getDoc(doc(anon(), "trails/t1")));
  });
  test("인증된 사용자 등록 성공", async () => {
    await assertSucceeds(setDoc(doc(alice(), "trails/t2"), trail("alice")));
  });
  test("이메일 미인증 사용자 등록 실패", async () => {
    const db = env.authenticatedContext("alice", unverified).firestore();
    await assertFails(setDoc(doc(db, "trails/t2"), trail("alice")));
  });
  test("타인 명의로 등록 실패", async () => {
    await assertFails(setDoc(doc(bob(), "trails/t2"), trail("alice")));
  });
  test("평점 조작 등록 실패", async () => {
    await assertFails(setDoc(doc(alice(), "trails/t2"), trail("alice", { ratingAvg: 5, ratingCount: 100 })));
  });
  test("허용되지 않은 필드 추가 실패", async () => {
    await assertFails(setDoc(doc(alice(), "trails/t2"), trail("alice", { isFeatured: true })));
  });
  test("닉네임 사칭 실패", async () => {
    await assertFails(setDoc(doc(alice(), "trails/t2"), trail("alice", { ownerName: "운영자" })));
  });
  test("소유자 제목 수정 성공 / 경로·집계 수정 실패", async () => {
    await assertSucceeds(updateDoc(doc(alice(), "trails/t1"), { title: "새 제목", updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(alice(), "trails/t1"), { ratingAvg: 5, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(alice(), "trails/t1"), { path: [], updatedAt: serverTimestamp() }));
  });
  test("타인 수정/삭제 실패", async () => {
    await assertFails(updateDoc(doc(bob(), "trails/t1"), { title: "해킹", updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(bob(), "trails/t1")));
  });
  test("관리자는 삭제 가능", async () => {
    const admin = env.authenticatedContext("admin", { ...verified, admin: true }).firestore();
    await assertSucceeds(deleteDoc(doc(admin, "trails/t1")));
  });
});

describe("reviews", () => {
  const review = (name = "bob", rating = 5) => ({ rating, text: "좋아요", authorName: name, createdAt: serverTimestamp() });
  test("본인 uid 문서로만 리뷰 작성", async () => {
    await assertSucceeds(setDoc(doc(bob(), "trails/t1/reviews/bob"), review()));
    await assertFails(setDoc(doc(bob(), "trails/t1/reviews/alice"), review()));
  });
  test("평점 범위 검증", async () => {
    await assertFails(setDoc(doc(bob(), "trails/t1/reviews/bob"), review("bob", 6)));
    await assertFails(setDoc(doc(bob(), "trails/t1/reviews/bob"), review("bob", 0)));
  });
});

describe("posts", () => {
  test("자유게시판 작성 성공", async () => {
    await assertSucceeds(setDoc(doc(alice(), "posts/p2"), post("alice")));
  });
  test("일반 사용자는 공지사항 작성 불가", async () => {
    await assertFails(setDoc(doc(alice(), "posts/p2"), post("alice", { board: "notice" })));
  });
  test("관리자는 공지사항 작성 가능", async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), "users/admin"), { nickname: "운영자" }));
    const admin = env.authenticatedContext("admin", { ...verified, admin: true }).firestore();
    await assertSucceeds(setDoc(doc(admin, "posts/p2"), post("admin", { board: "notice", authorName: "운영자" })));
  });
  test("조회수 직접 조작 불가", async () => {
    await assertFails(updateDoc(doc(alice(), "posts/p1"), { viewCount: 9999 }));
    await assertFails(updateDoc(doc(bob(), "posts/p1"), { viewCount: increment(1) }));
  });
  test("타인 글 수정 불가", async () => {
    await assertFails(updateDoc(doc(bob(), "posts/p1"), { title: "x", updatedAt: serverTimestamp() }));
  });
  test("댓글 작성 / 사칭 불가", async () => {
    const c = { authorId: "bob", authorName: "bob", content: "댓글", createdAt: serverTimestamp() };
    await assertSucceeds(addDoc(collection(bob(), "posts/p1/comments"), c));
    await assertFails(addDoc(collection(bob(), "posts/p1/comments"), { ...c, authorId: "alice" }));
  });
  test("비로그인 작성 불가", async () => {
    await assertFails(setDoc(doc(anon(), "posts/p3"), post("alice")));
  });
});

describe("inquiries", () => {
  const inq = (uid) => ({ uid, authorName: uid, title: "문의", content: "내용", status: "open", answer: null, createdAt: serverTimestamp(), answeredAt: null });
  test("본인 문의만 읽기, 답변은 관리자만", async () => {
    await assertSucceeds(setDoc(doc(alice(), "inquiries/q1"), inq("alice")));
    await assertSucceeds(getDoc(doc(alice(), "inquiries/q1")));
    await assertFails(getDoc(doc(bob(), "inquiries/q1")));
    await assertFails(updateDoc(doc(alice(), "inquiries/q1"), { answer: "셀프답변", status: "answered", answeredAt: serverTimestamp() }));
    const admin = env.authenticatedContext("admin", { ...verified, admin: true }).firestore();
    await assertSucceeds(updateDoc(doc(admin, "inquiries/q1"), { answer: "답변", status: "answered", answeredAt: serverTimestamp() }));
  });
});

describe("server-only collections", () => {
  test("rewards/facilities 쓰기 금지, 추천코드 조회 금지", async () => {
    await assertFails(setDoc(doc(alice(), "rewards/r1"), { cost: 0, stock: 1e6, active: true }));
    await assertFails(setDoc(doc(alice(), "facilities/f1"), { type: "toilet" }));
    await assertFails(getDoc(doc(alice(), "referralCodes/ABCDEFG")));
    await assertFails(getDoc(doc(alice(), "nicknames/alice")));
  });
});

describe("storage", () => {
  const img = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);
  test("본인 폴더에 이미지 업로드 성공", async () => {
    const s = env.authenticatedContext("alice", verified).storage();
    await assertSucceeds(uploadBytes(ref(s, "users/alice/trails/123.jpg"), img, { contentType: "image/jpeg" }));
  });
  test("타인 폴더 업로드 실패", async () => {
    const s = env.authenticatedContext("bob", verified).storage();
    await assertFails(uploadBytes(ref(s, "users/alice/trails/123.jpg"), img, { contentType: "image/jpeg" }));
  });
  test("이미지가 아닌 파일 업로드 실패", async () => {
    const s = env.authenticatedContext("alice", verified).storage();
    await assertFails(uploadBytes(ref(s, "users/alice/trails/evil.jpg"), img, { contentType: "text/html" }));
  });
  test("5MB 초과 업로드 실패", async () => {
    const s = env.authenticatedContext("alice", verified).storage();
    const big = new Uint8Array(5 * 1024 * 1024 + 1);
    await assertFails(uploadBytes(ref(s, "users/alice/trails/big.jpg"), big, { contentType: "image/jpeg" }));
  });
});
