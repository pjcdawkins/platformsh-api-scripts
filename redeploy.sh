#!/usr/bin/env bash
# Redeploy an environment.

# Boilerplate: set up error handling and include common.sh.
set -e -o pipefail
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$dir"/inc/common.sh

requestWithAuth -XPOST -f \
  "$environment_url/redeploy" \
  -o/dev/null

echo "Redeployed: $environment_url"
