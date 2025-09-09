# Mythos Sentinel Patching & API Documentation

## Patching Process
- Patches delivered as zip: `msentinel-patch--NNNN--<slug>.zip`
- Install: unzip + run `install.sh`
- Rollback: run `rollback.sh`
- Every patch:
  - Backs up changed files as `__vNNNN`
  - Updates VERSION file
  - Commits + tags (`vX.Y.Z+patchNNNN`)
  - Runs `chown -R mythos:mythos /opt/mythos-sentinel`
  - Logs to patch-registry.log

## API Endpoints
- `/` : Public hello
- `/mirror` : Echo request with redaction
- `/version` : Show current app version
- `/tfiles` : Planned GitHub proxy
- `/admin/debug` : Planned admin-only

## Rules
- This doc MUST be updated whenever patching process changes.
- VERSION file is single source of truth.
