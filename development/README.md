# Run `ko` and friends in-cluster

```
kubectl create serviceaccount devpod --namespace=default
kubectl create clusterrolebinding devpod --clusterrole=cluster-admin --serviceaccount=default:devpod --namespace=default
kubectl apply -f devpod.yaml
```

Now exec into your container of chioce, such as:

`kubectl exec devpod -c ko -ti -- bash`


## `docker`

`kubectl exec devpod -c docker -- docker pull` is useful for checking your build results.

