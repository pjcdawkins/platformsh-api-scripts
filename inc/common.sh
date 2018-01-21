#!/usr/bin/env bash

set -e -o pipefail

# Common variables.
accounts_base_url=${PLATFORMSH_API_ACCOUNTS_BASE:-https://accounts.platform.sh}
project_id=$PLATFORM_PROJECT
project_region=api.platform.sh
environment_id=${PLATFORM_BRANCH:-master}
environment_url=https://"$project_region"/api/projects/"$project_id"/environments/"${environment_id}"

if [ -z "$PLATFORM_PROJECT" ]; then
  echo '$PLATFORM_PROJECT must be set' >&2
  exit 1
fi

# Make a cURL request.
request() {
  curl -sgS -H'User-Agent: platformsh-api-scripts' "$@"
}

# Get a named field from a JSON string.
# Usage: getJsonField json field
getJsonField() {
  echo "$1" | grep -Eio '"'"$2"'": *"[^"]*' | sed -E 's/"'"$2"'": ?"//'
}

# Load from a cache.
# Usage: loadCache cacheKey ttl
loadCache() {
  # Get the modified timestamp of a file.
  getModifiedTime() {
    uname | grep -q Darwin && stat -f %m "$1" || stat -c %Y "$1"
  }
  cache=${PLATFORMSH_API_CACHE:-/tmp/platformsh-api-$USER}
  oldestAllowedTime=$(expr $(date +%s) - "$2")
  if [ -f "$cache/$1" ] && [ "$(getModifiedTime "$cache/$1")" -gt "$oldestAllowedTime" ]; then
    cat "$cache/$1"
  fi
}

# Save to a cache.
# Usage: saveCache cacheKey data
saveCache() {
  cache=${PLATFORMSH_API_CACHE:-/tmp/platformsh-api-$USER}
  mkdir -p "$cache" && chmod 0700 "$cache"
  touch "$cache/$1" && chmod 0600 "$cache/$1"
  echo "$2" > "$cache/$1"
}

# Make a cURL request with OAuth2 authentication.
requestWithAuth() {
  # Get a Platform.sh access token for use with HTTP requests.
  getAccessToken() {
    # Exchange an API token for an access token (JSON response).
    getTokenResponse() {
      client_id=${PLATFORMSH_API_CLIENT_ID:-platform-cli}
      api_token=${PLATFORMSH_API_TOKEN:-$PLATFORMSH_CLI_TOKEN}
      if [ -z "$api_token" ]; then
        echo 'One of $PLATFORMSH_API_TOKEN or $PLATFORMSH_CLI_TOKEN must be set' >&2
        exit 1
      fi
      response=$(request \
           -H 'Accept: application/json' \
           -H 'Content-Type: application/x-www-form-urlencoded' \
           "$accounts_base_url"/oauth2/token \
           -d "client_id=${client_id}&client_secret=&grant_type=api_token&api_token=${api_token}")
      if [ -z "$response" ]; then
        echo 'Error: empty response from token request' >&2
        exit 1
      fi
      echo $response
    }

    # Get the access token response (cached if possible, or direct).
    if ! response=$(loadCache tokens 3600) || [ -z "$response" ]; then
      response=$(getTokenResponse)
      saveCache tokens "$response"
    fi

    # Extract the access token from the response.
    getJsonField "$response" access_token
  }

  if ! accessToken=$(getAccessToken) || [ -z "$accessToken" ]; then
    exit 1
  fi

  request -H"Authorization: Bearer $accessToken" "$@"
}
