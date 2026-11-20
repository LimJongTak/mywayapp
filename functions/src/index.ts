/**
 * MyWay Cloud Functions (서울 리전: asia-northeast3)
 *
 * 포인트·카운터·조회수처럼 위변조되면 안 되는 값은 오직 이 서버 코드에서만 쓴다.
 * Firestore 보안 규칙은 클라이언트가 해당 필드를 직접 수정하지 못하게 막는다.
 */
import { randomInt } from "node:crypto";
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import {
  AggregateField,
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import { setGlobalOptions } from "firebase-functions/v2";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import {
  onDocumentDeleted,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import {
  POINTS,
  checkWalk,
  generateCode,
  isValidLatLng,
  isValidNickname,
  kstDateKey,
  LatLng,
  walkPoints,
} from "./rules";

initializeApp();
const db = getFirestore();

setGlobalOptions({ region: "asia-northeast3", maxInstances: 10 });

/** 운영 환경에서는 App Check 토큰이 없는 요청(봇/스크립트)을 거부한다. functions/.env 참고 */
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK !== "false";
const callOpts = { enforceAppCheck: ENFORCE_APP_CHECK, cors: true };

const secureRandom = () => randomInt(0, 1_000_000) / 1_000_000;

function requireAuth(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
  return req.auth.uid;
}

function requireAdmin(req: CallableRequest): string {
  const uid = requireAuth(req);
  if (req.auth?.token.admin !== true) {
    throw new HttpsError("permission-denied", "관리자 권한이 필요합니다.");
  }
  return uid;
}

function pointLog(uid: string) {
  return db.collection("users").doc(uid).collection("pointLogs").doc();
}

// ───────────────────────────── 회원 ─────────────────────────────

/**
 * 최초 로그인 후 프로필 생성 (이메일/구글 공통). 멱등.
 * 가입 보너스 + 추천인 코드 보너스를 트랜잭션으로 지급한다.
 */
export const initProfile = onCall(callOpts, async (req) => {
  const uid = requireAuth(req);
  const { nickname, referralCode } = (req.data ?? {}) as {
    nickname?: unknown;
    referralCode?: unknown;
  };
  if (!isValidNickname(nickname)) {
    throw new HttpsError(
      "invalid-argument",
      "닉네임은 2~12자의 한글/영문/숫자/_ 만 가능합니다.",
    );
  }
  const refCode =
    typeof referralCode === "string" && referralCode.trim()
      ? referralCode.trim().toUpperCase()
      : null;
  if (refCode && !/^[A-Z0-9]{6,8}$/.test(refCode)) {
    throw new HttpsError("invalid-argument", "추천인 코드 형식이 올바르지 않습니다.");
  }

  const userRef = db.collection("users").doc(uid);
  const nickRef = db.collection("nicknames").doc(nickname.toLowerCase());

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (userSnap.exists) return { created: false };

    const nickSnap = await tx.get(nickRef);
    if (nickSnap.exists) {
      throw new HttpsError("already-exists", "이미 사용 중인 닉네임입니다.");
    }

    let referrerUid: string | null = null;
    if (refCode) {
      const refSnap = await tx.get(db.collection("referralCodes").doc(refCode));
      if (!refSnap.exists) {
        throw new HttpsError("not-found", "존재하지 않는 추천인 코드입니다.");
      }
      referrerUid = refSnap.get("uid") as string;
      if (referrerUid === uid) referrerUid = null;
    }

    // 충돌 없는 내 추천 코드 생성
    let myCode = "";
    for (let i = 0; i < 5; i++) {
      const candidate = generateCode(7, secureRandom);
      const s = await tx.get(db.collection("referralCodes").doc(candidate));
      if (!s.exists) {
        myCode = candidate;
        break;
      }
    }
    if (!myCode) throw new HttpsError("internal", "잠시 후 다시 시도해 주세요.");

    const user = await getAuth().getUser(uid);
    const now = FieldValue.serverTimestamp();
    let points = POINTS.SIGNUP_BONUS;
    if (referrerUid) points += POINTS.REFERRAL_NEW_USER;

    tx.set(userRef, {
      nickname,
      email: user.email ?? null,
      photoUrl: user.photoURL ?? null,
      points,
      referralCode: myCode,
      referredBy: referrerUid,
      trailCount: 0,
      walkCount: 0,
      totalWalkM: 0,
      createdAt: now,
    });
    tx.set(nickRef, { uid });
    tx.set(db.collection("referralCodes").doc(myCode), { uid });
    tx.set(pointLog(uid), {
      amount: POINTS.SIGNUP_BONUS,
      reason: "첫 가입 축하 포인트",
      createdAt: now,
    });
    if (referrerUid) {
      tx.set(pointLog(uid), {
        amount: POINTS.REFERRAL_NEW_USER,
        reason: "추천인 코드 입력 보너스",
        createdAt: now,
      });
      tx.update(db.collection("users").doc(referrerUid), {
        points: FieldValue.increment(POINTS.REFERRAL_REFERRER),
      });
      tx.set(pointLog(referrerUid), {
        amount: POINTS.REFERRAL_REFERRER,
        reason: `친구 추천 보너스 (${nickname})`,
        createdAt: now,
      });
    }
    return { created: true, points };
  });
});

/** 닉네임 변경 (중복 방지를 위해 서버에서 처리) */
export const updateNickname = onCall(callOpts, async (req) => {
  const uid = requireAuth(req);
  const nickname = (req.data ?? {}).nickname;
  if (!isValidNickname(nickname)) {
    throw new HttpsError("invalid-argument", "닉네임은 2~12자의 한글/영문/숫자/_ 만 가능합니다.");
  }
  const userRef = db.collection("users").doc(uid);
  await db.runTransaction(async (tx) => {
    const user = await tx.get(userRef);
    if (!user.exists) throw new HttpsError("failed-precondition", "프로필이 없습니다.");
    const old = (user.get("nickname") as string).toLowerCase();
    const newKey = nickname.toLowerCase();
    if (old === newKey) {
      tx.update(userRef, { nickname });
      return;
    }
    const nickRef = db.collection("nicknames").doc(newKey);
    if ((await tx.get(nickRef)).exists) {
      throw new HttpsError("already-exists", "이미 사용 중인 닉네임입니다.");
    }
    tx.delete(db.collection("nicknames").doc(old));
    tx.set(nickRef, { uid });
    tx.update(userRef, { nickname });
  });
  return { ok: true };
});

/** 회원 탈퇴: 개인 데이터 삭제 + 작성 콘텐츠 익명화 + Auth 계정 삭제 */
export const deleteAccount = onCall(callOpts, async (req) => {
  const uid = requireAuth(req);
  // 탈취된 오래된 세션으로 탈퇴하는 것을 막기 위해 최근 5분 내 로그인 요구
  const authTime = req.auth?.token.auth_time ?? 0;
  if (Date.now() / 1000 - authTime > 300) {
    throw new HttpsError("failed-precondition", "보안을 위해 다시 로그인한 뒤 탈퇴를 진행해주세요.");
  }
  const userRef = db.collection("users").doc(uid);
  const user = await userRef.get();
  if (user.exists) {
    const nickname = user.get("nickname") as string | undefined;
    const code = user.get("referralCode") as string | undefined;
    if (nickname) await db.collection("nicknames").doc(nickname.toLowerCase()).delete();
    if (code) await db.collection("referralCodes").doc(code).delete();
  }
  // 내가 만든 산책로는 삭제 (사진 포함), 게시글은 익명화
  const trails = await db.collection("trails").where("ownerId", "==", uid).get();
  for (const t of trails.docs) await db.recursiveDelete(t.ref);
  const posts = await db.collection("posts").where("authorId", "==", uid).get();
  const batch = db.batch();
  posts.docs.forEach((p) => batch.update(p.ref, { authorName: "탈퇴한 회원" }));
  await batch.commit();
  await getStorage()
    .bucket()
    .deleteFiles({ prefix: `users/${uid}/` })
    .catch((e) => logger.warn("storage cleanup failed", e));
  await db.recursiveDelete(userRef);
  await getAuth().deleteUser(uid);
  return { ok: true };
});

// ───────────────────────────── 산책 / 보상 ─────────────────────────────

/**
 * 산책 완료 → 서버에서 경로를 검증한 뒤 포인트 지급.
 * 하루 보상 횟수 제한 + 같은 산책로 하루 1회 보상.
 */
export const completeWalk = onCall(callOpts, async (req) => {
  const uid = requireAuth(req);
  const { trailId, path, startedAt, endedAt } = (req.data ?? {}) as {
    trailId?: unknown;
    path?: unknown;
    startedAt?: unknown;
    endedAt?: unknown;
  };
  if (typeof trailId !== "string" || !/^[A-Za-z0-9]{1,40}$/.test(trailId)) {
    throw new HttpsError("invalid-argument", "잘못된 산책로입니다.");
  }
  if (!Array.isArray(path) || path.length > 5000 || !path.every(isValidLatLng)) {
    throw new HttpsError("invalid-argument", "잘못된 경로 데이터입니다.");
  }
  if (typeof startedAt !== "number" || typeof endedAt !== "number" || endedAt <= startedAt) {
    throw new HttpsError("invalid-argument", "잘못된 시간 정보입니다.");
  }
  const nowMs = Date.now();
  if (endedAt > nowMs + 60_000 || nowMs - startedAt > 12 * 3600_000) {
    throw new HttpsError("invalid-argument", "산책 시간이 유효하지 않습니다.");
  }

  const trailSnap = await db.collection("trails").doc(trailId).get();
  if (!trailSnap.exists) throw new HttpsError("not-found", "산책로를 찾을 수 없습니다.");
  const trailPath = (trailSnap.get("path") as { latitude: number; longitude: number }[]).map(
    (g): LatLng => ({ lat: g.latitude, lng: g.longitude }),
  );
  const trailDistanceM = trailSnap.get("distanceM") as number;

  const check = checkWalk({
    trailPath,
    trailDistanceM,
    walkedPath: path as LatLng[],
    durationSec: (endedAt - startedAt) / 1000,
  });

  const dayKey = kstDateKey(new Date());
  const userRef = db.collection("users").doc(uid);
  const dailyRef = userRef.collection("dailyStats").doc(dayKey);
  const walkRef = userRef.collection("walks").doc();

  return db.runTransaction(async (tx) => {
    const [user, daily] = await Promise.all([tx.get(userRef), tx.get(dailyRef)]);
    if (!user.exists) throw new HttpsError("failed-precondition", "프로필이 없습니다.");
    const rewardedCount = (daily.get("rewardedWalks") as number | undefined) ?? 0;
    const rewardedTrails = (daily.get("trails") as string[] | undefined) ?? [];

    let points = 0;
    let message: string;
    if (!check.ok) {
      message = check.reason ?? "산책이 인정되지 않았습니다.";
    } else if (rewardedCount >= POINTS.DAILY_WALK_REWARD_LIMIT) {
      message = "오늘의 산책 보상 한도에 도달했습니다. 산책 기록은 저장되었어요!";
    } else if (rewardedTrails.includes(trailId)) {
      message = "이 산책로는 오늘 이미 보상을 받았어요. 산책 기록은 저장되었어요!";
    } else {
      points = walkPoints(check.walkedDistanceM);
      message = `산책 완료! ${points}P가 적립되었습니다.`;
    }

    const now = FieldValue.serverTimestamp();
    tx.set(walkRef, {
      trailId,
      trailTitle: trailSnap.get("title"),
      distanceM: Math.round(check.walkedDistanceM),
      durationSec: Math.round((endedAt - startedAt) / 1000),
      verified: check.ok,
      coverage: Math.round(check.coverage * 100) / 100,
      points,
      startedAt: Timestamp.fromMillis(startedAt),
      endedAt: Timestamp.fromMillis(endedAt),
      createdAt: now,
    });
    if (check.ok) {
      tx.update(userRef, {
        walkCount: FieldValue.increment(1),
        totalWalkM: FieldValue.increment(Math.round(check.walkedDistanceM)),
        ...(points > 0 ? { points: FieldValue.increment(points) } : {}),
      });
      tx.update(trailSnap.ref, { walkCount: FieldValue.increment(1) });
    }
    if (points > 0) {
      tx.set(
        dailyRef,
        { rewardedWalks: rewardedCount + 1, trails: [...rewardedTrails, trailId] },
        { merge: true },
      );
      tx.set(pointLog(uid), {
        amount: points,
        reason: `산책 완료 - ${trailSnap.get("title")}`,
        createdAt: now,
      });
    }
    return { verified: check.ok, points, message, distanceM: Math.round(check.walkedDistanceM) };
  });
});

/** 리워드(제휴 매장 쿠폰) 교환 — 재고·포인트를 트랜잭션으로 차감 */
export const redeemReward = onCall(callOpts, async (req) => {
  const uid = requireAuth(req);
  const rewardId = (req.data ?? {}).rewardId;
  if (typeof rewardId !== "string" || !/^[A-Za-z0-9_-]{1,40}$/.test(rewardId)) {
    throw new HttpsError("invalid-argument", "잘못된 리워드입니다.");
  }
  const userRef = db.collection("users").doc(uid);
  const rewardRef = db.collection("rewards").doc(rewardId);
  const couponRef = userRef.collection("coupons").doc();

  return db.runTransaction(async (tx) => {
    const [user, reward] = await Promise.all([tx.get(userRef), tx.get(rewardRef)]);
    if (!user.exists) throw new HttpsError("failed-precondition", "프로필이 없습니다.");
    if (!reward.exists || reward.get("active") !== true) {
      throw new HttpsError("not-found", "교환할 수 없는 리워드입니다.");
    }
    const cost = reward.get("cost") as number;
    const stock = reward.get("stock") as number;
    const points = user.get("points") as number;
    if (stock <= 0) throw new HttpsError("resource-exhausted", "재고가 모두 소진되었습니다.");
    if (points < cost) throw new HttpsError("failed-precondition", "포인트가 부족합니다.");

    const code = `MW-${generateCode(4, secureRandom)}-${generateCode(4, secureRandom)}`;
    const now = FieldValue.serverTimestamp();
    tx.update(userRef, { points: FieldValue.increment(-cost) });
    tx.update(rewardRef, { stock: FieldValue.increment(-1) });
    tx.set(couponRef, {
      rewardId,
      title: reward.get("title"),
      partnerName: reward.get("partnerName"),
      code,
      used: false,
      createdAt: now,
      expiresAt: Timestamp.fromMillis(Date.now() + 30 * 24 * 3600_000),
    });
    tx.set(pointLog(uid), {
      amount: -cost,
      reason: `리워드 교환 - ${reward.get("title")}`,
      createdAt: now,
    });
    return { code };
  });
});

// ───────────────────────────── 커뮤니티 ─────────────────────────────

/** 게시글 조회수: 사용자당 1회만 증가 (조회수 조작 방지) */
export const viewPost = onCall(callOpts, async (req) => {
  const uid = requireAuth(req);
  const postId = (req.data ?? {}).postId;
  if (typeof postId !== "string" || !/^[A-Za-z0-9]{1,40}$/.test(postId)) {
    throw new HttpsError("invalid-argument", "잘못된 게시글입니다.");
  }
  const postRef = db.collection("posts").doc(postId);
  const viewerRef = postRef.collection("viewers").doc(uid);
  await db.runTransaction(async (tx) => {
    const [post, viewer] = await Promise.all([tx.get(postRef), tx.get(viewerRef)]);
    if (!post.exists || viewer.exists) return;
    tx.set(viewerRef, { at: FieldValue.serverTimestamp() });
    tx.update(postRef, { viewCount: FieldValue.increment(1) });
  });
  return { ok: true };
});

// ───────────────────────────── 관리자 ─────────────────────────────

/** 관리자 권한 부여/회수 (기존 관리자만 호출 가능, 최초 관리자는 scripts/grantAdmin) */
export const setAdmin = onCall(callOpts, async (req) => {
  requireAdmin(req);
  const { uid, admin } = (req.data ?? {}) as { uid?: unknown; admin?: unknown };
  if (typeof uid !== "string" || typeof admin !== "boolean") {
    throw new HttpsError("invalid-argument", "잘못된 요청입니다.");
  }
  await getAuth().setCustomUserClaims(uid, admin ? { admin: true } : {});
  return { ok: true };
});

// ───────────────────────────── 집계 트리거 ─────────────────────────────

/** 리뷰 작성/수정/삭제 → 산책로 평균 평점·리뷰 수 재계산 */
export const onReviewWritten = onDocumentWritten(
  "trails/{trailId}/reviews/{uid}",
  async (event) => {
    const trailRef = db.collection("trails").doc(event.params.trailId);
    const agg = await trailRef
      .collection("reviews")
      .aggregate({ avg: AggregateField.average("rating"), count: AggregateField.count() })
      .get();
    const { avg, count } = agg.data();
    await trailRef
      .update({ ratingAvg: Math.round((avg ?? 0) * 10) / 10, ratingCount: count })
      .catch(() => undefined); // 산책로가 이미 삭제된 경우
  },
);

/** 관심목록 추가/삭제 → favoriteCount */
export const onFavoriteWritten = onDocumentWritten(
  "users/{uid}/favorites/{trailId}",
  async (event) => {
    const before = event.data?.before.exists;
    const after = event.data?.after.exists;
    if (before === after) return;
    await db
      .collection("trails")
      .doc(event.params.trailId)
      .update({ favoriteCount: FieldValue.increment(after ? 1 : -1) })
      .catch(() => undefined);
  },
);

/** 댓글 수 집계 */
export const onCommentWritten = onDocumentWritten(
  "posts/{postId}/comments/{commentId}",
  async (event) => {
    const before = event.data?.before.exists;
    const after = event.data?.after.exists;
    if (before === after) return;
    await db
      .collection("posts")
      .doc(event.params.postId)
      .update({ commentCount: FieldValue.increment(after ? 1 : -1) })
      .catch(() => undefined);
  },
);

/** 산책로 등록/삭제 → 사용자 trailCount, 등록 보상 */
export const onTrailWritten = onDocumentWritten("trails/{trailId}", async (event) => {
  const before = event.data?.before;
  const after = event.data?.after;
  if (!before?.exists && after?.exists) {
    const ownerId = after.get("ownerId") as string;
    const userRef = db.collection("users").doc(ownerId);
    // 트리거는 최소 1회 이상 실행될 수 있으므로 event.id 로 중복 지급 방지
    const eventRef = db.collection("processedEvents").doc(event.id);
    await db.runTransaction(async (tx) => {
      const day = kstDateKey(new Date());
      const dailyRef = userRef.collection("dailyStats").doc(day);
      const [user, daily, processed] = await Promise.all([
        tx.get(userRef),
        tx.get(dailyRef),
        tx.get(eventRef),
      ]);
      if (!user.exists || processed.exists) return;
      tx.set(eventRef, { at: FieldValue.serverTimestamp() });
      const rewardedTrails = (daily.get("createdTrailRewards") as number | undefined) ?? 0;
      // 산책로 등록 보상은 하루 3회까지 (스팸 방지)
      if (rewardedTrails < 3) {
        tx.update(userRef, {
          trailCount: FieldValue.increment(1),
          points: FieldValue.increment(POINTS.TRAIL_CREATED),
        });
        tx.set(dailyRef, { createdTrailRewards: rewardedTrails + 1 }, { merge: true });
        tx.set(pointLog(ownerId), {
          amount: POINTS.TRAIL_CREATED,
          reason: `산책로 등록 - ${after.get("title")}`,
          createdAt: FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(userRef, { trailCount: FieldValue.increment(1) });
      }
    });
  } else if (before?.exists && !after?.exists) {
    const ownerId = before.get("ownerId") as string;
    await db
      .collection("users")
      .doc(ownerId)
      .update({ trailCount: FieldValue.increment(-1) })
      .catch(() => undefined);
  }
});

/** 산책로 삭제 시 하위 리뷰와 사진 정리 */
export const onTrailDeleted = onDocumentDeleted("trails/{trailId}", async (event) => {
  const trailRef = db.collection("trails").doc(event.params.trailId);
  await db.recursiveDelete(trailRef.collection("reviews"));
  const photoPath = event.data?.get("photoPath") as string | undefined;
  if (photoPath) {
    await getStorage()
      .bucket()
      .file(photoPath)
      .delete()
      .catch(() => undefined);
  }
});

/** 게시글 삭제 시 댓글·조회 기록 정리 */
export const onPostDeleted = onDocumentDeleted("posts/{postId}", async (event) => {
  const postRef = db.collection("posts").doc(event.params.postId);
  await db.recursiveDelete(postRef.collection("comments"));
  await db.recursiveDelete(postRef.collection("viewers"));
});
