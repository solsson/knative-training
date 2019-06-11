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

export ISTIO_VERSION=1.1.8
rm -r istio-*
curl -o istio-${ISTIO_VERSION}-linux.tar.gz -L https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux.tar.gz
tar xvzf istio-${ISTIO_VERSION}-linux.tar.gz

mkdir ./istio-${ISTIO_VERSION}-lean-unhelm
helm template --namespace=istio-system \
  --set prometheus.enabled=false \
  --set mixer.enabled=false \
  --set mixer.policy.enabled=false \
  --set mixer.telemetry.enabled=false \
  `# Pilot doesn't need a sidecar.` \
  --set pilot.sidecar=false \
  --set pilot.resources.requests.memory=128Mi \
  `# Disable galley (and things requiring galley).` \
  --set galley.enabled=false \
  --set global.useMCP=false \
  `# Disable security / policy.` \
  --set security.enabled=false \
  --set global.disablePolicyChecks=true \
  `# Disable sidecar injection.` \
  --set sidecarInjectorWebhook.enabled=false \
  --set global.proxy.autoInject=disabled \
  --set global.omitSidecarInjectorConfigMap=true \
  `# Set gateway pods to 1 to sidestep eventual consistency / readiness problems.` \
  --set gateways.istio-ingressgateway.autoscaleMin=1 \
  --set gateways.istio-ingressgateway.autoscaleMax=1 \
  `# Set pilot trace sampling to 100%` \
  --set pilot.traceSampling=100 \
  ./istio-${ISTIO_VERSION}/install/kubernetes/helm/istio \
  --output-dir ./istio-${ISTIO_VERSION}-lean-unhelm

for i in ./istio-${ISTIO_VERSION}/install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done

kubectl label namespace default istio-injection=disabled --overwrite=true
kubectl apply -R -f ./istio-${ISTIO_VERSION}-lean-unhelm/istio

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
