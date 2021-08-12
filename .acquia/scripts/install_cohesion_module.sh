#!/usr/bin/env bash

(
    cd /home/node
    mkdir -p drupal/{cohesion,cohesion-theme}

    rsync -a . ./drupal/cohesion --exclude drupal --exclude Jenkinsfile --exclude .git_commit --exclude e2e-tests --exclude themes --exclude .gitignore --exclude .git_previous_commit --exclude .git --exclude cohesion-services --exclude apps --exclude json --exclude modules/cohesion_sync/js/src
    rsync -a ./themes/cohesion_theme/* ./drupal/cohesion-theme/

    docker cp ./drupal/cohesion cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/modules/contrib/dx8
    docker cp ./drupal/cohesion-theme cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/themes
    docker cp ./cohesion-services/drupal/drupal/install/dx8 cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/profiles/contrib

    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'mv /var/www/html/drupal/docroot/modules/contrib/dx8/composer.dev.json /var/www/html/drupal/docroot/modules/contrib/dx8/composer.json'
    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c '/var/www/html/install-cohesion-dependencies.sh'
    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'cd /var/www/html/drupal && ./vendor/bin/drush si lightning --account-name=webadmin --account-pass=webadmin --db-url=mysql://webadmin:webadmin@127.0.0.1/drupal --site-name=Lightning -y'
    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'cd /var/www/html/drupal && ./vendor/bin/drush en -y cohesion cohesion_sync cohesion_base_styles cohesion_custom_styles cohesion_elements cohesion_style_helpers cohesion_templates cohesion_website_settings example_element request_data_conditions admin_toolbar admin_toolbar_links_access_filter admin_toolbar_tools'
    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'cd /var/www/html/drupal && ./vendor/bin/drush theme:enable -y cohesion_theme'

# (This is for Cypress)
    # cd /home/node/e2e-tests
# (This is for Cypress)
    # rm -rf ./node_modules
# (This is for Cypress)
    # npm install
# (This is for Cypress)
    # ./node_modules/.bin/cypress install

    docker cp /home/node/e2e-tests/cypress/fixtures/lightning.info.yml cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/modules/contrib/dx8/e2e-tests/cypress/fixtures/lightning.info.yml
    docker cp /home/node/e2e-tests/cypress/fixtures/phpunit.xml cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/core/phpunit.xml
    docker cp /home/node/e2e-tests/cypress/fixtures/testing.services.yml cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/sites/default/testing.services.yml

    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'chown -R www-data:www-data /var/www/html/drupal/docroot'
    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'chmod -R 0777 /var/www/html/drupal/docroot/sites/default/files'
    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'echo "\$settings[\"dx8_editable_api_url\"] = TRUE;" >> /var/www/html/drupal/docroot/sites/default/settings.php'

    # Copy sql dump file from scenarios
    DUMP_TO_USE=$(cat ../cohesion-services/dx8-gateway/node/app/config.json | jq .version -r)

    aws s3 ls "s3://coh-jenkins-backup/scenarios-db-backup/desktop-dump-${DUMP_TO_USE}.sql"

    if [[ $? = "0" ]]; then
        aws s3 cp "s3://coh-jenkins-backup/scenarios-db-backup/desktop-dump-${DUMP_TO_USE}.sql" ./desktop-scenarios.sql
        aws s3 cp "s3://coh-jenkins-backup/scenarios-db-backup/mobile-dump-${DUMP_TO_USE}.sql" ./mobile-scenarios.sql
    else
        aws s3 cp "s3://coh-jenkins-backup/scenarios-db-backup/desktop-dump-develop.sql" ./desktop-scenarios.sql
        aws s3 cp "s3://coh-jenkins-backup/scenarios-db-backup/mobile-dump-develop.sql" ./mobile-scenarios.sql
    fi

    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'rm -f /var/www/html/drupal/docroot/modules/contrib/dx8/e2e-tests/cypress/fixtures/scenarios/scenarios.sql'
    docker exec cohesion-drupal-client-${BUILD_TAG} bash -c 'mkdir -p /var/www/html/drupal/docroot/modules/contrib/dx8/e2e-tests/cypress/fixtures/scenarios'
    docker cp ./desktop-scenarios.sql cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/modules/contrib/dx8/e2e-tests/cypress/fixtures/scenarios/desktop-scenarios.sql
    docker cp ./mobile-scenarios.sql cohesion-drupal-client-${BUILD_TAG}:/var/www/html/drupal/docroot/modules/contrib/dx8/e2e-tests/cypress/fixtures/scenarios/mobile-scenarios.sql
)
