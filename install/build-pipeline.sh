#!/bin/sh
#set -e

[ "$1" != "--auto-accept=true" ] && {
  echo "KUBECONFIG=$KUBECONFIG"
  kubectl config current-context
  kubectl cluster-info
  [ -z "$(kubectl -n registry get endpoints knative -o jsonpath='{ .subsets[*].addresses[*].ip }')" ] && \
    echo "This installer assumes that https://github.com/triggermesh/knative-local-registry is installed" && \
    exit 1
  read -p "Press enter to install Knative in this cluster"
}

kubectl label namespace default istio-injection=enabled

[ -z "$KNATIVE_RELEASES" ] && {
  # See ./knative-releases-dowload.sh
  #KNATIVE_RELEASES=./knative-releases
  KNATIVE_RELEASES=https://storage.googleapis.com/knative-releases
}

kubectl apply -f ${KNATIVE_RELEASES}/serving/previous/v0.2.3/istio-crds.yaml
kubectl apply -f ${KNATIVE_RELEASES}/serving/previous/v0.2.3/istio.yaml

while [ $(kubectl get crd gateways.networking.istio.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}') != 'True' ]; do
  echo "Waiting on Istio CRDs"; sleep 1
done
while [ -z "$(kubectl -n istio-system get endpoints istio-sidecar-injector -o jsonpath='{ .subsets[*].addresses[*].ip }')" ]; do
  echo "Waiting for istio-sidecar-injector to be ready"
done

kubectl apply -f ${KNATIVE_RELEASES}/serving/previous/v0.2.3/serving.yaml

kubectl apply -f ${KNATIVE_RELEASES}/serving/previous/v0.2.3/monitoring-metrics-prometheus.yaml
kubectl apply -f ${KNATIVE_RELEASES}/serving/previous/v0.2.3/monitoring-tracing-zipkin-in-mem.yaml
#kubectl apply -f ${KNATIVE_RELEASES}/serving/previous/v0.2.3/monitoring-logs-elasticsearch.yaml

# https://github.com/solsson/go-ko-runner
korunner=solsson/go-ko-runner@sha256:a36ffaec1634a578c70b11277fc4f36df9e30c74b3ec1c5fa7412b4100bb9c54
kubectl create serviceaccount ko-runner --namespace=default
kubectl create clusterrolebinding ko-runner --clusterrole=cluster-admin --serviceaccount=default:ko-runner --namespace=default
kubectl run install-knative-build-pipeline --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/build-pipeline" \
  --env="KO_REVISION=6e91749a395b862cb70fdc2adef53c1c6ac514ea" \
  --env="EXIT_DELAY=3600"

# TODO can we do a wait like the above and after that delete the service account?
