#!/usr/bin/env bash

set -e

test -z "$1" && echo Need version number && exit 1

IMAGE="scribner/webhook-listener:$1"

docker build . -t  $IMAGE

docker tag $IMAGE k8scc01covidacr.azurecr.io/$IMAGE
docker push k8scc01covidacr.azurecr.io/$IMAGE
