/**
 * 순수 비즈니스 로직 (Firebase 의존성 없음) — 단위 테스트 대상.
 * 포인트 정책 / 산책 검증 / 입력 검증을 한 곳에서 관리한다.
 */

export const POINTS = {
  SIGNUP_BONUS: 500,
  REFERRAL_NEW_USER: 300,
  REFERRAL_REFERRER: 300,
  WALK_BASE: 10,
  WALK_PER_KM: 10,
  WALK_MAX: 100,
  TRAIL_CREATED: 50,
  DAILY_WALK_REWARD_LIMIT: 5,
} as const;

export interface LatLng {
  lat: number;
  lng: number;
}

const EARTH_RADIUS_M = 6371000;
const toRad = (d: number) => (d * Math.PI) / 180;

export function haversine(a: LatLng, b: LatLng): number {
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(h)));
}

export function pathDistance(path: LatLng[]): number {
  let total = 0;
  for (let i = 1; i < path.length; i++) total += haversine(path[i - 1], path[i]);
  return total;
}

export function isValidLatLng(p: unknown): p is LatLng {
  if (typeof p !== "object" || p === null) return false;
  const { lat, lng } = p as Record<string, unknown>;
  return (
    typeof lat === "number" &&
    typeof lng === "number" &&
    Number.isFinite(lat) &&
    Number.isFinite(lng) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180
  );
}

/** 점 p에서 경로(polyline)의 가장 가까운 꼭짓점까지의 거리 (근사) */
export function minDistanceToPath(p: LatLng, path: LatLng[]): number {
  let min = Infinity;
  for (const q of path) min = Math.min(min, haversine(p, q));
  return min;
}

export interface WalkCheckInput {
  trailPath: LatLng[];
  trailDistanceM: number;
  walkedPath: LatLng[];
  durationSec: number;
}

export interface WalkCheckResult {
  ok: boolean;
  reason?: string;
  walkedDistanceM: number;
  coverage: number;
}

/**
 * 산책 완료 검증 (부정 적립 방지)
 *  - 최소 기록 지점 수
 *  - 평균 속도 상한 (걷기 기준 시속 9km 이하)
 *  - 산책로 경로 꼭짓점의 70% 이상을 반경 50m 이내로 지나야 함
 *  - 이동 거리가 산책로 거리의 60% 이상
 */
export function checkWalk(input: WalkCheckInput): WalkCheckResult {
  const { trailPath, trailDistanceM, walkedPath, durationSec } = input;
  const walkedDistanceM = pathDistance(walkedPath);
  const fail = (reason: string, coverage = 0): WalkCheckResult => ({
    ok: false,
    reason,
    walkedDistanceM,
    coverage,
  });

  if (walkedPath.length < 5) return fail("기록된 위치가 너무 적습니다.");
  if (durationSec < 60) return fail("산책 시간이 너무 짧습니다.");

  const speedKmh = walkedDistanceM / 1000 / (durationSec / 3600);
  if (speedKmh > 9) return fail("이동 속도가 걷기 속도를 초과했습니다.");

  // 산책로 꼭짓점 샘플링(최대 100개)으로 커버리지 계산
  const step = Math.max(1, Math.floor(trailPath.length / 100));
  let checked = 0;
  let covered = 0;
  for (let i = 0; i < trailPath.length; i += step) {
    checked++;
    if (minDistanceToPath(trailPath[i], walkedPath) <= 50) covered++;
  }
  const coverage = checked === 0 ? 0 : covered / checked;
  if (coverage < 0.7) return fail("산책로 경로를 충분히 따라 걷지 않았습니다.", coverage);
  if (walkedDistanceM < trailDistanceM * 0.6)
    return fail("이동 거리가 부족합니다.", coverage);

  return { ok: true, walkedDistanceM, coverage };
}

export function walkPoints(distanceM: number): number {
  const pts = POINTS.WALK_BASE + Math.floor((distanceM / 1000) * POINTS.WALK_PER_KM);
  return Math.min(POINTS.WALK_MAX, pts);
}

export function sanitizeText(v: unknown, min: number, max: number): string | null {
  if (typeof v !== "string") return null;
  const s = v.trim();
  if (s.length < min || s.length > max) return null;
  return s;
}

const NICKNAME_RE = /^[0-9A-Za-z가-힣_]{2,12}$/;
export function isValidNickname(v: unknown): v is string {
  return typeof v === "string" && NICKNAME_RE.test(v);
}

const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 혼동되는 문자(0,O,1,I) 제외
export function generateCode(len: number, rand: () => number = Math.random): string {
  let s = "";
  for (let i = 0; i < len; i++) s += CODE_CHARS[Math.floor(rand() * CODE_CHARS.length)];
  return s;
}

/** KST 기준 yyyy-MM-dd */
export function kstDateKey(date: Date): string {
  const kst = new Date(date.getTime() + 9 * 3600 * 1000);
  return kst.toISOString().slice(0, 10);
}
