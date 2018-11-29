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

SERVING_GIT=9dd4beb2f4b03a8aea12a9ae7c26326b5dab5981

kubectl apply -f https://github.com/knative/serving/raw/${SERVING_GIT}/third_party/istio-1.0.4/istio-crds.yaml
kubectl apply -f https://github.com/knative/serving/raw/${SERVING_GIT}/third_party/istio-1.0.4/istio.yaml

while [ $(kubectl get crd gateways.networking.istio.io -o jsonpath='{.status.conditions[?(@.type=="Established")].status}') != 'True' ]; do
  echo "Waiting on Istio CRDs"; sleep 1
done
while [ -z "$(kubectl -n istio-system get endpoints istio-sidecar-injector -o jsonpath='{ .subsets[*].addresses[*].ip }')" ]; do
  echo "Waiting for istio-sidecar-injector to be ready"
done

# https://github.com/solsson/go-ko-runner
korunner=solsson/go-ko-runner@sha256:a1c2b790e59c7c482879181339fef03ca3486cf133691642b5feff482155f9e0
echo "korunner=$korunner"
kubectl create serviceaccount ko-runner --namespace=default
kubectl create clusterrolebinding ko-runner --clusterrole=cluster-admin --serviceaccount=default:ko-runner --namespace=default

kubectl run install-knative-serving --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/serving" \
  --env="KO_REVISION=$SERVING_GIT" \
  --env="EXIT_DELAY=1"

# TODO run a single ko pod with init containers instead, to get predictable order
kubectl run install-knative-build-pipeline --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/build-pipeline" \
  --env="KO_REVISION=f70944ea6b59295e80de9e531df5a292ceb48d43" \
  --env="INSTALL_THIRD_PARTY=_" \
  --env="EXIT_DELAY=3600"

# TODO can we do a wait like the above and after that delete the service account?

# TODO https://github.com/knative/serving/blob/master/DEVELOPMENT.md#install-logging-and-monitoring-backends