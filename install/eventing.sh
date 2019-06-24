#!/bin/sh

kubectl apply -k github.com/Yolean/unhelm/istio/crds?ref=7ab305e9b55bbdd1b7aa6c9d2915aac9dfe15a25
sleep 10
kubectl apply -k github.com/Yolean/unhelm/istio/namespace?ref=7ab305e9b55bbdd1b7aa6c9d2915aac9dfe15a25
kubectl apply -f https://github.com/Yolean/unhelm/raw/7ab305e9b55bbdd1b7aa6c9d2915aac9dfe15a25/istio/knative-istio-lean.yaml

# Try to solve ko apply error:
kubectl apply -f https://github.com/knative/serving/raw/9faddd878c8bbed628bf8f5d655874eec22733af/config/999-cache.yaml

korunner=solsson/go-ko-runner@sha256:cd41533cc951f7baba33dca2282d248045196f9afd41e2780d5c64f151194788
kubectl create serviceaccount ko-runner --namespace=default
kubectl create clusterrolebinding ko-runner --clusterrole=cluster-admin --serviceaccount=default:ko-runner --namespace=default

kubectl run install-knative-serving --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/serving" \
  --env="KO_REVISION=65b7d9ab6841af06c69c04f93f63db04e071f94f" \
  --env="EXIT_DELAY=3600" \
  --env="KO_DOCKER_REPO=builds.registry.svc.cluster.local/knative-serving"

until kubectl -n knative-serving wait --for=condition=Ready --timeout=1s pod -l app=controller; do
  echo "Waiting for Serving to be ready ..."
  kubectl logs --tail=1 install-knative-serving || echo "Installer not running yet"
  sleep 30
done

# avoid subdomains
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-network
  namespace: knative-serving
data:
  domainTemplate: "{{.Name}}--{{.Namespace}}.{{.Domain}}"
EOF

kubectl run install-knative-eventing --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/eventing" \
  --env="KO_REVISION=108d062deb9d52955d866a75c5955df2d21f4cf0" \
  --env="EXIT_DELAY=3600" \
  --env="KO_DOCKER_REPO=builds.registry.svc.cluster.local/knative-eventing"

until kubectl logs -f install-knative-eventing; do
  sleep 5
done

kubectl run install-knative-eventing-channel-inmemory --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/eventing" \
  --env="KO_REVISION=108d062deb9d52955d866a75c5955df2d21f4cf0" \
  --env="KO_DOCKER_REPO=builds.registry.svc.cluster.local/knative-eventing" \
  --env="KO_APPLY_PATH=config/provisioners/in-memory-channel/in-memory-channel.yaml"

kubectl run install-knative-eventing-channel-kafka --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/eventing" \
  --env="KO_REVISION=108d062deb9d52955d866a75c5955df2d21f4cf0" \
  --env="KO_DOCKER_REPO=builds.registry.svc.cluster.local/knative-eventing" \
  --env="KO_APPLY_PATH=contrib/kafka/config"

# Must be done after apply
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-kafka
  namespace: knative-eventing
data:
  bootstrapServers: bootstrap.kafka:9092
EOF
