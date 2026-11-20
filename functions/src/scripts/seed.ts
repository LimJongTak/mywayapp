/**
 * 편의시설·리워드 샘플 데이터 등록 (관리자 전용 컬렉션이라 Admin SDK로 넣는다)
 *   GOOGLE_APPLICATION_CREDENTIALS=서비스계정키.json npm run seed
 *   에뮬레이터: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=demo-myway npm run seed
 */
import { initializeApp } from "firebase-admin/app";
import { GeoPoint, getFirestore } from "firebase-admin/firestore";

type Facility = { type: "toilet" | "shelter" | "bike"; name: string; lat: number; lng: number };

const facilities: Facility[] = [
  // 서울 경복궁 일대
  { type: "toilet", name: "경복궁 흥례문 화장실", lat: 37.5779, lng: 126.9768 },
  { type: "toilet", name: "국립민속박물관 화장실", lat: 37.5817, lng: 126.9790 },
  { type: "shelter", name: "경회루 쉼터", lat: 37.5800, lng: 126.9757 },
  { type: "shelter", name: "삼청공원 쉼터", lat: 37.5880, lng: 126.9817 },
  { type: "bike", name: "따릉이 광화문역", lat: 37.5714, lng: 126.9768 },
  { type: "bike", name: "따릉이 경복궁역", lat: 37.5758, lng: 126.9733 },
  // 순천 동천·국가정원 일대
  { type: "toilet", name: "순천만국가정원 동문 화장실", lat: 34.9302, lng: 127.5100 },
  { type: "shelter", name: "동천 산책로 쉼터", lat: 34.9500, lng: 127.4930 },
  { type: "bike", name: "온누리 자전거 순천역", lat: 34.9455, lng: 127.5030 },
];

const rewards = [
  { id: "coffee-1000", title: "아메리카노 1,000원 할인", partnerName: "순천 동천카페", cost: 1000, stock: 100 },
  { id: "bakery-10", title: "빵 10% 할인", partnerName: "서촌 베이커리", cost: 800, stock: 50 },
  { id: "bike-1h", title: "자전거 대여 1시간 무료", partnerName: "온누리 자전거", cost: 1500, stock: 30 },
];

async function main() {
  initializeApp();
  const db = getFirestore();
  const batch = db.batch();
  for (const f of facilities) {
    batch.set(db.collection("facilities").doc(), {
      type: f.type,
      name: f.name,
      location: new GeoPoint(f.lat, f.lng),
    });
  }
  for (const r of rewards) {
    const { id, ...rest } = r;
    batch.set(db.collection("rewards").doc(id), { ...rest, active: true });
  }
  await batch.commit();
  console.log(`✅ 편의시설 ${facilities.length}건, 리워드 ${rewards.length}건 등록 완료`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
