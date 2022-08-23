# vSphere with Tanzu (TKGS) Basics

## Great series of YouTube Videos:

- https://www.youtube.com/watch?v=uSGujnlYpVc - Deep Dive 1: Network Prerequisites and Routing
- https://www.youtube.com/watch?v=Ubsm04VWXKk - Deep Dive 2: Creating a Nested Cluster
- https://www.youtube.com/watch?v=wfYDDbBJHfM - Deep Dive 3: Configuring a vSphere Cluster for Tanzu
- https://www.youtube.com/watch?v=biqSFIu_hmQ - Deep Dive 4: Creating a Namespace and Deploying a K8S Cluster
- https://www.youtube.com/watch?v=rWNYPRxihno - Deep Dive 5: Exploring a Tanzu Kubernetes Cluster

Corresponding GitHub Repo: https://github.com/corrieb/vspherewithtanzudemo/tree/main/sanity

## Setup:

1. Create a namespace "test-namespace"
1. Login with `kubectl vsphere login --server 192.168.139.3 -u administrator@vsphere.local --insecure-skip-tls-verify`
1. `kubectl config use-context test-namespace`

## Interesting Commands:

1. `kubectl config get-contexts` will show two contexts - the IP, and demo-namespace
1. `kubectl config use-context test-namespace`
1. `kubectl describe virtualmachineclasses` - shows virtual machine classes available
1. `kubectl describe ns test-namespace` - shows storage classes available
1. `kubectl describe TkgServiceConfiguration` - show/edit global parameters for TKGS
1. `kubectl get storageclasses` - also shows storage classes
1. `kubectl get TanzuKubernetesReleases` - shows what Kubernetes versions are available
1. `kubectl get VirtualMachineImages` - shows virtual machine images which is similar to Kubernetes versions, but doesn't show upgrade paths
1. `kubectl vsphere logout`

## Create a Cluster:

1. `kubectl apply -f 00-createcluster.yaml` (took about 25 minutes)
1. `kubectl get TanzuKubernetesClusters` watch progress of cluster creation

## Security

You have very little authority in the supervisor cluster - need to get into your own cluster before you can really do
anything. You can see this with `kubectl get clusterroles` - not authorized

Login to the cluster you created:

```
kubectl vsphere logout

kubectl vsphere login --server 192.168.139.3 --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name dev-cluster -u administrator@vsphere.local \
  --insecure-skip-tls-verify
```

Switch into your cluster `kubectl config use-context dev-cluster`

Show roles and role bindings:
- `kubectl get clusterroles`
- `kubectl get clusterrolebindings`

## Deploy a Pod

`kubectl run kuard --restart=Never --image=gcr.io/kuar-demo/kuard-amd64:blue`

`kubectl port-forward kuard 8080:8080`

## Deployments

On vSphere with Tanzu we need to give permission to the default service account for deployments to work.

Run `kubectl apply -f 03a-deployment.yaml`

Run `kubectl describe rs` to show the security error

Run `kubectl apply -f 03b-securitypolicy.yaml` to fix the error

Run `kubectl describe rs` to show things working

## Load Balancer Service

Run `kubectl apply -f 05-loadbalancerservice.yaml` to create the service

Run `kubectl get svc` to see the IP address created from HA Proxy

Navigate to the IP Address

## Deploy Kubeapps

Run `kubectl apply -f 10-securitypolicyKubeapps.yaml` to give permission to Kubeapps to install

```
helm repo add bitnami https://charts.bitnami.com/bitnami
kubectl create namespace kubeapps
helm install kubeapps --namespace kubeapps --set frontend.service.type=LoadBalancer bitnami/kubeapps
```

```
kubectl create --namespace default serviceaccount kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator
```

```
kubectl get secret $(kubectl get serviceaccount kubeapps-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep kubeapps-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' && echo
```

Get IP address from the kubeapps service:

```
kubectl get svc -n kubeapps
```

Go to Kubeapps, sign in with token above: http://192.168.139.133

Install Jenkins from the kubeapps dashboard. Remember to change the storage class to `tanzu-gold-storage-policy`

You can also install MySql. Two things to look out for:
1. Set the storage class to `tanzu-gold-storage-policy`
2. The helm chart will create a service account. Need to give the service account permission to deploy pods (03b-securitypolicy.yml)

```
helm uninstall -n kubeapps kubeapps
```

