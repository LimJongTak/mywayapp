// 테스트 전용: firebase-tools 가 NO_PROXY 를 무시하고 localhost 에뮬레이터 호출까지
// HTTPS 프록시로 보내는 문제를 막는다. 루프백 주소만 직접 연결하고 그 외는 프록시 유지.
const path = require("node:path");
try {
  const toolsDir = path.dirname(require.resolve("firebase-tools/package.json"));
  const undici = require(require.resolve("undici", { paths: [toolsDir] }));
  const Orig = undici.ProxyAgent;
  const direct = new undici.Agent();
  const LOOPBACK = new Set(["127.0.0.1", "localhost", "[::1]", "::1"]);
  class LoopbackAwareProxyAgent extends Orig {
    dispatch(opts, handler) {
      const host = new URL(opts.origin).hostname;
      if (LOOPBACK.has(host)) return direct.dispatch(opts, handler);
      return super.dispatch(opts, handler);
    }
  }
  undici.ProxyAgent = LoopbackAwareProxyAgent;
} catch {
  // firebase-tools 가 없으면 아무것도 하지 않음
}
