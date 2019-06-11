#!/bin/bash
set -e

cat <<EOF
k-keycloak scale --replicas=0 deploy kc
k-monitoring scale --replicas=0 deploy prometheus-operator
k-monitoring scale --replicas=0 deploy prometheus-adapter
k-monitoring scale --replicas=0 deploy grafana
k-monitoring scale --replicas=0 deploy kube-state-metrics
k-monitoring scale --replicas=0 statefulset prometheus-k8s
k-monitoring scale --replicas=0 statefulset alertmanager-main
EOF
kubectl apply -f https://github.com/triggermesh/knative-local-registry/raw/master/templates/registry-service-knative.yaml

../install/meetup-20190612.sh

# We already have node-exporter, and node metrics isn't relevant for Knative demos
kubectl -n knative-monitoring delete daemonset node-exporter

#kubectl -n knative-monitoring set image deploy/grafana grafana=grafana/grafana:6.2.2@sha256:1f1260f5a97e18547d6aa703602400d2f46162edda4dcf0f96156a693c3e9f4c

# https://github.com/jaegertracing/jaeger-operator#installing-the-operator
#kubectl create namespace observability # (1)
#kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/crds/jaegertracing_v1_jaeger_crd.yaml # (2)
#kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/service_account.yaml
#kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role.yaml
#kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/role_binding.yaml
#kubectl create -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/master/deploy/operator.yaml
#kubectl apply  -f https://github.com/knative/serving/releases/download/$RELEASE/monitoring-tracing-jaeger-in-mem.yaml
#kubectl apply  -f https://github.com/knative/serving/releases/download/$RELEASE/monitoring-tracing-zipkin-in-mem.yaml

### https://knative.dev/docs/serving/samples/autoscale-go/index.html

kubectl apply -f config-network.yaml
kubectl apply -f knative-demo-ingress.yaml

curl -L https://github.com/knative/docs/raw/release-0.6/docs/serving/samples/autoscale-go/service.yaml | kubectl apply -f -
IP_ADDRESS=$(minikube ip)
curl -H 'Host: autoscale-go--default.example.com' "http://$IP_ADDRESS/?sleep=100&prime=10000&bloat=5"

# https://github.com/knative/docs/tree/master/docs/eventing/samples/cronjob-source

cat <<EOF | kubectl apply -f -
apiVersion: serving.knative.dev/v1alpha1
kind: Service
metadata:
  name: event-display
spec:
  template:
    spec:
      containers:
        - image: gcr.io/knative-releases/github.com/knative/eventing-sources/cmd/event_display
EOF

cat <<EOF | kubectl apply -f -
apiVersion: sources.eventing.knative.dev/v1alpha1
kind: CronJobSource
metadata:
  name: test-cronjob-source
spec:
  schedule: "*/2 * * * *"
  data: '{"message": "Hello world!"}'
  sink:
    apiVersion: serving.knative.dev/v1alpha1
    kind: Service
    name: event-display
EOF
