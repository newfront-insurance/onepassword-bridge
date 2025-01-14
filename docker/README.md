# Deploy 1Password SCIM Bridge with Docker

*Learn how to deploy 1Password SCIM Bridge using Docker Compose or Docker Swarm.*

**Table of contents:**

- [Before you begin](#before-you-begin)
- [Step 1: Choose a deployment option](#step-1-choose-a-deployment-option)
- [Step 2: Install Docker tools](#step-2-install-docker-tools)
- [Step 3: Deploy 1Password SCIM Bridge](#step-3-deploy-1password-scim-bridge)
- [Step 4: Test the SCIM bridge](#step-4-test-the-scim-bridge)
- [Step 5: Connect your identity provider](#step-5-connect-your-identity-provider)
- [Update your SCIM bridge](#update-your-scim-bridge)
- [Advanced: Manual SCIM bridge deployment](#Advanced-Manual-deployment)
- [Appendix: Advanced `scim.env` options](#appendix-advanced-scimenv-options)
- [Appendix: Generate `scim.env` on Windows](#appendix-generate-scimenv-on-windows)

## Before you begin

Before you begin, familiarize yourself with [PREPARATION.md](/PREPARATION.md) and complete the necessary steps there.

## Step 1: Choose a deployment option

Using Docker, you have two deployment options: [Docker Compose](https://docs.docker.com/compose/) and [Docker Swarm](https://docs.docker.com/engine/swarm/).

**Docker Swarm** is the recommended option, but Docker Compose can also be used depending on your deployment needs. You can set up a Docker host on your own infrastructure or on a cloud provider of your choice.

The `scimsession` file is passed into the docker container using an environment variable, which is less secure than Docker Swarm secrets, Kubernetes secrets, or AWS Secrets Manager, all of which are supported and recommended for production use.

## Step 2: Install Docker tools

1. On your local machine, install [Docker for Desktop](https://www.docker.com/products/docker-desktop) and start Docker.
2. Install the `docker-compose` and `docker-machine` command-line tools on your local machine. If you're using macOS and Homebrew, make sure you're using the _cask_ app-based version of Docker (`brew cask install docker`), not the default CLI version.

## Step 3: Deploy 1Password SCIM Bridge

To automatically deploy 1Password SCIM Bridge with [Docker Swarm](#docker-swarm) or [Docker Compose](#docker-compose), use our script, [./docker/deploy.sh](deploy.sh).

### Docker Swarm

For this method, you'll need to have joined a Docker Swarm with the target deployment node. Learn how to [create a swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/).

After you've created a swarm, log in with `docker swarm join`. Then use the provided bash script [./docker/deploy.sh](deploy.sh) to deploy your SCIM bridge. The script will do the following:

1. Ask whether you're using Google Workspace as your identity provider so you can add your configuration files as Docker Secrets within your Swarm cluster.
2. Ask whether you're deploying using Docker Swarm or Docker Compose.
3. Ask for your SCIM bridge domain name so you can automatically get a TLS certificate from Let's Encrypt. This is the domain you selected in [PREPARATION.md](/PREPARATION.md).
4. Ask for your `scimsession` file location to add your `scimsession` file as a Docker Secret within your Swarm cluster.
5. Deploy a container using `1password/scim`, as well as a `redis` container. The `redis` container is necessary to store Let's Encrypt certificates, as well as act as a cache for your identity provider information.

The logs from the SCIM bridge and Redis containers will be streamed to your machine. If everything seems to have deployed successfully, press Ctrl+C to exit, and the containers will remain running on the remote machine.

At this point, you should set a DNS record routing the domain name to the IP address of the `op-scim` container.

### Docker Compose

To deploy with Docker Compose, you'll need Docker Desktop set up either locally or remotely. Learn how to [set up Docker Desktop](https://docs.docker.com/desktop/). Then follow these steps:

1. Make sure your environment is set up by running the command `eval %{docker-machine env $machine_name}` using the machine name you've chosen.
2. Run the [./docker/deploy.sh](deploy.sh) script.
3. Choose Compose as the deployment method when prompted. Any references for Docker Secrets will be added to the Docker Compose deployment as environment variables.

<hr>

## Advanced Manual deployment

<details>
<summary>How to manually deploy 1Password SCIM Bridge</summary>

You can also manually deploy the SCIM bridge with [Docker Swarm](#docker-swarm-manual-deployment) or [Docker Compose](#docker-compose-manual-deployment).

### Clone `scim-examples`

You’ll need to clone this repository using `git` into a directory of your choice:

```bash
git clone https://github.com/1Password/scim-examples.git
```

You can then browse to the Docker directory:

```bash
cd scim-examples/docker/
```

### Docker Swarm manual deployment

To use Docker Swarm, run `docker swarm init` or `docker swarm join` on the target node and complete that portion of the setup. Refer to [Docker’s documentation for more details](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/).

Unlike Docker Compose, you won't need to set the `OP_SESSION` variable in `scim.env`. Instead, you'll use Docker Secrets to store the `scimsession` file. You'll still need to set the environment variable `OP_TLS_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_TLS_DOMAIN` to that domain name. This is also needs to be set for self-managed TLS Docker Swarm deployment.

#### If you use Google Workspace as your identity provider

If you use Google Workspace as your identity provider, you'll need to set up some additional secrets.

First, edit the file located at `scim-examples/beta/workspace-settings.json` and enter in the appropriate details. Then create the necessary secrets for Google Workspace:

```bash
# this is the path of the JSON file you edited in the paragraph above
cat /path/to/workspace-settings.json | docker secret create workspace-settings -
# replace <google keyfile> with the name of the file Google generated for your Google Service Account
cat /path/to/<google keyfile>.json | docker secret create workspace-credentials -

```
<br>

After that’s set up, you can do the following (using the alternate command for the stack deployment if using Google Workspace as your identity provider):

```bash
# enter the swarm directory
cd scim-examples/docker/swarm/
# sets up a Docker Secret on your Swarm
cat /path/to/scimsession | docker secret create scimsession -
# deploy your Stack
docker stack deploy -c docker-compose.yml op-scim
# (optional) view the service logs
docker service logs --raw -f op-scim_scim
```

Alternate Google Workspace stack deployment command:

``` bash
# deploy your Stack with Google Workspace settings
docker stack deploy -c docker-compose.yml -c gw-docker-compose.yml op-scim
```
Learn more about [connecting Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/).
  
### Self managed TLS for Docker Swarm

Provide your own key and cert files to the deployment as secrets, which disables Let's Encrypt functionality. In order to utilize self managed TLS key and certificate files, you need to define these as secrets using the following commands and And finally, use `docker stack` to deploy:

```bash
cat /path/to/private.key | docker secret create op-tls-key -
cat /path/to/cert.crt | docker secret create op-tls-crt -
```

Use `docker stack` to deploy:

``` bash
# deploy your Stack with self-managed TLS using Docker Secrets
docker stack deploy -c docker-compose.yml -c docker.tls.yml op-scim
```

``` bash
# (optional) view the service logs
docker service logs --raw -f op-scim_scim
```

### Docker Compose manual deployment

When using Docker Compose, you can create the environment variable `OP_SESSION` manually by doing the following:

```bash
# only needed for Docker Compose - use Docker Secrets when using Swarm
# enter the compose directory (if you aren’t already in it)
cd scim-examples/docker/compose/
SESSION=$(cat /path/to/scimsession | base64 | tr -d "\n")
sed -i '' -e "s/OP_SESSION=$/OP_SESSION=$SESSION/" ./scim.env
```

You’ll also need to set the environment variable `OP_TLS_DOMAIN` within `scim.env` to the URL you selected during [PREPARATION.md](/PREPARATION.md). Open that in your preferred text editor and change `OP_TLS_DOMAIN` to that domain name.

Ensure that `OP_TLS_DOMAIN` is set to the domain name you’ve set up before you continue.

#### If you use Google Workspace as your identity provider

If you use Google Workspace as your identity provider, you'll need to set up some additional secrets.

First, edit the file located at `scim-examples/beta/workspace-settings.json` and enter in the appropriate details. Then create the necessary secrets for Google Workspace:

```bash
# enter the compose directory (if you aren’t already in it)
cd scim-examples/docker/compose/
# this is the path of the JSON file you edited in the paragraph above
WORKSPACE_SETTINGS=$(cat /path/to/workspace_settings.json | base64 | tr -d "\n")
sed -i '' -e "s/OP_WORKSPACE_SETTINGS=$/OP_WORKSPACE_SETTINGS=$WORKSPACE_SETTINGS/" ./scim.env
# replace <google keyfile> with the name of the file Google generated for your Google Service Account
GOOGLE_CREDENTIALS=$(cat /path/to/<google keyfile>.json | base64 | tr -d "\n")
sed -i '' -e "s/OP_WORKSPACE_CREDENTIALS=$/OP_WORKSPACE_CREDENTIALS=$GOOGLE_CREDENTIALS/" ./scim.env
```
<br>

And finally, use `docker-compose` to deploy:

```bash
# enter the compose directory (if you aren’t already in it)
cd scim-examples/docker/compose/
# create the container
docker-compose -f docker-compose.yml up --build -d
# (optional) view the container logs
docker-compose -f docker-compose.yml logs -f
```
Learn more about [connecting Google Workspace to 1Password SCIM Bridge](https://support.1password.com/scim-google-workspace/).

</details>

<hr>

## Step 4: Test the SCIM bridge

To test if your SCIM bridge is online, open the public IP address of the Docker Host for your bridge in a web browser. You should be able to enter your bearer token to verify that your SCIM bridge is up and running.

You can also use the following `curl` command to test the SCIM bridge from the command line:

```bash
curl --header "Authorization: Bearer TOKEN_GOES_HERE" https://<domain>/scim/Users
```

## Step 5: Connect your identity provider

To finish setting up automated user provisioning, [connect your identity provider to the SCIM bridge](https://support.1password.com/scim/#step-3-connect-your-identity-provider).

## Update your SCIM Bridge

👍 Check for 1Password SCIM Bridge updates on the [SCIM bridge release page](https://app-updates.agilebits.com/product_history/SCIM).

To upgrade your SCIM bridge, `git pull` the latest versions from this repository. Then re-apply the `.yml` file. For example:

### Docker Swarm

```bash
cd scim-examples/
git pull
cd docker/swarm/
# For Docker Swarm updates:
# add second yaml if using Google Workspace `docker stack deploy -c docker-compose.yml -c gw-docker-compose.yml op-scim`
docker stack deploy -c docker-compose.yml op-scim
```

### Docker Compose

```bash
cd scim-examples/
git pull
cd docker/compose/
# for Docker Compose updates:
docker-compose -f docker-compose.yml up --build -d
```

After 2-3 minutes, the bridge should come back online with the latest version.

## Appendix: Advanced `scim.env` options

The following options are available for advanced or custom deployments. Unless you have a specific need, these options do not need to be modified.

* `OP_TLS_CERT_FILE` and `OP_TLS_KEY_FILE`: These two variables can be set to the paths of a key file and certificate file secrets, which will disable Let's Encrypt functionality, causing the SCIM bridge to use your own manually-defined certificate when `OP_TLS_DOMAIN` is also defined. This is only supported with Docker Swarm, not Docker Compose. Note the additional steps above in the [manual self managed TLS section](#Self-managed-TLS-for-Docker-Swarm) for enabling this feature.
* `OP_PORT`: When `OP_TLS_DOMAIN` is set to blank, you can use `OP_PORT` to change the default port from 3002 to one you choose.
* `OP_REDIS_URL`: You can specify a `redis://` or `rediss://` (for TLS) URL here to point towards a different Redis host. You can then remove the sections in `docker-compose.yml` that refer to Redis to not deploy that container. Redis is still required for the SCIM bridge to function.
* `OP_PRETTY_LOGS`: You can set this to `1` if you'd like the SCIM bridge to output logs in a human-readable format. This can be helpful if you aren't planning on doing custom log ingestion in your environment.
* `OP_DEBUG`: You can set this to `1` to enable debug output in the logs, which is useful for troubleshooting or working with 1Password Support to diagnose an issue.
* `OP_TRACE`: You can set this to `1` to enable trace-level log output, which is useful for debugging Let’s Encrypt integration errors.
* `OP_PING_SERVER`: You can set this to `1` to enable an optional `/ping` endpoint on port `80`, which is useful for health checks. It's disabled if `OP_TLS_DOMAIN` is unset and TLS is not in use.

## Appendix: Generate `scim.env` on Windows

On Windows, refer to [./docker/compose/generate-env.bat](generate-env.bat) to learn how to generate the `base64` string for `OP_SESSION`.
