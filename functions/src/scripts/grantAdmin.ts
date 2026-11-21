/**
 * 최초 관리자 지정 스크립트
 *   GOOGLE_APPLICATION_CREDENTIALS=서비스계정키.json npm run grant-admin -- user@example.com
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

async function main() {
  const email = process.argv[2];
  if (!email) {
    console.error("사용법: npm run grant-admin -- <email>");
    process.exit(1);
  }
  initializeApp();
  const user = await getAuth().getUserByEmail(email);
  await getAuth().setCustomUserClaims(user.uid, { ...(user.customClaims ?? {}), admin: true });
  console.log(`✅ ${email} (${user.uid}) 에게 관리자 권한을 부여했습니다. 앱에서 다시 로그인하세요.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
