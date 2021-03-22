#!/usr/bin/env bash

set -e

#/ build.sh [VERSION] [REPOSITORY]
#/
#/ Builds the image for the Concourse resource, tags it with the provided VERSION and pushes it to
#/ a given repository on Dockerhub or any DTR.
#/
#/ Examples:
#/
#/ ./build.sh VERSION REPOSITORY [--latest]
#/
#/ Options:
#/   --help: Display this help message
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

if [[ -z $1 || -z $2 ]]; then usage ; fi

version=$1
repo=$2
latest=$3

image_name='prometheus-pushgateway-resource'

echo "Building Image"
docker build --no-cache -t ${image_name} .
docker tag ${image_name} ${repo}/${image_name}:${version}
docker push ${repo}/${image_name}:${version}
if [ "${latest:-}" == "--latest" ]; then
  echo "Tagging as latest"
  docker tag ${image_name} ${repo}/${image_name}:latest
  docker push ${repo}/${image_name}:latest
fi
