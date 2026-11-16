#!/usr/bin/env bash
set -euo pipefail

container="${EPIC_REGTEST_MONGO_CONTAINER:-epicmail-regtest-mongo}"
exec docker exec -i "$container" mongosh "$@"
