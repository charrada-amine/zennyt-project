import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';

// Credentials are supplied by the operator, never stored in this script.
const password = process.env.ADMIN_PASSWORD;
if (!password) throw new Error('Set ADMIN_PASSWORD for the existing local administrator');
const origin = process.env.ADMIN_ORIGIN ?? 'http://localhost:3001';
const email = process.env.ADMIN_EMAIL ?? 'admin@zennyt.local';
const post = (path, body, token) => fetch(`${origin}/api/v1${path}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
  body: JSON.stringify(body),
});
let response = await post('/auth/login', { email, password });
assert.equal(response.status, 200, 'login through web proxy');
let tokens = await response.json();
const get = (path) => fetch(`${origin}/api/v1${path}`, { headers: { Authorization: `Bearer ${tokens.accessToken}` } });
try {
  response = await get('/games/admin/configuration-schemas');
  assert.equal(response.status, 200);
  const schemas = await response.json();
  assert.equal(schemas.length, 16);
  const memory = schemas.find(s => s.gameType === 'MEMORY_QUEST' && s.kind === 'SETTINGS');
  assert.equal(memory.fields.find(f => f.key === 'memoryDigitVisibleMs').defaultValue, 900);
  const emotional = schemas.find(s => s.gameType === 'EMOTIONAL_REGULATION' && s.kind === 'SETTINGS');
  response = await post('/games/admin/configurations', {
    gameType: emotional.gameType, kind: emotional.kind,
    values: { ...Object.fromEntries(emotional.fields.map(f => [f.key, f.defaultValue])), reflectiveThinkingTimeMs: 2999 },
  }, tokens.accessToken);
  assert.equal(response.status, 400, 'unsafe reflection minimum must be rejected without writing');
  response = await get('/games/admin/assets');
  const assets = await response.json();
  for (const asset of assets.filter(a => a.url.startsWith('/api/v1/'))) {
    const preview = await fetch(`${origin}${asset.url}`, { headers: { Authorization: `Bearer ${tokens.accessToken}` } });
    assert.equal(preview.status, 200, 'migrated asset preview');
    assert.ok((await preview.arrayBuffer()).byteLength > 0);
  }
  if (process.argv.includes('--restart-backend')) {
    execFileSync('docker', ['compose', 'restart', 'backend'], { stdio: 'ignore' });
    let ready = false;
    for (let attempt = 0; attempt < 60; attempt++) {
      ready = await fetch('http://localhost:8080/actuator/health').then(r => r.ok).catch(() => false);
      if (ready) break;
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    assert.ok(ready, 'backend healthy after restart');
  }
  response = await post('/auth/refresh', { refreshToken: tokens.refreshToken });
  assert.equal(response.status, 200, 'refresh survives restart');
  tokens = await response.json();
  response = await get('/games/admin/overview');
  assert.equal(response.status, 200, 'renewed access works');
  response = await post('/auth/login', { email, password });
  assert.equal(response.status, 200, 'fresh subsequent login');
  const fresh = await response.json();
  await post('/auth/logout', { refreshToken: fresh.refreshToken });
  console.log('PASS: login, 16 schemas, timing validation, asset preview, refresh, subsequent login');
} finally {
  await post('/auth/logout', { refreshToken: tokens.refreshToken });
}
