# Experimental: Platform.sh API scripts

No warranty and no license. Don't use this unless you know what you are doing.

As an alternative to installing the Platform.sh CLI on an environment, these
scripts help run API actions without any particular dependencies (just things
like `curl`, `sed`, and a few environment variables).

## Scripts

* `redeploy.sh` will set an environment variable named `_redeploy` to the
  current time, thus triggering a redeploy.
* `snapshot.sh` will request a snapshot of the current environment.

## Usage

1. Create a machine user who only has access to the project(s) where you want to use these scripts.
2. Log in as the machine user, and create an [API token](https://docs.platform.sh/gettingstarted/cli/api-tokens.html)
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
    git clone https://github.com/pjcdawkins/platformsh-api-scripts.git    
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
