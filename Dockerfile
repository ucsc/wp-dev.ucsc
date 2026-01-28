FROM wordpress:6.5.5-php8.1-apache

RUN set -x \
  && apt-get update \
  && apt-get install -y libldap2-dev git \
  && rm -rf /var/lib/apt/lists/* \
  && docker-php-ext-configure ldap \
  && docker-php-ext-install ldap

RUN pecl install "xdebug" \
  && docker-php-ext-enable xdebug

RUN echo "[xdebug]" >> /usr/local/etc/php/conf.d/xdebug.ini && \
  echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini && \
  echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini && \
  echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/xdebug.ini && \
  echo "xdebug.idekey=\"VSCODE\"" >> /usr/local/etc/php/conf.d/xdebug.ini && \
  echo "xdebug.log=/tmp/xdebug.log" >> /usr/local/etc/php/conf.d/xdebug.ini
