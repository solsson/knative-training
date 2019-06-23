#!/bin/bash
# If you're in the business of demoing stuff it might come in handy to have a known "latest"
set -e

for R in \
   serving/previous/v0.5.2 \
   serving/previous/v0.6.0 \
   serving/latest \
   build/previous/v0.6.0 \
   build/latest \
   eventing-sources/latest \
   eventing/latest \
   ; do
  [[ "$(basename $R)" = "latest" ]] && [ -d ./knative-releases/$R ] && rm -r ./knative-releases/$R
  mkdir -p ./knative-releases/$R
  gsutil -m cp -r -n gs://knative-releases/$R/* ./knative-releases/$R/
done
