#!/bin/sh
#set -e

kubectl cluster-info
read -p "Press enter to continue"

kubectl label namespace default istio-injection=enabled

kubectl create -f knative-releases/serving/previous/v0.2.2/istio-crds.yaml
kubectl create -f knative-releases/serving/previous/v0.2.2/istio.yaml
read -p "Press enter to continue"

kubectl create -f knative-releases/serving/previous/v0.2.2/serving.yaml
read -p "Press enter to continue"

kubectl apply -f knative-releases/serving/previous/v0.2.2/monitoring-metrics-prometheus.yaml
kubectl apply -f knative-releases/serving/previous/v0.2.2/monitoring-tracing-zipkin-in-mem.yaml
read -p "Press enter to continue"

kubectl apply -f $GOPATH/src/github.com/knative/build-pipeline/third_party/config/build/release.yaml
