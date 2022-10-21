FROM wordpress:6.0.3-php8.1-apache

RUN set -x \
  && apt-get update \
  && apt-get install -y libldap2-dev git \
  && rm -rf /var/lib/apt/lists/* \
  && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
  && docker-php-ext-install ldap

