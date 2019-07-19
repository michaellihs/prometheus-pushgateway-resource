#!/usr/bin/env bash

concourse_fqdn='concourse.dev.localhost'

curl --noproxy ${concourse_fqdn} -s -f -o fly "http://${concourse_fqdn}:8080/api/v1/cli?arch=amd64&platform=darwin"
chmod u+x fly

./fly --target=prometheus-pushgateway login \
    --concourse-url="http://${concourse_fqdn}:8080" \
    --username=test \
    --password=test \
    --team-name=main

./fly --target=prometheus-pushgateway set-pipeline \
    --non-interactive \
    --pipeline=prometheus-pushgateway-dev \
    --config=pipeline.yml

./fly --target=prometheus-pushgateway unpause-pipeline -p prometheus-pushgateway-dev
