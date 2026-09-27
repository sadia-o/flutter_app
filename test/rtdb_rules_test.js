const http = require('http');

const DB_PORT = 9000;
const AUTH_PORT = 9099;
const HOST = '127.0.0.1';
const PROJECT_ID = 'bait-guard-6f470';
const DB_NS = 'bait-guard-6f470-default-rtdb';
const ESP_UID = 'zj0CNiqRBwdTwXzKrD5yP5Puds83';
const VIEWER_UID = 'viewer_uid_123';
const STRANGER_UID = 'stranger_uid_999';

function httpRequest(options, body) {
  return new Promise((resolve, reject) => {
    const postData = body ? JSON.stringify(body) : null;
    const req = http.request({
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(postData ? { 'Content-Length': Buffer.byteLength(postData) } : {}),
        ...options.headers,
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        let json;
        try { json = JSON.parse(data); } catch (_) { json = data; }
        resolve({ status: res.statusCode, body: json });
      });
    });
    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}

async function createAndGetToken(uid, email) {
  // 1. Create account with exact UID using emulator admin endpoint
  await httpRequest({
    host: HOST,
    port: AUTH_PORT,
    path: `/identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts`,
    method: 'POST',
    headers: { 'Authorization': 'Bearer owner' }
  }, {
    localId: uid,
    email: email,
    password: 'password123'
  });

  // 2. Sign in to obtain signed ID token with exact UID
  const res = await httpRequest({
    host: HOST,
    port: AUTH_PORT,
    path: '/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-key',
    method: 'POST',
  }, {
    email: email,
    password: 'password123',
    returnSecureToken: true
  });

  if (!res.body.idToken) {
    throw new Error(`Failed to get ID token for ${uid}: ${JSON.stringify(res.body)}`);
  }
  return res.body.idToken;
}

function dbRequest(path, options = {}) {
  const method = options.method || 'GET';
  const query = options.token ? `?auth=${options.token}&ns=${DB_NS}` : `?ns=${DB_NS}`;
  return httpRequest({
    host: HOST,
    port: DB_PORT,
    path: `${path}.json${query}`,
    method: method,
    headers: options.token ? { 'Authorization': `Bearer ${options.token}` } : {}
  }, options.body);
}

async function run() {
  console.log('--- Starting Local Firebase RTDB Rules Verification with Auth Emulator ---');
  let failures = 0;
  let passed = 0;

  async function assert(desc, fn) {
    try {
      await fn();
      console.log(`[PASS] ${desc}`);
      passed++;
    } catch (e) {
      console.error(`[FAIL] ${desc}: ${e.message}`);
      failures++;
    }
  }

  // 1. Create and mint tokens with verified UIDs
  const espToken = await createAndGetToken(ESP_UID, 'esp32@hardware.baitguard.local');
  const viewerToken = await createAndGetToken(VIEWER_UID, 'viewer@baitguard.local');
  const strangerToken = await createAndGetToken(STRANGER_UID, 'stranger@other.local');

  // 2. Seed mobileReaders grant for VIEWER_UID using admin bypass
  const seedRes = await httpRequest({
    host: HOST,
    port: DB_PORT,
    path: `/mobileReaders/${VIEWER_UID}.json?ns=${DB_NS}&access_token=owner`,
    method: 'PUT'
  }, { active: true, facilityIds: { site_1: true } });
  if (seedRes.status !== 200) {
    throw new Error(`Failed to seed mobileReaders: ${JSON.stringify(seedRes.body)}`);
  }

  // Test 1: Unauthenticated write to stationLive/station_01 -> DENIED (401)
  await assert('Unauthenticated write to stationLive/station_01 is DENIED', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'PUT',
      body: { device_id: 'station_01', facility_id: 'site_1', battery_percentage: 90, bait_percentage: 80, online: true, last_seen_at: Date.now() }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 2: Stranger write to stationLive/station_01 -> DENIED (401)
  await assert('Stranger user write to stationLive/station_01 is DENIED', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'PUT',
      token: strangerToken,
      body: { device_id: 'station_01', facility_id: 'site_1', battery_percentage: 90, bait_percentage: 80, online: true, last_seen_at: Date.now() }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 3: ESP valid write to stationLive/station_01 -> ALLOWED (200)
  await assert('ESP valid write to stationLive/station_01 is ALLOWED', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_01', facility_id: 'site_1', battery_percentage: 90, bait_percentage: 80, online: true, last_seen_at: Date.now() }
    });
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}: ${JSON.stringify(res.body)}`);
  });

  // Test 4: ESP deleting stationLive/station_01 (newData.exists() violation) -> DENIED (401)
  await assert('ESP deleting stationLive/station_01 is DENIED by newData.exists()', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'DELETE',
      token: espToken
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 5: ESP writing mismatched device_id to stationLive/station_01 -> DENIED (401)
  await assert('ESP writing mismatched device_id to stationLive/station_01 is DENIED', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_99', facility_id: 'site_1', battery_percentage: 90, bait_percentage: 80, online: true, last_seen_at: Date.now() }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 6: ESP appending valid rat event -> ALLOWED (200)
  await assert('ESP appending valid rat_detected event is ALLOWED', async () => {
    const res = await dbRequest('/stationEvents/station_01/evt_rat_1', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_01', facility_id: 'site_1', event_type: 'rat_detected', timestamp: Date.now() }
    });
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}: ${JSON.stringify(res.body)}`);
  });

  // Test 7: ESP overwriting existing event (!data.exists() violation) -> DENIED (401)
  await assert('ESP overwriting existing event is DENIED by !data.exists()', async () => {
    const res = await dbRequest('/stationEvents/station_01/evt_rat_1', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_01', facility_id: 'site_1', event_type: 'rat_detected', timestamp: Date.now() + 1000 }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 8: Rat event containing bait_percentage (individual rejection) -> DENIED (401)
  await assert('Rat event containing bait_percentage is individually REJECTED', async () => {
    const res = await dbRequest('/stationEvents/station_01/evt_rat_invalid', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_01', facility_id: 'site_1', event_type: 'rat_detected', timestamp: Date.now(), bait_percentage: 50 }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 9: ESP appending valid low-bait event with required fields -> ALLOWED (200)
  await assert('ESP appending valid low_bait_alert with all required fields is ALLOWED', async () => {
    const res = await dbRequest('/stationEvents/station_01/evt_low_1', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_01', facility_id: 'site_1', event_type: 'low_bait_alert', bait_percentage: 15, current_pixels: 420, status: 'Low', timestamp: Date.now() }
    });
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}: ${JSON.stringify(res.body)}`);
  });

  // Test 10: Low-bait event missing current_pixels -> DENIED (401)
  await assert('Low-bait event missing current_pixels is DENIED', async () => {
    const res = await dbRequest('/stationEvents/station_01/evt_low_bad', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_01', facility_id: 'site_1', event_type: 'low_bait_alert', bait_percentage: 15, status: 'Low', timestamp: Date.now() }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 11: Low-bait event with unknown extra field -> DENIED (401) by $other: false
  await assert('Event with unknown field is DENIED by $other: false', async () => {
    const res = await dbRequest('/stationEvents/station_01/evt_low_unknown', {
      method: 'PUT',
      token: espToken,
      body: { device_id: 'station_01', facility_id: 'site_1', event_type: 'low_bait_alert', bait_percentage: 15, current_pixels: 420, status: 'Low', timestamp: Date.now(), hackerField: 'injected' }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 12: Authorized reader read -> ALLOWED (200)
  await assert('Authorized reader with active grant and site_1 can READ stationLive', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'GET',
      token: viewerToken
    });
    if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}: ${JSON.stringify(res.body)}`);
  });

  // Test 13: Unauthorized reader read -> DENIED (401)
  await assert('Unauthorized user without grant is DENIED read on stationLive', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'GET',
      token: strangerToken
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 14: Human writing to stationLive -> DENIED (401)
  await assert('Authorized reader cannot WRITE to stationLive', async () => {
    const res = await dbRequest('/stationLive/station_01', {
      method: 'PUT',
      token: viewerToken,
      body: { device_id: 'station_01', facility_id: 'site_1', battery_percentage: 90, bait_percentage: 80, online: true, last_seen_at: Date.now() }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  // Test 15: Human writing their own mobileReaders grant -> DENIED (401)
  await assert('Human user cannot write or escalate mobileReaders grants', async () => {
    const res = await dbRequest(`/mobileReaders/${strangerToken.slice(0, 10)}`, {
      method: 'PUT',
      token: strangerToken,
      body: { active: true, facilityIds: { site_1: true } }
    });
    if (res.status !== 401) throw new Error(`Expected 401, got ${res.status}`);
  });

  console.log(`\n--- Summary: ${passed} passed, ${failures} failed ---`);
  if (failures > 0) process.exit(1);
}

run().catch(e => {
  console.error('Fatal error:', e);
  process.exit(1);
});
