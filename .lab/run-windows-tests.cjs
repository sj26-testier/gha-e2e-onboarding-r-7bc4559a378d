const fs = require('node:fs')
const path = require('node:path')
const crypto = require('node:crypto')
const {execFileSync} = require('node:child_process')
if (!process.version.startsWith('v24.') || !path.isAbsolute(process.execPath)) throw new Error('Managed absolute Node24 required')
const executable = path.resolve('.lab/bin/cache-final.test.exe')
const digest = crypto.createHash('sha256').update(fs.readFileSync(executable)).digest('hex')
if (digest !== '3f2d8402dbba2a21c073cf00fca824a85148bed5df70731b2753ca9f0a4c608b') throw new Error('Test digest mismatch')
const argv = [
  '-test.run=^(TestCacheServiceLifecycleUsesFreshIsolatedCredentials|TestWindowsCache.*|TestIsolateCacheActionEnvironment.*)$',
  '-test.v',
  '-test.timeout=6m'
]
console.log('LAB_TEST_ARGV: ' + JSON.stringify(argv))
let output
try {
  output = execFileSync(executable, argv, {encoding: 'utf8', maxBuffer: 16 * 1024 * 1024, timeout: 7 * 60 * 1000})
} catch (error) {
  if (error.stdout) process.stdout.write(error.stdout)
  if (error.stderr) process.stderr.write(error.stderr)
  throw error
}
process.stdout.write(output)
if (/--- (SKIP|FAIL):/.test(output)) throw new Error('Selected tests skipped or failed')
const roots = [
  'TestWindowsCacheArchiveTools',
  'TestWindowsCacheZstdStaging',
  'TestCacheServiceLifecycleUsesFreshIsolatedCredentials',
  'TestIsolateCacheActionEnvironmentLeavesGitHubServerURLForSharedOverride',
  'TestIsolateCacheActionEnvironmentLeavesRealGitHubServerURLUnchanged'
]
const expected = [...roots]
for (const version of ['v4.3.0', 'v6.1.0']) {
  const suite = 'TestCacheServiceLifecycleUsesFreshIsolatedCredentials/' + version
  expected.push(suite)
  for (const mode of ['', 'read', 'write', 'write-only', 'none']) expected.push(suite + '/mode=' + mode)
}
const lines = output.split(/\r?\n/).map(line => line.trim())
for (const name of expected) {
  if (!lines.some(line => line.startsWith('=== RUN') && line.slice(7).trim() === name)) throw new Error('Missing RUN: ' + name)
  if (!lines.some(line => line.startsWith('--- PASS: ' + name + ' ('))) throw new Error('Missing PASS: ' + name)
}
if (!lines.includes('PASS')) throw new Error('Missing overall test PASS')
console.log('LAB_WINDOWS_TESTS_PASSED: roots=5 lifecycle_versions=2 lifecycle_modes=10 skipped=0')
