# Synthetic released Windows compatibility probe

Dedicated sj26-testier lab, not a customer workload. Pins the unmodified GitHub Actions plugin and released buildkite-gha 0.105.3. Exercises the original host JAVA_HOME/bin/java.exe consumer, optionally compiles a small class with installed javac, and saves/deletes/exact-restores two independent zstd cache payloads. No credentials, environment bridge, packages, publishing or image changes. Agent/image observations stay in private lab evidence.

The run-owned push uses GitHub-documented `[skip actions]` to suppress a fresh native control; the existing native control is retained as comparison. Windows-only same-job persistence is not cross-OS or cross-worker proof.
