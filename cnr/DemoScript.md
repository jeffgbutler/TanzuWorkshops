# CNR vs. Raw Kubernetes Demo

Install Redis:

```shell
kubectl run redis --image=redis:6.2.6

kubectl expose pod redis --type=ClusterIP --port=6379 --target-port=6379 
```

## Raw Kubernetes
```shell
kubectl apply -f 02-PaymentCalculatorRawKubernetes.yaml
```

This deploys the payment calculator and exposes it with a K8S service.

Available at http://192.168.139.9

Shortcomings:

1. Requires knowledge of Kubernetes Primitives
1. Does not have a DNS entry
1. Does Not have a certificate or support TLS

#2 and #3 can be overcome throught the use of an ingress controller - which is another thing to install
and configure.

```shell
kubectl delete -f 02-PaymentCalculatorRawKubernetes.yaml
```

## Cloud Native Runtimes


```shell
kn service create payment-calculator \
   --image jeffgbutler/payment-calculator --port 8080 \
   --env spring.redis.host=redis \
   --env spring.redis.port=6379 \
   --env spring.profiles.active=redis
```

This does the following:

1. K8S Deployment
1. K8S Service
1. Configures Ingress
1. Sets up an autoscaler (scale to zero by default)

Knative is configured to force HTTPS traffic so it will redirect all HTTP requests appropriately.

A wildcard certificate is installed in Knative, and there is a wildcard DNS entry (just like TAS)

Knative can also be configure to automatically generate certificates for services if you have an ACME server
available internally, or it can use LetsEncrypt!

Hit the app at https://payment-calculator.cnr.tanzuathome.net

You can also use the traffic simulator here: https://jeffgbutler.github.io/payment-calculator-client/
- Enter https://payment-calculator.cnr.tanzuathome.net

```shell
kn delete service payment-calculator
```

## Knative YAML

The `kn` CLI command is convenient (similar to cf push). But sometimes we want more control over
the service than what's available with the command. Because this is Kubernetes, everything eventually gets translated
to YAML anyway, so we can use YAML to configure the service.

We'll use YAML to change the following defaults in Knative:

1. We will set the minimum scale to 1 rather than 0
1. We will set the auto scale metric to 10 concurrent requests rather than the default of 100

```shell
kubectl apply -f 03-PaymentCalculatorCnr.yaml
```

Now we can use Apache Bench to load the request with traffic and see the autoscale in action:

```shell
ab -t 120 -c 100 "https://payment-calculator.cnr.tanzuathome.net/payment?amount=100000&rate=3.5&years=10"
```
