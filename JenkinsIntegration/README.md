# Jenkins Integration with TKGS

How to integrate Jenkins with a TKGS cluster.

Assumes you have an instance of Jenkins installed and have the Kubernetes plugin installed as well. One simple
way to install Jenkins on a Kubernetes cluster is with Kubeapps (https://kubeapps.com/).

## Create and Prepare a Kubernetes Cluster

```shell
kubectl vsphere login --server 192.168.139.3 -u administrator@vsphere.local --insecure-skip-tls-verify

kubectl config use-context test-namespace

kubectl apply -f 01-CreateCluster.yml
```

Wait for the cluster to be created. This is just one way to create a TKGS cluster - you can also
create the cluster with Tanzu Mission Control.

Log in to your new cluster:

```shell
kubectl vsphere logout

kubectl vsphere login --server 192.168.139.3 --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name prod-cluster -u administrator@vsphere.local \
  --insecure-skip-tls-verify
```

Retrieve the control plane URL for the new cluster - sae this for later use:

```shell
kubectl cluster-info
```

The control plane URL is https://192.168.139.9:6443 in my cluster.

Create a service account for Jenkins:

```shell
kubectl create -n default serviceaccount jenkins-operator
```

Assign the cluster admin role to the new service account:

```shell
kubectl create clusterrolebinding jenkins-operator --clusterrole=cluster-admin --serviceaccount=default:jenkins-operator
```

Retrieve the token for the new service account:

```shell
kubectl get secret $(kubectl get serviceaccount jenkins-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' \
  | grep jenkins-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' && echo

```

It will be a very long string. Save the value somewhere convenient. In my case it was:

```
eyJhbGciOiJSUzI1NiIsImtpZCI6Ind6UjVwRWUxNTVJSFZvZHE3RF95aHZzdHJBNUxja0d1UW14TFRQMnVzclEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImplbmtpbnMtb3BlcmF0b3ItdG9rZW4teHNwZGYiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiamVua2lucy1vcGVyYXRvciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImQ0YmQ0M2IxLTA4YTctNDY2OS04NjZlLTgzZjEyNzFiNTVkMCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmplbmtpbnMtb3BlcmF0b3IifQ.iIlPlNH2_pO1TjNKAQSHHNZ6_dM67flU9AJA5jrB5zfCbQ1EBpnKvTp73IK9ib7r6PP9YeFmpZ8DolTJqXx4_feBdVhgVCXGR4abHUD95ivSBQtBKVwRy2EmEnfeI8Y6vKyMAab_h_9tqWbj-MADrBOJWcZONdeRtWyQ9QnX7_4QTsaC_AFYT0KupiMHDOxgbeV0i91SCS7i7BrpHE6foLu3ieIzStHWI8RdQrX_TE2PjqsgpX8G_xny5JsWa_4nU2Gty-03e7QgPV9ea1EqzuE4fnlfzD9QqZpANSli7ajd9kZQAR9mxLwH8LUSOH2GrjLtu4oi0OTsZlPEieppMQ
```

## Update Pod Security Policies (TKGS Only)

TKGS clusters have very strict pod security policies in place that will limit deployments to the cluster. Documentation
regarding pod security policies in TKGS is here: https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-CD033D1D-BAD2-41C4-A46F-647A560BAEAB.html

You can allow deployments into any namespace with the following command (this may not be appropriate for production clusters):

```shell
kubectl create clusterrolebinding default-tkg-admin-privileged-binding \
  --clusterrole=psp:vmware-system-privileged \
  --group=system:authenticated
```

This will allow any authenticated user privileged access to the cluster.

## Setup Jenkins

Login to Jenkins... http://192.168.139.7    user/43YBXOmUpB

### Create a Credential for the Service Account

1. Manage Jenkins
1. Manage Credentials
1. Select the "Jenkins" store
1. Select "Global Credentials (unrestricted)"
1. Add Credentials
1. Enter the values:

   | Item   | Value                                         |
   |--------|-----------------------------------------------|
   | Kind   | Secret Text                                   |
   | Scope  | Global                                        |
   | Secret | The service account token you retrieved above |
   | ID     | prod-cluster-token                            |


### Configure the Kubernetes Cloud Provider

1. Manage Jenkins
1. Manage Nodes and Clouds
1. Configure Clouds
1. Add a new cloud (Kubernetes)
1. Enter a name to denote this cluster (I used "prod-cluster")
1. Press "Kubernetes Cloud Details..."
1. Enter the values:

   | Item | Value                                                                                       |
   |---------------------------|------------------------------------------------------------------------|
   | Name                      | prod-cluster                                                           |
   | Kubernetes URL            | The control plane URL you retrieved above (https://192.168.139.9:6443) |
   | Disable certificate check | Checked                                                                |
   | Credentials               | prod-cluster-token                                                     |

1. Test the connection - should succeed
1. Save
