## Dev Environment for UCSC CampusPress theme/plugin
This docker environment builds a dev environment running both the theme and plugin that run on Campus Press.

## Prerequisites
The instructions assume you have git and docker installed. https://www.docker.com/products/docker-desktop/

### Development Environment Setup

* First we will clone this repo that contains the Dockerfiles and nginx conf/certs to run both the ucsc-2022 theme as well as the ucsc-gutenberg-blocks plugin
  * `git clone https://github.com/ucsc/wp-dev.ucsc.git && cd wp-dev.ucsc`
* If you haven't already edit you hosts file and add "127.0.0.1  wp-dev.ucsc" or use the command below
  * `sudo echo "127.0.0.1  wp-dev.ucsc" >> /etc/hosts`
* Create/Start the WordPress server with HTTPS & php ldap module (This command may take a few moments to finish)
  * `docker compose up -d`
* Check that a `wp-config.php` file exists in the `public/` folder that was generated before proceeding
* The following script will clone the theme and plugin to the correct directory.
  * `./gitclone.sh`
* next we will install WordPress, activate the theme & plugin, run `composer install` on the theme as well as `npm install` on both the plugin and the theme
  * `docker compose -f docker-compose-build.yml run theme_composer`
  * `docker compose -f docker-compose-build.yml run theme_npm_install`
  * `docker compose -f docker-compose-build.yml run plugin_npm_install`
  * `docker compose -f docker-compose-build.yml run wordpress_install`
* Now that the plugin and theme are both built we can start watching for changes to the theme and plugin and rebuild with the following command.
  * `docker compose -f docker-compose-start.yml up -d`


At this point you should be able to visit https://wp-dev.ucsc/wp-admin in a browser. In Google Chrome you will get a error saying "Your connection is not private", this is due to the local ssl cert. You can click Advanced -> proceed to wp-dev.ucsc. To login use: `U: user P: password`


* The theme is located at `public/wp-content/themes/ucsc-2022`
* The theme is located at `public/wp-content/plugins/ucsc-gutenberg-blocks`

### Vscode/Xdebug setup

The PHP Debug plugin is required: https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug

On the debug tab click `Create a launch.json file` and select type `php`.

You can replace the contents of `launch.json` with the following:

```
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
