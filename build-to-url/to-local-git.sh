#!/bin/bash
set -e

#git clone http://git.git.svc.cluster.local/ExampleSource/kanikobuild.git
# with: kubectl -n git port-forward gogs-0 3000
git clone http://localhost:3000/ExampleSource/kanikobuild.git kanikobuild.git
cp Dockerfile frontend.go ./kanikobuild.git/

cd ./kanikobuild.git/
git add .

git config user.email "knative@example.com"
git config user.name "Knative Training"

git commit -m "initial commit"
git push origin master
