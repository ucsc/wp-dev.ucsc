# Docker Environment for UCSC WordPress theme and plugins

## How this environment works

This is a **home-rolled Docker Compose** environment for local development. It is
**not** [`@wordpress/env` (wp-env)](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/),
**not** [Local (LocalWP)](https://localwp.com/), **not** ddev, and **not** WP
Engine's local tooling. There is no framework CLI — the whole lifecycle is plain
`docker compose` against the compose files in this repo, with WP-CLI run inside a
container.

**Why home-rolled:** the *Campus Directory* block needs the PHP **LDAP**
extension (and a UCSC VPN connection to reach the LDAP server). Off-the-shelf
runtimes did not cleanly support a custom LDAP-enabled PHP image, so this repo
ships its own image and compose set instead.

What's in the repo:

| File | Role |
| --- | --- |
| `Dockerfile` | Builds the `wp` service from `wordpress:6.5.5-php8.1-apache`, adding the PHP **LDAP** extension and **Xdebug**. |
| `docker-compose.yml` | Base stack: `server` (nginx 1.19), `db` (mysql 8.0), `wp` (built from `Dockerfile`), `wpcli` (`wordpress:cli-php8.1`), `toxiproxy` (fault injection, see [Outage scenarios](#outage-scenarios)). |
| `docker-compose-start.yml` | Dev/watch overlay — adds the Node build/watch services for the theme and the blocks plugin. |
| `docker-compose-install.yml` | One-shot bootstrap jobs: `theme_composer_install`, `theme_npm_install`, `plugin_npm_install`, `wordpress_install`. |
| `setup.sh` | Clones the theme and product plugins into `public/wp-content/`. |
| `bin/fault.sh` | Switches LDAP / campusdirectory.ucsc.edu outage scenarios on and off. |
| `devtools/` | Toxiproxy config and the dev-only `ucsc-dev-faults` mu-plugin used by `bin/fault.sh`. |
| `.env.example.txt` | Copied to `.env` during first-time setup. |

```bash
# base WordPress stack only
docker compose up -d
# base stack + Node dev/watch environments (theme + blocks plugin)
docker compose -f docker-compose.yml -f docker-compose-start.yml up -d
```

Node versions are set by the compose images, not by the Node on your machine:
the blocks plugin services (`plugin_npm_install`, `plugin_npm_start`) use
`node:22-alpine`; the theme services still use `node:16.18.0-alpine3.15`.

> [!IMPORTANT]
> This Docker stack is the **local development environment only**. The real
> WordPress site is production and is **not** this stack. Run all builds, tests,
> and PHP through the containers (e.g. `docker compose exec wpcli wp <command>`)
> — not host Node/PHP/Composer.

The step-by-step setup below walks through this from a clean checkout.

## Prerequisites

1. The instructions assume you have git and [Docker](https://www.docker.com/products/docker-desktop/) installed. Have the docker app open while going through the steps. 
2. You need a [UCSC VPN connection](https://its.ucsc.edu/vpn/) to use the *Campus Directory* block in the [UCSC Gutenberg Blocks plugin](https://github.com/ucsc/ucsc-gutenberg-blocks).

## Setup

1. Go to your terminal and run this command to clone this repo
      * `git clone https://github.com/ucsc/wp-dev.ucsc.git`
      * cd into the folder `cd wp-dev.ucsc`

2. Edit your hosts file by running `sudo nano /etc/hosts` in your terminal and add `127.0.0.1  wp-dev.ucsc`
    * On Mac OS do ctrl+O to writeout and hit enter on your keyboard
    * Then hit ctrl+X to exit
    * You have now successfully edited you host file.
      
3. Change `.env.example.txt` to `.env` by following these steps:
      * cd into the folder `cd wp-dev.ucsc` if you are not in it already
      * Run the command `ls -a` to see hidden files and verify there is a file called `.env.example.txt`
      * Run this command to change the name to .env `cp .env.example.txt .env`
      * Run ls -a to verify the name of the file has changed to `.env`
     
4. In the wp-dev.ucsc directory build and start the WordPress server with HTTPS & PHP LDAP module (Allow time for this command to finish)
     * `docker compose up -d`
     to start the WordPress server environment
     OR
     * `docker compose -f docker-compose.yml -f docker-compose-start.yml up -d`
     to start the WordPress server environment AND the Node development environments for the theme and blocks plugin
     * Once this is finished running you should have a total of 5 docker containers up and running. You can verify this by opening up the docker app and
       making sure there is a green dot next to each container.
     * Troubleshooting: If there is not a green dot next to each container then here is what you should do: select all the containers in your docker app and
       delete them all. Once all the containers have been deleted go to your terminal in the wp-dev.ucsc directory and run `docker compose up -d` again.
       This should solve the issue and have all 5 containers up and running succesfully.
       
       

> [!IMPORTANT]  
> Check that a `wp-config.php` file exists in the `./public/` folder before proceeding

5. Run the following script to clone the theme and plugins to the correct project directories.
      * `./setup.sh`

6. Next we install WordPress, activate the theme & plugin, run composer install on the theme as well as npm install on both the plugin and the theme
     * `docker compose -f docker-compose-install.yml run theme_composer_install`
     * `docker compose -f docker-compose-install.yml run theme_npm_install`
     * `docker compose -f docker-compose-install.yml run plugin_npm_install` (may take up to 2 minutes to complete)
     * `docker compose -f docker-compose-install.yml run wordpress_install`

Your installation is now complete.

Troubleshooting: If there is not a green dot next to each container then here is what you should do: select all the containers in your docker app and
delete them all. Once all the containers have been deleted go to your terminal in the wp-dev.ucsc directory and run `docker compose up -d` again.
This should solve the issue and have all 5 containers up and running succesfully.

## Running the Docker services for development

Now that WordPress is installed and the plugins and theme are built, we can start watching for changes to code and rebuild when necessary

* Start the WordPress server environment
  * `docker compose up -d`
OR
* Start the WordPress server environment AND the Node development environments for the theme and blocks plugin
  * `docker compose -f docker-compose.yml -f docker-compose-start.yml up -d`


> [!TIP]  
> Swap `up` with `down` in the commands above to stop your containers. You must run both commands to start and stop the development environments.

## In Your Browser
At this point you should be able to visit https://wp-dev.ucsc/wp-admin in a browser. In Google Chrome you will get a error saying "Your connection is not private", this is due to the local certificates. You can click Advanced -> proceed to wp-dev.ucsc. To login:

* username: `admin`
* password `password`

> [!TIP]
> 
> * You can run WP-CLI commands with `docker exec ${NAME}-cli wp <COMMAND>`
> * `${NAME}` is what you used in your `.env` file

## Campus Directory LDAP

Campus Directory connects to LDAP exactly as production does: `ldaps://ldap-blue.ucsc.edu`, bound as `pantheon-webapps` with the `ldap_api_key` option. There is no anonymous dev mode. Put the key in `.env` as `LDAP_API_KEY` before running `wordpress_install`. On an existing install, set it once in **Settings > UCSC Gutenberg Block Settings** (or with `wp option update ldap_api_key`). You still need the UCSC VPN.

## Outage scenarios

The `wp` container always reaches `ldap-blue.ucsc.edu` and `campusdirectory.ucsc.edu` through the `toxiproxy` service, with the real hostnames and TLS, so a normal run and an outage run take the same path. Switch scenarios with `bin/fault.sh`. Each command clears the previous fault and flushes transients so cached results do not hide it.

| Command | Effect |
| --- | --- |
| `bin/fault.sh ldap-stall` / `cd-stall` | Connection accepted, no reply ever arrives |
| `bin/fault.sh ldap-down` / `cd-down` | Connection refused |
| `bin/fault.sh cd-403` / `cd-html` / `cd-500` | campusdirectory answers with that page |
| `bin/fault.sh status` | Show what is on |
| `bin/fault.sh off` | Back to normal |

## Troubleshooting 

If the error WARN[0000] Found orphan containers is encountered, use the --remove orphans flag on startup. 

docker compose -f docker-compose.yml -f docker-compose-start.yml up -d --remove-orphans

## VScode/Xdebug setup

The [PHP Debug plugin](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug) is required. On the debug tab click `Create a launch.json file` and select type `php`.

You can replace the contents of `launch.json` with the following:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html/wp-content/plugins/ucsc-gutenberg-blocks": "${workspaceRoot}"
      },
      "hostname": "wp-dev.ucsc"
    }
  ]
}
```
