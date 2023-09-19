# Ingress with Contour

This page shows how to use a Kubernetes ingress controller to expose a service. In this case, we are
using Contour (https://projectcontour.io/) as the ingress controller.

## Pre-Requisites

- Kubernetes cluster with a LoadBalancer service available
- Contour installed on the cluster
- Wildcard DNS entry pointing to the public IP address of the Envoy service

In my cluster, I have `*.tap.tanzuathome.net` pointing to 192.168.141.133.

Change the ingress spec.host entry in [Kuard.yaml](Kuard.yaml) to match your DNS record.

## Deploy the App with Kubectl

```shell
kubectl apply -f Kuard.yaml
```

Once the ingress reconciles, you should be able to reach Kuard at the host name you specify. For me it is http://kuard.tap.tanzuathome.net (or
whatever host name you specified)

Delete with the following:

```shell
kubectl delete -f Kuard.yaml
```

## Deploy the App with Kapp

```shell
kapp deploy -a kuard -f Kuard.yaml
```

Once the ingress reconciles, you should be able to reach Kuard at the host name you specify. For me it is http://kuard.tap.tanzuathome.net (or
whatever host name you specified)

Delete with the following:

```shell
kapp delete -a kuard
```
