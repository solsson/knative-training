#!/bin/sh

INSTALLER=meetup-20181121.sh
cat $INSTALLER \
  | sed 's/kubectl create /kubectl delete --ignore-not-found=true /' \
  | sed 's/kubectl apply /kubectl delete --ignore-not-found=true /' \
  > uninstall-$INSTALLER

cat <<EOF >> uninstall-$INSTALLER

kubectl delete --ignore-not-found=true namespace knative-eventing
kubectl delete --ignore-not-found=true namespace knative-sources
kubectl delete --ignore-not-found=true namespace kafka
kubectl delete --ignore-not-found=true namespace knative-build-pipeline
kubectl delete --ignore-not-found=true namespace knative-build
kubectl delete --ignore-not-found=true namespace knative-serving
kubectl delete --ignore-not-found=true namespace istio-system
kubectl delete --ignore-not-found=true namespace git
kubectl delete --ignore-not-found=true namespace registry
EOF

chmod u+x uninstall-$INSTALLER

source uninstall-$INSTALLER
