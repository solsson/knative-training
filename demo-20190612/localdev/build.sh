#!/bin/bash

kubectl delete -f build.yaml --timeout=0s --force=true 2>&1 >/dev/null
kubectl apply -f build-template-kaniko.yaml
kubectl apply -f build.yaml

sleep 1
BUILDPOD=$(kubectl get pods -l build.knative.dev/buildName=wait-html -o=jsonpath='{.items[0].metadata.name}')
echo "Buildpod: $BUILDPOD"

until kubectl logs -c build-step-custom-source $BUILDPOD; do
  echo "Source container not available yet ..."
  sleep 1
done

echo "Copying source, with the awaited file last"
for f in index.html Dockerfile; do
  kubectl cp $f $BUILDPOD:/workspace -c build-step-custom-source
done

until kubectl logs -f -c build-step-build-and-push $BUILDPOD; do
  echo "When you see a resulting image digest here, press Ctrl+C"
  sleep 1
done
