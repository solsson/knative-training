#!/bin/bash
# If you're in the business of demoing stuff it might come in handy to have a known "latest"
set -e

for R in serving build eventing-sources eventing; do
  rm -r ./knative-releases/$R/latest 2>/dev/null || echo "No ./latest at $R"
  gsutil -m cp -r -n gs://knative-releases/$R ./knative-releases
done
