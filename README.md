# Docker Environment for UCSC WordPress theme and plugins

## Prerequisites

The instructions assume you have git and [Docker](https://www.docker.com/products/docker-desktop/) installed.

## Setup

1. Clone this repo
      * `git clone https://github.com/ucsc/wp-dev.ucsc.git && cd wp-dev.ucsc`

2. Edit your hosts file and add `127.0.0.1  wp-dev.ucsc` or use the command below
     * `sudo echo "127.0.0.1  wp-dev.ucsc" >> /etc/hosts`
  
3. Change `.env.example.txt` to `.env` and update the variables if you like.

4. Build and start the WordPress server with HTTPS & PHP LDAP module (Allow time for this command to finish)
     * `docker compose up -d`

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

## Running the Docker services for development

Now that WordPress is installed and the plugins and theme are built, we can start watching for changes to code and rebuild when necessary

* Starts the WordPress server environment
  * `docker compose up -d`
* Starts the Node development environments for the theme and blocks plugin
  * `docker compose -f docker-compose-start.yml up -d`

> [!NOTE]  
> Swap `up` with `down` in the commands above to stop your containers. You must run both commands to start and stop the development environments.

At this point you should be able to visit https://wp-dev.ucsc/wp-admin in a browser. In Google Chrome you will get a error saying "Your connection is not private", this is due to the local certificates. You can click Advanced -> proceed to wp-dev.ucsc. To login:

* username: `admin`
* password `password`


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
