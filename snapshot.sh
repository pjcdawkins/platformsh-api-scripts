#!/usr/bin/env bash
# Request a snapshot of an environment (without waiting for the result).

# Boilerplate: set up error handling and include common.sh.
set -e -o pipefail
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$dir"/inc/common.sh

requestWithAuth -X POST -f \
  "$environment_url/backup" \
  -o /dev/null

echo "Snapshot requested: $environment_url"
