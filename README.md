# Experimental: Platform.sh API scripts

As an alternative to installing the Platform.sh CLI on an environment, these
scripts help run API actions without any particular dependencies (just things
like `curl`, `sed`, and a few environment variables).

## Scripts

* `redeploy.sh` will set an environment variable named `_redeploy` to the
  current time, thus triggering a redeploy.
* `snapshot.sh` will request a snapshot of the current environment.

## Usage

1. Create a machine user who only has access to the project(s) where you want to use these scripts.
2. [Log in](https://accounts.platform.sh/user/login) as the machine user, and create an [API token](https://docs.platform.sh/gettingstarted/cli/api-tokens.html)
   under Account Settings -> API Tokens.
3. On your Platform.sh project or environment, set the variable
   `env:PLATFORMSH_API_TOKEN` to the value of that API token.
4. Run the script(s) in your Platform.sh environment, during runtime or crons (see the example below).

### Example

Edit the "hooks" section in your `.platform.app.yaml` to install the scripts:

```yaml
hooks:
  build: |
    set -e
    wget -qO- https://github.com/pjcdawkins/platformsh-api-scripts/archive/v0.0.1.tar.gz | tar -xz
    mv platformsh-api-scripts-0.0.1 platformsh-api-scripts
```

And edit the "crons" section to use the scripts:

```yaml
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

Exclude the scripts directory in your `.gitignore` file:

```
/platformsh-api-scripts
```

### Alternative: using the Platform.sh CLI.

The CLI is better supported, so if you can, it's probably better to use it. The config would be similar:

```yaml
hooks:
  build: |
    set -e
    curl -sfS https://platform.sh/cli/installer | php

crons:
  # Automatically redeploy every month.
  redeploy:
    spec: '0 0 1 * *'
    cmd: |
      if [ "$PLATFORM_BRANCH" = master ]; then
        platform redeploy --yes --no-wait
      fi
  # Automatically snapshot every week.
  snapshot:
    spec: '0 0 * * 0'
    cmd: |
      if [ "$PLATFORM_BRANCH" = master ]; then
        platform snapshot:create --yes --no-wait
      fi
```
