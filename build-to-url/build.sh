#!/bin/bash
set -e

# see ../git
# kubectl -n git port-forward gogs-0 3000
GITHOST=http://localhost:3000/

GITREPO=ExampleSource/kanikobuild.git

[ -e ./.git ] && echo ".git already exists here" && exit 1
[ -e ./gittemp ] && echo "gittemp already exists here" && exit 2

git clone -n "$GITHOST$GITREPO" gittemp
mv gittemp/.git ./.git && rmdir gittemp
git config user.email "knative@example.com"
git config user.name "Knative Training"
git add --no-warn-embedded-repo .
git commit -m "$(date)"
git push origin HEAD
GITREV=$(git rev-parse HEAD)
rm -rf ./.git
cat service-build.yaml | sed "s/revision: master/revision: $GITREV/" | kubectl apply -f -
