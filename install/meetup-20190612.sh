#!/bin/bash
set -e

[ "$1" != "--auto-accept=true" ] && {
  echo "KUBECONFIG=$KUBECONFIG"
  kubectl config current-context
  kubectl cluster-info
  [ -z "$(kubectl -n registry get endpoints knative -o jsonpath='{ .subsets[*].addresses[*].ip }')" ] && \
    echo "This installer assumes that https://github.com/triggermesh/knative-local-registry is installed" && \
    exit 1
  read -p "Press enter to install Knative in this cluster"
}

#./knative-releases-dowload.sh

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
  labels:
    istio-injection: disabled
EOF

kubectl label namespace default istio-injection=disabled --overwrite=true

kubectl apply -f https://github.com/knative/serving/releases/download/v0.5.2/istio-crds.yaml
curl -L https://github.com/knative/serving/releases/download/v0.5.2/istio-lean.yaml | sed 's/2048Mi/128Mi/' | kubectl apply -f -

# https://knative.dev/docs/install/knative-with-any-k8s/#installing-knative

# Got an error "no matches for kind Image in version caching.internal.knative.dev/v1alpha1" on the initial run
for run in 1 2; do
kubectl apply --selector knative.dev/crd-install=true \
   --filename https://github.com/knative/serving/releases/download/v0.6.1/serving.yaml \
   --filename https://github.com/knative/build/releases/download/v0.6.0/build.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.6.0/release.yaml \
   --filename https://github.com/knative/eventing-sources/releases/download/v0.6.0/eventing-sources.yaml \
   --filename https://github.com/knative/serving/releases/download/v0.6.1/monitoring.yaml \
   --filename https://raw.githubusercontent.com/knative/serving/v0.6.1/third_party/config/build/clusterrole.yaml
sleep 1
done

kubectl apply --filename https://github.com/knative/serving/releases/download/v0.6.1/serving.yaml --selector networking.knative.dev/certificate-provider!=cert-manager \
   --filename https://github.com/knative/build/releases/download/v0.6.0/build.yaml \
   --filename https://github.com/knative/eventing/releases/download/v0.6.0/release.yaml \
   --filename https://github.com/knative/eventing-sources/releases/download/v0.6.0/eventing-sources.yaml \
   --filename https://raw.githubusercontent.com/knative/serving/v0.6.1/third_party/config/build/clusterrole.yaml

#kubectl apply --filename https://github.com/knative/serving/releases/download/v0.6.1/monitoring.yaml
#kubectl -n knative-monitoring scale --replicas=0 statefulset elasticsearch-logging
kubectl apply --filename https://github.com/knative/serving/releases/download/v0.6.1/monitoring-metrics-prometheus.yaml
kubectl -n knative-monitoring scale --replicas=1 statefulset prometheus-system
