#!/bin/sh

TEST_NS=test-knative-eventing

kubectl create namespace $TEST_NS
kubectl label namespace $TEST_NS knative-eventing-injection=enabled

cat << EOF | kubectl apply -f -
apiVersion: eventing.knative.dev/v1alpha1
kind: Channel
metadata:
  name: default-channel
  namespace: $TEST_NS
spec: {}
EOF

until kubectl -n $TEST_NS get broker default -o=jsonpath='{.status.address.url}'; do
  kubectl -n $TEST_NS describe broker
done

cat << EOF | kubectl -n $TEST_NS apply -f -
apiVersion: serving.knative.dev/v1beta1
kind: Service
metadata:
  name: message-dumper
  namespace: $TEST_NS
spec:
  template:
    spec:
      containers:
      - image: gcr.io/knative-releases/github.com/knative/eventing-sources/cmd/message_dumper@sha256:ab5391755f11a5821e7263686564b3c3cd5348522f5b31509963afb269ddcd63
EOF

cat << EOF | kubectl -n $TEST_NS apply -f -
apiVersion: eventing.knative.dev/v1alpha1
kind: Trigger
metadata:
  name: test-message-trigger
  namespace: $TEST_NS
spec:
  filter:
    sourceAndType:
      type: dev.knative.foo.bar
  subscriber:
    ref:
      apiVersion: serving.knative.dev/v1alpha1
      kind: Service
      name: message-dumper
EOF

kubectl run install-knative-eventing-contrib-heartbeats --serviceaccount=ko-runner \
  --restart=Never --image=$korunner \
  --env="KO_SOURCE=github.com/knative/eventing-contrib" \
  --env="KO_REVISION=5c0f996a5d8680715725cde534361fb73aaa99f4" \
  --env="KO_DOCKER_REPO=builds.registry.svc.cluster.local/knative-eventing-contrib" \
  --env="KO_APPLY_PATH=samples/heartbeats/heartbeats-sender.yaml"

hearbeats_sender_build=builds.registry.svc.cluster.local/knative-eventing-contrib/heartbeats-5c61cceaf400de2390c78ad3e9da0712

cat << EOF | kubectl -n $TEST_NS apply -f -
apiVersion: sources.eventing.knative.dev/v1alpha1
kind: ContainerSource
metadata:
  name: heartbeats-sender
  namespace: $TEST_NS
spec:
  template:
    spec:
      containers:
        - image: builds.registry.svc.cluster.local/knative-eventing-contrib/heartbeats-5c61cceaf400de2390c78ad3e9da0712
          name: heartbeats-sender
          args:
            - --eventType=dev.knative.foo.bar
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
  sink:
    apiVersion: eventing.knative.dev/v1alpha1
    kind: Broker
    name: default
EOF
