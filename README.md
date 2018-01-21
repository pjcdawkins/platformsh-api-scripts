# Experimental: Platform.sh API scripts

No warranty and no license. Don't use this unless you know what you are doing.

As an alternative to installing the Platform.sh CLI on an environment, these
scripts help run API actions without any particular dependencies (just things
like `curl`, `sed`, and a few environment variables).

## Usage

1. Get an [API token](https://docs.platform.sh/gettingstarted/cli/api-tokens.html)
   under your Account Settings -> API Tokens. Preferably do this as a machine
   user who only has access to the project(s) where you want to use these
   scripts.
2. On your Platform.sh project or environment, set the variable
   `env:PLATFORMSH_API_TOKEN` to the value of that API token.
3. Run the script(s) in your Platform.sh environment, during runtime or crons.

## Scripts

* `redeploy.sh` will set an environment variable named `_redeploy` to the
  current time, thus triggering a redeploy.
* `snapshot.sh` will request a snapshot of the current environment.

## Configuration example

```yaml
# Download the scripts.
hooks:
  build: |
    git clone https://github.com/pjcdawkins/platformsh-api-scripts.git    

# Set up cron.
crons:
  # Automatically redeploy every month.
  redeploy:
    spec: '0 0 1 * *'
    cmd: |
      if [ "$PLATFORM_BRANCH" = master ]; then
        bash platformsh-api-scripts/redeploy.sh
      fi
  # Automatically snapshot every week.
  snapshot:
    spec: '0 0 * * 0'
    cmd: |
      if [ "$PLATFORM_BRANCH" = master ]; then
        bash platformsh-api-scripts/snapshot.sh
      fi
```
