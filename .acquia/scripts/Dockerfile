# see https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-apache.html
# FROM ${REPO_LOCATION}php-apache:7.2
ARG REPO_LOCATION
FROM ${REPO_LOCATION}php:7.2-apache

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd pdo_mysql


RUN apt-get update -y && apt-get install -y sudo git zip unzip jq vim mariadb-server && \
    /etc/init.d/mysql restart && mysqladmin password "password" && \
    find /var/lib/mysql -type f -exec touch {} \; && /etc/init.d/mysql restart && sleep 5 && \
    mysql -uroot -ppassword -e 'CREATE USER "webadmin"@"%" IDENTIFIED BY "webadmin"; create database drupal; GRANT ALL ON drupal.* TO "webadmin"@"%";'

RUN echo "sendmail_path=$(which true)" > /usr/local/etc/php/conf.d/cohesion.ini
RUN echo "memory_limit=-1" >> /usr/local/etc/php/conf.d/cohesion.ini
RUN echo "max_execution_time=0" >> /usr/local/etc/php/conf.d/cohesion.ini

WORKDIR /var/www/html

COPY ./container-stable.sh /var/www/html
COPY ./install-cohesion-dependencies.sh /var/www/html
COPY ./apache-vhost.conf /etc/apache2/sites-enabled/drupal.conf

# Install SSH keys and composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --1 && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

# Install drupal-lightning using composer create-project
RUN COMPOSER_MEMORY_LIMIT=-1 composer create-project acquia/lightning-project:8.7.1 drupal --no-install && \
    cd /var/www/html/drupal && composer require acquia/lightning:4.1.0 --no-update && composer require drupal/libraries:3.0.0-alpha1 && \
    composer require drush/drush && \
    mkdir -p /var/www/html/drupal/docroot/themes && \
    mkdir -p /var/www/html/drupal/docroot/profiles/contrib && \
    chown -R www-data: /var/www/html/drupal && \
    chmod -R 0777 /var/www/html/drupal/docroot && \
    a2dissite 000-default
