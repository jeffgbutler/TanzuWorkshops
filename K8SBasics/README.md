# Kubernetes Basics Workshop

This short workshop demonstrates some basics of Kubernetes. We assume that you have access to a Kubernetes cluster somewhere -
this could be in the public cloud, some on premise infrastructure, or even on your workstation. All exercises should
work in any Kubernetes environment.

## Install the Kubernetes CLI

All interactions with Kubernetes in this workshop will use the Kubernetes CLI "kubectl". You can
install it on your workstation by following instructions here: https://kubernetes.io/docs/tasks/tools/

## Gain Access to a Kubernetes Cluster

In vSPhere with Tanzu (TKGS), this would be a Tanzu Kubernetes Cluster also sometimes called a "workload" cluster. TKGS also has the
concept of a "supervisor" cluster, but we can safely ignore the supervisor cluster for this workshop.

For TKGS, you will also need to install the vSphere plugin for Kubectl. This can be obtained from a web page exposed
by the supervisor cluster. The vSphere plugin will be named `kubectl-vsphere` for Linux/MacOS and `kubectl-vsphere.exe` for
windows. This file must be placed in the executable path on your operating system, preferably in the same directory as `kubectl`.

Once you have setup `kubectl` and the vSphere plugin, you can login to a Kubernetes cluster with a command
like the following:

```shell
kubectl vsphere login \
  --server 192.168.139.3 \
  --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name dev-cluster \
  --vsphere-username administrator@vsphere.local \
  --insecure-skip-tls-verify
```

In this case, you are logging in to TKGS at IP address `192.168.139.3`. You are using supervisor namespace `test-namespace` and workload
cluster `dev-cluster`. You should change these values to match the values given to you by your administrator.

Once logged in, your Kubectl context should be set to `dev-cluster`. You can verify this with the following command:

```shell
kubectl config get-contexts
```

The cluster `dev-cluster` should be marked as current. If it is not, then you can set it with the following command:

```shell
kubectl config use-context dev-cluster
```

You can make sure you are connected to the cluster with the following command:

```shell
kubectl get all
```

## Create a Namespace

Namespaces in a Kubernetes cluster are a logical partition of the cluster. By default, there is very little enforced separation
between items in different namespaces. So initially we will think of namespaces as a means of avoiding naming collisions
if there are multiple users in our cluster.

If you don't create a namespace and use it in the following Kubernetes commands, then items will be created in a namespace called "default"
that exists in every Kubernetes cluster.

**Important:** please make a unique namespace for your use in this workshop! We suggest you use a name based on your
initials like `jgb-namespace`. For the remainder of the workshop, replace `jgb-namespace` with the namespace you created.

```shell
kubectl create namespace jgb-namespace
```

## Deploy a Pod

```shell
kubectl run nginx --image=nginx -n jgb-namespace
```

This deploys a single pod containing the nginx image.

1. How can you check the status?    (kubectl get all -n jgb-namespace)
1. Where does the image come from?  (Docker Hub)
1. What version of the image is deployed?  (Latest)
1. Can you actually access nginx?    (No)
1. What happens if the pod crashes?   (Kubernetes will create a new pod)

## Expose a Pod with Cluster IP

```shell
kubectl expose pod nginx --type=ClusterIP --port=80 -n jgb-namespace
```

This gives the pod a reliable IP on the cluster's internal services network. You can find the IP address
with the following:

```shell
kubectl get all -n jgb-namespace
```

I got `10.1.6.211` in my cluster.

1. Is it available outside the cluster?  (No)

## Basic Kubectl Commands

All operations in a Kubernetes cluster are accessed through Kubectl. Kubectl can connect to many different Kubernetes clusters,
but only one will be active at a time. You can see which clusters are available to you with the command:

```shell
kubectl config get-contexts
```

If you want to change to a different cluster, use a command like the following:

```shell
kubectl config use-context docker-desktop
```

Kubernetes clusters have a number of standard resources, and usually have other vendor specific resources. You can see what resources
are in your cluster with the command:


```shell
kubectl api-resources
```

This command will also show the short name for a resource if it has one, as well as whether the resource can be placed in a namespace.
For example, all of the following commands are equivalant:

```shell
kubectl get pods
kubectl get pod
kubectl get po
```

Kubectl "get" commands display information about one or more resources.

```shell
kubectl get all  # show basic information about resources in the default namespace
kubectl -n jgb-namespace get all  # show basic information about resources in jgb-namespace

kubectl get pods   # show basic information about all pods in the default namespace
kubectl -n jgb-namespace get pods   # show basic information about all pods in jgb-namespace
kubectl get pods -A     # show basic information about all pods in all namespaces
kubectl -n jgb-namespace get pods -o wide  # show a bit more detail about pods in my-namespace
kubectl -n jgb-namespace get pod nginx # show basic information about a specific pod
kubectl -n jgb-namespace get pod nginx -o yaml # show the YAML configuration for a specific pod

kubectl get nodes # show information about the nodes in a cluster
kubectl get nodes -o wide # show more detailed information about the nodes in a cluster (will show the node IP addresses)
```

Kubectl "describe" commands show detailed configuration and events for a resource

```shell
kubectl -n jgb-namespace describe pod nginx
```

You can access the logs in a pod with commands like the following:

```kubectl
kubectl -n jgb-namespace logs nginx  # snapshot of the logs
kubectl -n jgb-namespace logs nginx -f # start streaming the logs
kubectl -n jgb-namespace logs nginx --tail=10 # show the last 10 lines in the logs
```

## Debugging

A ClusterIP service is not available outside of the cluster. To access it, you need to get access
to an environment inside the cluster. One easy way to do this is to deploy a pod and open a command
shell in the pod:

```shell
kubectl run -it curl --image=curlimages/curl -n jgb-namespace -- sh
```

This will deploy a container named `curl` using the `curlimages/curl` image. It will open a shell session
in that container and attach your workstation to it. This is a very useful debugging technique!

In this session you can try a couple of things:

```shell
curl nginx
```

1. Which nginx service will it query?  (the one in your namespace)

```shell
curl nginx.jgb-namespace.svc.cluster.local
```

1. Can you curl an nginx service in someone else's namespace?

```shell
curl 10.1.6.211
```

You can close your terminla session with `exit`. If you want to reattach to the `curl` pod, either of the
following commands will work:

If you want to reatt
```shell
kubectl -n jgb-namespace attach curl -it
```

```shell
kubectl -n jgb-namespace exec -it curl -- sh
```

## Cleanup

```shell
kubectl -n jgb-namespace delete service nginx
```

```shell
kubectl -n jgb-namespace delete pod nginx
```

## Deployments

Deploying a single pod is useful for basic learning, but we want something more in production. If we deploy an application 
as a single pod and it dies, it could cause a service interruption. So we need something a bit more robust than a pod. In Kubernetes,
that next level abstraction is called a `deployment`. A deployment contains three types of Kubernetes objects:

1. Pod(s) - where the application runs
1. ReplicaSet - an object that manages replicas and restarts pods if one fails
1. Deployment - an object that manages everything

Take a look at [01-NginxDeployment.yaml](01-NginxDeployment.yaml)

Change the namespace in this file to match the namespace you created, then execute it:

```shell
kubectl apply -f 01-NginxDeployment.yaml
```

Watch the progress of the deployment with the following:

```shell
kubectl -n jgb-namespace get all
```

## TKGS Security Issues (Optional)
If you are on TKGS, this might fail. Why?

Debugging... Find the name of the replicaset:

```shell
kubectl -n jgb-namespace get all
```

It will be something like `nginx-7848d4b86f`

```shell
kubectl -n jgb-namespace describe replicaset nginx-7848d4b86f
```

If you are on TKGS, you will likely see an error message about pods not being admitted to to pod
security policies. You can remedy this with the following:

```shell
kubectl apply -f 00-RoleBinding.yaml
```

## Expose a Deployment with Nodeport

ClusterIP services are useful when you have services that should only be available to other pods in a cluster. This is great for
things like databases and caches that should only be available to other services like web apps. If we want to expose and application
outside of the cluster, we need a different type of service.

Take a look at [02-NodePortService.yaml](02-NodePortService.yaml)

Change the namespace in this file to match the namespace you created, then execute it:

```shell
kubectl apply -f 02-NodePortService.yaml
```

Find the port:

```shell
kubectl -n jgb-namespace get service nginx-nodeport
```

It will be in the range 30000-32767.

Find the node IP addresses:

```shell
kubectl get nodes -o wide
```

Access the service at `http://node_IP_address:node_port` In my case is like this:

```shell
curl http://192.168.139.131:31549
```

## Expose a Deployment with LoadBalancer

NodePort is supported in all Kubernetes clusters. It usually requires somekind of external gateway to be useful in real life.
Some Kubernetes clusters support a service type of LoadBalancer which can be more useful.

Take a look at [03-LoadBalancerService.yaml](03-LoadBalancerService.yaml)

Change the namespace in this file to match the namespace you created, then execute it:

```shell
kubectl apply -f 03-LoadBalancerService.yaml
```

Find the external IP address:

```shell
kubectl -n jgb-namespace get service nginx-loadbalancer
```

Access the service at the external IP address shown. In my case is like this:

```shell
curl http://192.168.139.9
```

# Deploy a Microservice

For the next exercise, we are going to deploy a microservice that calculates loan payments. This service will also need 
access to an instance is Redis. Source code for the application is here: https://github.com/jeffgbutler/java-payment-calculator

The application image is on Docker Hub as the address jeffgbutler/payment-calculator

## Deploy Redis

We will deploy a very simple instance of Redis - only one pod with no replica set and no authentication. This is useful for testing, but
not for production!

```shell
kubectl -n jgb-namespace run redis --image=redis:6.2.6
```

```shell
kubectl -n jgb-namespace expose pod redis --type=ClusterIP --port=6379 --target-port=6379 
```

## Deploy the Payment Calculator Service

Take a look at [04-PaymentCalculatorDeployment.yaml](04-PaymentCalculatorDeployment.yaml)

Change the namespace in this file to match the namespace you created, then execute it:

```shell
kubectl apply -f 04-PaymentCalculatorDeployment.yaml
```

Take a look at [05-PaymentCalculatorService.yaml](05-PaymentCalculatorService.yaml)

Change the namespace in this file to match the namespace you created, then execute it:

```shell
kubectl apply -f 05-PaymentCalculatorService.yaml
```

Once the external IP is provisioned, you can access the service in a browser: http://192.168.139.9 in my case.

The default page should show the Swagger UI. You can use the UI to exercise the web service.
