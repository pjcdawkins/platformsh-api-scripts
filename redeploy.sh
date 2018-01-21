#!/usr/bin/env bash
# Redeploy an environment, by setting a variable named '_redeploy'.

# Boilerplate: set up error handling and include common.sh.
set -e -o pipefail
dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$dir"/inc/common.sh

variableName=_redeploy

# Check if the variable exists.
variableGetCode=$(requestWithAuth -I "$environment_url"/variables/"$variableName" -w '%{http_code}' -o /dev/null)

# Set the variable via POST or PATCH.
if [ "$variableGetCode" = 404 ]; then
  requestWithAuth -XPOST -f \
    "$environment_url"/variables \
    -d'{"name": "'"$variableName"'", "value": "'"$(date)"'"}' \
    -o/dev/null
else
  requestWithAuth -X PATCH -f \
    "$environment_url"/variables/"$variableName" \
    -d '{"value": "'"$(date)"'"}' \
    -o /dev/null
fi

echo "Redeployed: $environment_url"
