#!/usr/bin/env bash

set -e -o pipefail

# Common variables.
accounts_base_url=${PLATFORMSH_API_ACCOUNTS_BASE:-https://accounts.platform.sh}
project_id=$PLATFORM_PROJECT
project_region=api.platform.sh
environment_id=${PLATFORM_BRANCH:-master}
environment_url=https://"$project_region"/api/projects/"$project_id"/environments/"${environment_id}"

# Make a cURL request.
request() {
  curl -sgS -H'User-Agent: platformsh-api-scripts' "$@"
}

# Get a named field from a JSON string.
# Usage: getJsonField json field
getJsonField() {
  echo "$1" | grep -Eio '"'"$2"'": *"[^"]*' | sed -E 's/"'"$2"'": ?"//'
}

getProjectId() {
  echo $PLATFORM_PROJECT
}

getEnvironmentId() {
  echo ${PLATFORM_BRANCH:-master}
}

# Make a cURL request with OAuth2 authentication.
requestWithAuth() {
  # Get a Platform.sh access token for use with HTTP requests.
  getAccessToken() {
    client_id=${PLATFORMSH_API_CLIENT_ID:-platform-cli}
    api_token=${PLATFORMSH_API_TOKEN:-"$PLATFORMSH_CLI_TOKEN"}
    cache=${PLATFORMSH_API_CACHE:-/tmp/platformsh-api-"$USER"}
    token_file="$cache/tokens"
    one_hour_ago=$(expr $(date '+%s') - 3600)

    if [ -z "$api_token" ]; then
      echo 'One of PLATFORMSH_API_TOKEN or PLATFORMSH_CLI_TOKEN must be set' >&2
      exit 1
    fi

    # Exchange an API token for an access token (JSON response).
    getTokenResponse() {
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

    # Get a cached token response (JSON from a file).
    getCachedTokenResponse() {
      if [ -f "$token_file" ] && [ "$(stat -f "%Sm" -t "%s" "$token_file")" -ge "$one_hour_ago" ]; then
        cat "$token_file"
      fi
    }

    # Save the token response to the cache file.
    saveTokenResponse() {
      mkdir -p "$cache" && chmod 0700 "$cache"
      touch "$token_file" && chmod 0600 "$token_file"
      echo "$1" > "$token_file"
    }

    # Get the access token response (cached if possible, or direct).
    response=$(getCachedTokenResponse)
    if [ -z "$response" ]; then
      mkdir -p "$cache" && chmod 0700 "$cache"
      touch "$token_file" && chmod 0600 "$token_file"
      response=$(getTokenResponse)
      saveTokenResponse "$response"
    fi

    # Extract the access token from the response.
    getJsonField "$response" access_token
  }

  if ! accessToken=$(getAccessToken) || [ -z "$accessToken" ]; then
    exit 1
  fi

  request -H"Authorization: Bearer $accessToken" "$@"
}
