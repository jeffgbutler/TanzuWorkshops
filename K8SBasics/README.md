# Kubernetes Basics Workshop

This short workshop demonstrates some basics of Kubernetes. We assume that you have access to a Kubernetes cluster somewhere -
this could be in the public cloud, some on premise infrastructure, or even on your workstation. All exercises should
work in any Kubernetes environment.

## Install the Kubernetes CLI

All interactions with Kubernetes in this workshop will use the Kubernetes CLI "kubectl". You can
install it on your workstation by following instructions here: https://kubernetes.io/docs/tasks/tools/

## Gain Access to a Kubernetes Cluster

In TKGS without NSX-T, this would be a Tanzu Kubernetes Cluster also sometimes called a "workload" cluster. TKGS also has the
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

```shell
kubectl create namespace my-namespace
```

## Deploy a Pod

```shell
kubectl run nginx --image=nginx -n my-namespace
```

This deploys a single pod containing the nginx image.

1. Where does the image come from?
1. What version of the image is deployed?
1. Can you actually access nginx?
1. What happens if the pod crashes?

## Expose a Pod with Cluster IP

```shell
kubectl expose pod nginx --type=ClusterIP --port=80 -n my-namespace
```

This gives the pod a reliable IP on the cluster's internal services network. You can find the IP address
with the following:

```shell
kubectl get all -n my-namespace
```

I got `10.1.7.21` in my cluster.

1. Is it available outside the cluster?
1. How can you test this?

## Debugging

```shell
kubectl run -it curl --image=curlimages/curl -n my-namespace -- sh
```

This will deploy a container named `curl` using the `curlimages/curl` image. It will open a shell session
in that container and attach your workstation to it. This is a very useful debugging technique!

In this session you can try a couple of things:

```shell
curl nginx
```

1. Which nginx service will it query?

```shell
curl nginx.my-namespace.svc.cluster.local
```

1. Can you curl an nginx service in someone else's namespace?

```shell
curl 10.1.7.21
```

You can close your terminla session with `exit`. If you want to reattach to the `curl` pod, either of the
following commands will work:

If you want to reatt
```shell
kubectl attach curl -it -n my-namespace
```

```shell
kubectl exec -it curl -n my-namespace -- sh
```

## Cleanup

```shell
kubectl delete service nginx -n my-namespace
```

```shell
kubectl delete pod nginx -n my-namespace
```

## Deployments

Deploying a single pod is useful for basic learning, but we want something more in production. If we deploy an application 
as a single pod and it dies, it could cause a service interruption. So we need something a bit more robust than a pod. In Kubernetes,
that next level abstraction is called a `deployment`. A deployment contains three types of Kubernetes objects:

1. Pod(s) - where the application runs
1. ReplicaSet - an object that manages replicas and restarts pods if one fails
1. Deployment - an object that manages everything

Take a look at [01-NginxDeployment.yaml](01-NginxDeployment.yaml)

```shell
kubectl apply -f 01-NginxDeployment.yaml
```

If you are on TKGS, this will probably fail. Why?

Debug...

Find the name of the replicaset:

```shell
kubectl get all -n my-namespace
```

It will be something like `nginx-7848d4b86f`

```shell
kubectl describe replicaset nginx-7848d4b86f -n my-namespace
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

```shell
kubectl apply -f 02-NodePortService.yaml
```

Find the port:

```shell
kubectl get all -n my-namespace
```

It will be in the range 32xxx.

Find the node IP addresses:

```shell
kubectl get nodes -o wide
```

Access the service at `node_IP_address:port`

## Expose a Deployment with LoadBalancer

NodePort is supported in all Kubernetes clusters. It usually requires somekind of external gateway to be useful in real life.
Some Kubernetes clusters support a service type of LoadBalancer which can be more useful.

```shell
kubectl apply -f 03-LoadBalancerService.yaml
```

Find the external IP address:

```shell
kubectl get all -n my-namespace
```

