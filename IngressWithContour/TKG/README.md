# Ingress with Contour

This page shows how to use a Kubernetes ingress controller to expose a service. In this case, we are
using Contour (https://projectcontour.io/) as the ingress controller.

## Pre-Requisites

- Kubernetes cluster with a LoadBalancer service available
- Contour installed on the cluster
- Wildcard DNS entry pointing to the public IP address of the Envoy service

In my cluster, I have `*.tap.tanzuathome.net` pointing to 192.168.141.133.

Change the host entry in [03_Ingress.yaml](03_Ingress.yaml) to match your DNS record.

## Deploy the App with Kubectl

1. `kubectl apply -f 01_Deployment.yaml`
2. `kubectl apply -f 02_Service.yaml`
3. `kubectl apply -f 03_Ingress.yaml`

Once the ingress reconciles, you should be able to reach nginx at the host name you specify. For me it is http://nginx.tap.tanzuathome.net.

Delete with the following:

1. `kubectl delete -f 03_Ingress.yaml`
2. `kubectl delete -f 02_Service.yaml`
3. `kubectl delete -f 01_Deployment.yaml`

## Deploy the App with Kapp

1. `kapp deploy -a nginx -f .`

Once the ingress reconciles, you should be able to reach nginx at the host name you specify. For me it is http://nginx.tap.tanzuathome.net.

Delete with the following:

1. `kapp delete -a nginx`
