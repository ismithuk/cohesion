#!/usr/bin/env bash

(
    cd /home/node/e2e-tests
    NODE_API_CONTAINER_IP=$(docker inspect cohesion-api-${BUILD_TAG} -f "{{.NetworkSettings.IPAddress}}")
    DRUPAL_CLIENT_PORT=$(echo $((3000 + ${CHANGE_ID} + ${BUILD_NUMBER})) | cut -c1-4)

    if [[ $1 = "base" ]]; then
      CYPRESS_testSitePath=/var/www/html/drupal/docroot CYPRESS_containerName=cohesion-drupal-client-${BUILD_TAG} CYPRESS_baseUrl=http://127.0.0.1:${DRUPAL_CLIENT_PORT} CYPRESS_apiURL=http://${NODE_API_CONTAINER_IP}:${NODE_API_PORT-3000} node runtests.js setup
    fi

    if [[ $1 != "base" ]] && [[ $1 != "scenarios" ]]; then
      CYPRESS_testSitePath=/var/www/html/drupal/docroot CYPRESS_containerName=cohesion-drupal-client-${BUILD_TAG} CYPRESS_baseUrl=http://127.0.0.1:${DRUPAL_CLIENT_PORT} CYPRESS_apiURL=http://${NODE_API_CONTAINER_IP}:${NODE_API_PORT-3000} yarn setup
    fi

    if [[ $? -ne 0 ]]; then
        exit 50
    fi

    if [[ ! -z "$(ls -A ./cypress/videos)" ]]; then
        aws s3 cp ./cypress/videos s3://cypress-screenshots/builds/${BRANCH_NAME}/${BUILD_ID} --recursive
    fi
    if [[ ! -z "$(ls -A ./cypress/screenshots)" ]]; then
        aws s3 cp ./cypress/screenshots s3://cypress-screenshots/builds/${BRANCH_NAME}/${BUILD_ID} --recursive
    fi

    CYPRESS_testSitePath=/var/www/html/drupal/docroot CYPRESS_containerName=cohesion-drupal-client-${BUILD_TAG} CYPRESS_baseUrl=http://127.0.0.1:${DRUPAL_CLIENT_PORT} CYPRESS_apiURL=http://${NODE_API_CONTAINER_IP}:${NODE_API_PORT-3000} node runtests.js $1

    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        EXIT_CODE=50
    fi

    if [[ ! -z "$(ls -A ./cypress/videos)" ]]; then
        aws s3 cp ./cypress/videos s3://cypress-screenshots/builds/${BRANCH_NAME}/${BUILD_ID} --recursive
    fi
    if [[ ! -z "$(ls -A ./cypress/screenshots)" ]]; then
        aws s3 cp ./cypress/screenshots s3://cypress-screenshots/builds/${BRANCH_NAME}/${BUILD_ID} --recursive
    fi

    exit $EXIT_CODE
)
