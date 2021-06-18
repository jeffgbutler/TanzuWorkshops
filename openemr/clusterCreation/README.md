# Cluster Creation for OpenEMR

In this section will detail requirements for creating a cluster suitible for OpenEMR in Tanzu for vSphere -
also known as Tanzu Kubernetes Grid Service (TKGS). If you are not using TKGS, then you can create
a Kubernetes cluster in whatever manner is normal for your environment.

With these instructions, we will create a cluster with one control plane node and three worker nodes.
You should be able to adapt these instructions to other Kubernetes providers relatively easily.

## Cluster Creation

Using the vSphere UI, create a namespace `openemr-ns`.


Login to the `openemr-ns` namespace with kubectl (replace the IP address and user ID below with the IP address of your vSphere
control plane and your TKGS credentials):

```shell
kubectl vsphere login --server 192.168.139.2 -u administrator@vsphere.local --insecure-skip-tls-verify

kubectl config use-context openemr-ns
```

Create a cluster:

```shell
kubectl apply -f 01-UnifiedCluster.yml
```

Wait for the cluster to be created (about 20 minutes). Check progress with the following command:

```shell
kubectl get TanzuKubernetesClusters
```

Logout of the management cluster and login to your new cluster (replace the IP address and user ID below with the IP address of
your vSphere control plane and your TKGS credentials):

```shell
kubectl vsphere logout

kubectl vsphere login --server 192.168.139.2 --tanzu-kubernetes-cluster-namespace openemr-ns \
  --tanzu-kubernetes-cluster-name openemr-unified-cluster -u administrator@vsphere.local \
  --insecure-skip-tls-verify

kubectl config use-context openemr-unified-cluster
```
