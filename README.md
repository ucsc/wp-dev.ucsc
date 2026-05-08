# Docker Environment for UCSC WordPress theme and plugins

## Prerequisites

1. The instructions assume you have git and [Docker](https://www.docker.com/products/docker-desktop/) installed. Have Docker Desktop running while going through the steps.
2. **Apple Silicon Macs (M1/M2/M3/M4):** This project uses `platform: linux/amd64` images. In Docker Desktop, go to **Settings > General** and enable **"Use Rosetta for x86_64/amd64 emulation on Apple Silicon"**, then click **Apply & restart**.
3. You need a [UCSC VPN connection](https://its.ucsc.edu/vpn/) to use the *Campus Directory* block in the [UCSC Gutenberg Blocks plugin](https://github.com/ucsc/ucsc-gutenberg-blocks).

## One time setup for local development

1. Clone this repo and enter the project directory:
      * `git clone https://github.com/ucsc/wp-dev.ucsc.git`
      * change to project folder `cd wp-dev.ucsc`

2. Add `127.0.0.1  wp-dev.ucsc` to your hosts file:
    * **macOS/Linux:** Run `sudo nano /etc/hosts`, add the line, then press ctrl+O, Enter, ctrl+X to save and exit
    * **Windows:** Open Notepad as Administrator, open `C:\Windows\System32\drivers\etc\hosts`, and add the line
      
3. Copy `.env.example.txt` to `.env`. The default values in `.env` (including `DB_PASSWORD`) work as-is for local development — no changes needed
     
4. Build and start the containers (allow time for this command to finish):
     * `docker compose up -d`
     * Once this is finished running you should have all docker containers up and running. You can verify this by opening up the docker app and making sure there is a green dot next to each container.
     * Troubleshooting: If there is not a green dot next to each container: select all the containers in your docker app and delete them all. Once all the containers have been deleted go to your terminal in the wp-dev.ucsc directory and run the command above again. This should solve the issue and have all containers up and running successfully.
       
       

> [!IMPORTANT]  
> Check that a `wp-config.php` file exists in the `./public/` folder before proceeding

5. Run `./setup.sh` to clone the theme and plugin repos ([ucsc-2022](https://github.com/ucsc/ucsc-2022), [ucsc-gutenberg-blocks](https://github.com/ucsc/ucsc-gutenberg-blocks), and [ucsc-custom-functionality](https://github.com/ucsc/ucsc-custom-functionality)) into the correct project directories.

6. Run the following commands to install dependencies, set up WordPress, and activate the theme and plugins (messages about orphan containers are ok).
     * `docker compose -f docker-compose-install.yml run theme_composer_install`
     * `docker compose -f docker-compose-install.yml run theme_npm_install`
     * `docker compose -f docker-compose-install.yml run plugin_npm_install` (may take up to 2 minutes to complete)
     * `docker compose -f docker-compose-install.yml run wordpress_install`

7. Start the Node development watchers for the theme and blocks plugin. These will do the initial build and then watch for file changes, automatically rebuilding assets when you edit source files.
     * `docker compose -f docker-compose.yml -f docker-compose-start.yml up -d`

Your installation is now complete. See "In Your Browser" below for how to login.

## Running the Docker services for development

After the initial setup is complete, start everything with:

```
docker compose -f docker-compose.yml -f docker-compose-start.yml up -d
```

This starts the WordPress server and the Node file watchers.

> [!TIP]
> To stop all containers: `docker compose -f docker-compose.yml -f docker-compose-start.yml down`

## In Your Browser
At this point you should be able to visit https://wp-dev.ucsc/wp-admin in a browser. In Google Chrome you will get an error saying "Your connection is not private", this is due to the local certificates. You can click Advanced -> proceed to wp-dev.ucsc. To login:

* username: `admin`
* password: `password`

> [!TIP]
> 
> * You can run WP-CLI commands with `docker exec ${NAME}-cli wp <COMMAND>`
> * `${NAME}` is what you used in your `.env` file

## Troubleshooting
### "Found orphan containers" warning
If you see `WARN[0000] Found orphan containers`, add the `--remove-orphans` flag:
```
docker compose -f docker-compose.yml -f docker-compose-start.yml up -d --remove-orphans
```

### Problem logging in and getting "The password you entered for the username admin is incorrect"
If you had to redo the setup (e.g. re-ran `./setup.sh` and the install commands), the database volume may still have the old WordPress install. The `wordpress_install` command will say "WordPress is already installed" and skip setting the password. Reset it with:

```
docker exec ucsc-wordpress-cli wp user update admin --user_pass=password --path=/var/www/html
```

To fully start over with a clean database, stop everything and remove the volume first:

```
docker compose down -v
```

Then re-run the setup from step 4.

### Nginx server container crashes on startup

The `server` (nginx) container may briefly show as unhealthy with the error `host not found in upstream "wp"`. This happens when nginx starts before the WordPress container is ready on the Docker network. The server container has `restart: always` set, so it will automatically recover once WordPress is ready. If it doesn't come back after a minute, restart it manually:

```
docker compose up -d server
```