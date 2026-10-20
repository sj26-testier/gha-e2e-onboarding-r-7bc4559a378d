#!/usr/bin/env bash
set -euo pipefail
printf '%s  .lab/bin/buildkite-gha-linux-amd64\n' 'bbd256ed588ade967ebf28ad63366de87d884ebdf39529f846621221033b79cd' | sha256sum -c -
printf '%s  .lab/bin/buildkite-gha-windows-amd64.exe\n' '4c582c428176f4a42e179c7086338c0efc095dc30ba5a554bd21dd361b1cce9d' | sha256sum -c -
printf '%s  .lab/bin/cache-final.test.exe\n' '3f2d8402dbba2a21c073cf00fca824a85148bed5df70731b2753ca9f0a4c608b' | sha256sum -c -
cat .lab/proof.json
"$PWD/.lab/bin/buildkite-gha-linux-amd64" --version
exec "$PWD/.lab/bin/buildkite-gha-linux-amd64" upload \
  --runtime-distribution "windows/amd64=$PWD/.lab/bin/buildkite-gha-windows-amd64.exe" \
  --runner-queue windows-2022=windows-medium \
  .github/workflows/windows-cache.yml
