import { test } from "node:test";
import assert from "node:assert/strict";
import {
  LatLng,
  checkWalk,
  generateCode,
  haversine,
  isValidLatLng,
  isValidNickname,
  kstDateKey,
  pathDistance,
  walkPoints,
} from "../rules";

// 경복궁 남→북 약 1km 직선 경로 (20개 꼭짓점)
const trail: LatLng[] = Array.from({ length: 20 }, (_, i) => ({
  lat: 37.576 + i * 0.00047,
  lng: 126.977,
}));
const trailDist = pathDistance(trail);

test("haversine ~ 111m per 0.001 deg lat", () => {
  const d = haversine({ lat: 37, lng: 127 }, { lat: 37.001, lng: 127 });
  assert.ok(d > 110 && d < 112, `got ${d}`);
});

test("valid walk is accepted", () => {
  const r = checkWalk({ trailPath: trail, trailDistanceM: trailDist, walkedPath: trail, durationSec: 15 * 60 });
  assert.equal(r.ok, true);
  assert.ok(r.coverage > 0.99);
});

test("too fast (vehicle) is rejected", () => {
  const r = checkWalk({ trailPath: trail, trailDistanceM: trailDist, walkedPath: trail, durationSec: 120 });
  assert.equal(r.ok, false);
  assert.match(r.reason!, /속도/);
});

test("walking elsewhere is rejected", () => {
  const elsewhere = trail.map((p) => ({ lat: p.lat + 0.01, lng: p.lng }));
  const r = checkWalk({ trailPath: trail, trailDistanceM: trailDist, walkedPath: elsewhere, durationSec: 15 * 60 });
  assert.equal(r.ok, false);
});

test("half walk is rejected", () => {
  const r = checkWalk({ trailPath: trail, trailDistanceM: trailDist, walkedPath: trail.slice(0, 10), durationSec: 600 });
  assert.equal(r.ok, false);
});

test("points are capped", () => {
  assert.equal(walkPoints(0), 10);
  assert.equal(walkPoints(2500), 35);
  assert.equal(walkPoints(50000), 100);
});

test("validators", () => {
  assert.ok(isValidNickname("산책왕_01"));
  assert.ok(!isValidNickname("a"));
  assert.ok(!isValidNickname("<script>"));
  assert.ok(isValidLatLng({ lat: 1, lng: 2 }));
  assert.ok(!isValidLatLng({ lat: 91, lng: 2 }));
  assert.ok(!isValidLatLng({ lat: NaN, lng: 2 }));
  assert.match(generateCode(7), /^[A-Z2-9]{7}$/);
  assert.equal(kstDateKey(new Date("2026-01-01T16:00:00Z")), "2026-01-02");
});
