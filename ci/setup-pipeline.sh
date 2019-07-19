#!/usr/bin/env bash

set -u

: ${CONCOURSE_FQDN?CONCOURSE_FQDN must be set}
: ${CONCOURSE_USER?CONCOURSE_USER must be set}
: ${CONCOURSE_PASSWORD?CONCOURSE_PASSWORD must be set}
: ${DOCKER_REPO?DOCKER_REPO must be set}
: ${DOCKER_USER?DOCKER_USER must be set}
: ${DOCKER_PASSWORD?DOCKER_PASSWORD must be set}

PIPELINE_NAME='prometheus-pushgateway-resource-ci'

curl --noproxy ${CONCOURSE_FQDN} -s -f -o fly "http://${CONCOURSE_FQDN}:8080/api/v1/cli?arch=amd64&platform=darwin"
chmod u+x fly

vars_file=$(mktemp /tmp/setup-pipeline.XXXXXX)

# TODO add trap to remove tmp file

cat <<EOF > ${vars_file}
docker_repo: ${DOCKER_REPO}
docker_user: ${DOCKER_USER}
docker_password: ${DOCKER_PASSWORD}
EOF

./fly --target=concourse login \
    --concourse-url="http://${CONCOURSE_FQDN}:8080" \
    --username=${CONCOURSE_USER} \
    --password=${CONCOURSE_PASSWORD} \
    --team-name=main

./fly --target=concourse set-pipeline \
    --non-interactive \
    --pipeline=${PIPELINE_NAME} \
    --load-vars-from=${vars_file} \
    --config=pipeline.yml

./fly --target=concourse unpause-pipeline -p ${PIPELINE_NAME}
