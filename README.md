
# Knativde Training Resources

This guide is brief on howto stuff.
It refers to official docs instead.
The choice of test case detauls - images, commands etc -
differs from these official docs to try to offer insights by slight variation.

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

With this alias and nothing deployed we expect a 404 using any hostname, `kcurl -vf nonexistent.example.com`,
assuming our cluser uses the [default hostname](https://github.com/knative/docs/blob/master/serving/using-a-custom-domain.md).

## The basic Serving example

https://github.com/knative/docs/blob/master/install/getting-started-knative-app.md#configuring-your-deployment

```
kubectl apply -f service-from-image/echo.yaml
# wait and all that
kcurl -vf echo.default.example.com
```

## New revisions using pre-built images

Let's assume you have CI that builds docker images,
and want to use the Knative revision feature for [Blue-Green Deployment](https://martinfowler.com/bliki/BlueGreenDeployment.html).
Imagine you did some coding, and waited for Jenkins :), inbetween these steps:

```
kubectl apply -f service-from-image/revisions-1.yaml
until kcurl revisions.default.example.com | grep Build1; do sleep 1; done;
kubectl apply -f service-from-image/revisions-2.yaml
until kcurl revisions.default.example.com | grep Build2; do sleep 1; done;
kubectl apply -f service-from-image/revisions-3.yaml
until kcurl revisions.default.example.com | grep Build3; do sleep 1; done;
```

## Are you having fun?

We all love terminals, but [...](https://duckduckgo.com/?q=netflix+microservices&t=h_&iax=images&ia=images).

Let's dive into Knative's choice of visualizations sooner rather than later:
 * [Grafana](https://github.com/knative/docs/blob/master/serving/accessing-metrics.md) for Requests Per Second, resource utilization etc.
 * [Prometheus](https://github.com/knative/docs/blob/master/serving/samples/telemetry-go/README.md#accessing-custom-metrics) if you want to go under the hood of the Grafana dashboards.
 * [Zipkin](https://github.com/knative/docs/blob/master/serving/accessing-traces.md) ...
 * or maybe Istio's [Jaeger](https://istio.io/docs/tasks/telemetry/distributed-tracing/#generating-traces-using-the-bookinfo-sample)

If you have a graph, let's apply a `Route` that is independent of our example `Configuration` and look under the hood of Grafana using a [Prometheus](https://github.com/knative/docs/blob/master/serving/samples/telemetry-go/README.md#accessing-custom-metrics) Requests Per Second query like [`rate(istio_revision_request_count{destination_namespace="default",destination_configuration="revisions"}[1m])`](http://localhost:9090/graph?g0.range_input=1h&g0.expr=round(rate(istio_revision_request_count%7Bdestination_namespace%3D%22default%22%2Cdestination_configuration%3D%22revisions%22%7D%5B1m%5D)%2C0.0001)&g0.tab=0):

```
kubectl apply -f service-from-image/revisions-blue-green-route.yaml
while true; do sleep .1 && time kcurl revisions-blue-green.default.example.com; done
```
