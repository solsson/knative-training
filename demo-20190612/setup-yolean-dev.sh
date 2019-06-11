#!/bin/bash
set -e

kubectl -n keycloak scale --replicas=0 deploy kc
kubectl -n monitoring scale --replicas=0 deploy prometheus-operator
kubectl -n monitoring scale --replicas=0 deploy prometheus-adapter
kubectl -n monitoring scale --replicas=0 deploy grafana
kubectl -n monitoring scale --replicas=0 deploy kube-state-metrics
kubectl -n monitoring scale --replicas=0 statefulset prometheus-k8s
kubectl -n monitoring scale --replicas=0 statefulset alertmanager-main

kubectl apply -f https://github.com/triggermesh/knative-local-registry/raw/master/templates/registry-service-knative.yaml

(cd ../install && ../install/meetup-20190612.sh)

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
