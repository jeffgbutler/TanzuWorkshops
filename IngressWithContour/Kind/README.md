# Ingress with Contour on Kind

This page shows how to use a Kubernetes ingress controller to expose a service. In this case, we are
using Contour (https://projectcontour.io/) as the ingress controller deployed on a local cluster with Kind.

## Pre-Requisites Create and Configure a Kind Cluster

Create the cluster:
```shell
kind create cluster --config KindClusterConfig.yaml
```

Install Contour Ingress Controller
```shell
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```

## Deploy the App with Kapp

Install a test application (you will need to change the ingress spec.host value in [Kuard.yaml](./Kuard.yaml) if you are
using a pre-existing cluster):

```shell
kapp deploy -a kuard -f Kuard.yaml
```

Make sure you can access Kuard at the following URL: http://kuard.kuard-test.127-0-0-1.nip.io/ (use a different URL if you changed
the ingress host)

Once you have verified access to Kuard, uninstall it with this command:

```shell
kapp delete -a kuard
```
