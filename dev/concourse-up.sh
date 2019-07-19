#!/usr/bin/env bash

export CONCOURSE_FQDN='concourse.dev.localhost'

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker-compose up -d

until curl -f -s --noproxy localhost "http://localhost:9091" > /dev/null
do
    echo 'Waiting 2 sec for the Push Gateway to be up and running...'
    sleep 2
done

open "http://localhost:9091"

until curl -f -s --noproxy ${CONCOURSE_FQDN} "http://${CONCOURSE_FQDN}:8080" > /dev/null
do
    echo 'Waiting 2 sec for Concourse to be up and running...'
    sleep 2
done

open "http://${CONCOURSE_FQDN}:8080"
