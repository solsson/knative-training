
# Knativde Training Resources



## Local Git

To use Gogs locally run `kubectl -n git port-forward gogs-0 3000`.
Log in as user knative passwod knative at http://localhost:3000/,
or run things like `git clone http://knative:knative@localhost:3000/myOrg/myRepo`.

## Set up knative serving

See the [docs](https://github.com/knative/docs/blob/master/install/README.md).
Unless otherwise stated, we try to keep this guide up-to-date with the most recent releases.

## Act as client

Throughout this guide we'll use the alias `kcurl` to refer to HTTP connections to the
[knative ingressgateway](https://github.com/knative/docs/blob/a25fc162cbeed098cd4150203b86a12c65534d7e/install/getting-started-knative-app.md#interacting-with-your-app).
The details depend on how you host your test cluster.

```
# minikube
alias kcurl="curl --connect-to :80:$(minikube ip):32380"
```

With this alias and nothing deployed we expect a 404 using any hostname, `kcurl -vf nonexistent.example.com`.

## The basic Serving example

https://github.com/knative/docs/blob/master/install/getting-started-knative-app.md#configuring-your-deployment

```
kubectl apply -f service-from-image/echo.yaml
# wait and all that
kcurl -vf echo.default.example.com
```
