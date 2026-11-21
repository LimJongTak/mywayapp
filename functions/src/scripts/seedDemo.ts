/**
 * 로컬 에뮬레이터용 데모 데이터 (데모 계정 + 산책로 + 게시글 + 편의시설 + 리워드)
 *
 *   1) firebase emulators:start --project demo-myway
 *   2) cd functions && npm run seed:demo
 *
 * 로그인: demo@myway.uk / demo1234 (관리자 권한 포함)
 * 안전장치: 에뮬레이터가 아닌 실제 프로젝트에는 절대 실행되지 않는다.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { GeoPoint, Timestamp, getFirestore } from "firebase-admin/firestore";

// Windows/macOS 공통으로 동작하도록 환경변수를 코드에서 지정
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";
const PROJECT_ID = process.env.GCLOUD_PROJECT ?? "demo-myway";
if (!PROJECT_ID.startsWith("demo-")) {
  console.error("❌ 데모 시드는 demo- 로 시작하는 에뮬레이터 프로젝트에서만 실행할 수 있습니다.");
  process.exit(1);
}

initializeApp({ projectId: PROJECT_ID });
const db = getFirestore();
const auth = getAuth();
const ago = (h: number) => Timestamp.fromMillis(Date.now() - h * 3600e3);
const shape = (lat: number, lng: number) =>
  [[0, 0], [0.0012, 0.0004], [0.0021, 0.0016], [0.0018, 0.0031], [0.0006, 0.0036]].map(
    ([a, b]) => new GeoPoint(lat + a, lng + b),
  );

async function main() {
  const email = "demo@myway.uk";
  const existing = await auth.getUserByEmail(email).catch(() => null);
  if (existing) {
    console.log("ℹ️  데모 데이터가 이미 있습니다. 다시 만들려면 에뮬레이터를 재시작하세요.");
    return;
  }
  const u = await auth.createUser({ email, password: "demo1234", emailVerified: true });
  await auth.setCustomUserClaims(u.uid, { admin: true });
  await db.doc(`users/${u.uid}`).set({
    nickname: "워크홀릭", email, photoUrl: null, points: 1870, referralCode: "WALK7KQ",
    referredBy: null, trailCount: 0, walkCount: 12, totalWalkM: 18400, createdAt: ago(240),
  });
  await db.doc("nicknames/워크홀릭").set({ uid: u.uid });
  await db.doc("referralCodes/WALK7KQ").set({ uid: u.uid });
  for (const [amount, reason, h] of [
    [500, "첫 가입 축하 포인트", 240],
    [300, "추천인 코드 입력 보너스", 240],
    [35, "산책 완료 - 서촌 골목 산책", 30],
  ] as const) {
    await db.collection(`users/${u.uid}/pointLogs`).add({ amount, reason, createdAt: ago(h) });
  }

  const trails: [string, string, string[], string, number, number][] = [
    ["경복궁 돌담길", "경복궁 담장을 따라 걷는 고즈넉한 산책로. 해 질 녘 추천!", ["궁궐", "노을뷰", "데이트"], "city", 37.576, 126.9745],
    ["서촌 골목 산책", "카페와 갤러리가 이어지는 서촌 골목길", ["카페", "골목"], "city", 37.579, 126.9705],
    ["삼청동 야경 코스", "삼청동 언덕에서 바라보는 도심 야경", ["야경", "인생사진"], "night", 37.5845, 126.9815],
    ["청계천 반려견 코스", "물길 따라 반려견과 함께 걷기 좋은 길", ["반려견", "강변"], "dog", 37.57, 126.979],
    ["북촌 한옥마을 길", "한옥 사이로 이어진 정겨운 길", ["한옥", "피크닉"], "family", 37.582, 126.985],
  ];
  const reviewers = ["산책길", "강아지맘", "서촌러"];
  for (const [i, [title, description, tags, category, lat, lng]] of trails.entries()) {
    const path = shape(lat, lng);
    const ref = await db.collection("trails").add({
      ownerId: u.uid, ownerName: "워크홀릭", title, description, tags, category, path,
      distanceM: 697, durationMin: 10, startLocation: path[0], photoUrl: null, photoPath: null,
      ratingAvg: 0, ratingCount: 0, favoriteCount: 0, walkCount: 10 + i * 7,
      createdAt: ago(i * 5), updatedAt: ago(i * 5),
    });
    // 리뷰 → onReviewWritten 트리거가 평균 평점을 계산
    for (const [j, name] of reviewers.entries()) {
      await ref.collection("reviews").doc(`demo-${j}`).set({
        rating: j === 2 ? 4 : 5, text: "좋은 산책로예요!", authorName: name, createdAt: ago(j + 1),
      });
    }
  }

  const facilities: [string, string, number, number][] = [
    ["toilet", "경복궁 화장실", 37.5779, 126.9768],
    ["shelter", "경회루 쉼터", 37.58, 126.9757],
    ["bike", "따릉이 광화문역", 37.573, 126.9768],
    ["toilet", "삼청공원 화장실", 37.586, 126.98],
  ];
  for (const [type, name, a, b] of facilities) {
    await db.collection("facilities").add({ type, name, location: new GeoPoint(a, b) });
  }

  const posts: [string, string, number][] = [
    ["free", "새로운 산책로 발견!", 231], ["free", "강아지와 함께 산책하기 좋은 곳", 198],
    ["free", "산책로 청소 활동 후기", 145], ["notice", "MyWay 정식 오픈 안내", 512],
    ["qna", "포인트는 언제 적립되나요?", 33],
  ];
  for (const [i, [board, title, viewCount]] of posts.entries()) {
    await db.collection("posts").add({
      board, title, content: "본문 내용입니다.", authorId: u.uid,
      authorName: board === "notice" ? "운영자" : "워크홀릭",
      viewCount, commentCount: 0, createdAt: ago(i * 5 + 1), updatedAt: ago(i * 5 + 1),
    });
  }

  for (const [id, title, partnerName, cost, stock] of [
    ["coffee-1000", "아메리카노 1,000원 할인", "순천 동천카페", 1000, 100],
    ["bakery-10", "빵 10% 할인", "서촌 베이커리", 800, 50],
    ["bike-1h", "자전거 대여 1시간 무료", "온누리 자전거", 1500, 30],
  ] as const) {
    await db.doc(`rewards/${id}`).set({ title, partnerName, cost, stock, active: true });
  }
  console.log("✅ 데모 데이터 생성 완료 — 로그인: demo@myway.uk / demo1234");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
