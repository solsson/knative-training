

curl -L https://github.com/knative/docs/raw/release-0.6/docs/serving/samples/autoscale-go/service.yaml | kubectl apply -f -

IP_ADDRESS=$(minikube ip)
curl -H 'Host: autoscale-go--default.example.com' "http://$IP_ADDRESS/?sleep=100&prime=10000&bloat=5"

kubectl apply -f autoscale-loadtest.yaml
