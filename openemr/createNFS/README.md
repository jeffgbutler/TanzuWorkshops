# Create NFS Server and Storage ReadWriteMany Class

This section shows how to create an NFS server on the vSAN installed on vSphere and configure a provisioner for persistent
volume claims with `ReadWriteMany` access mode on vSphere.

Prerequisites:

1. Helm installed
1. You must have access to the vSphere console
1. You must have the ability to create DNS records
1. You must have access to the Kubernetes cluster (see [cluster creation](../clusterCreation) for instructions on creating
   a Kubernetes Cluster in vSphere)

OpenEMR is not a fully cloud native application - it requires several persistent volume mounts. This causes issues when trying
to scale instances on a multi-node cluster. The persistent volume claims in the Minikube example deployment use an access mode
of `ReadWriteOnce` - which means that the volume can only be mounted to a single node. This works well in Minikube,
but fails in a scaled and multi-node environment. So we need to setup vSphere to allow access mode `ReadWriteMany`.
This is also the reason that OpenEMR cannot be deployed with Cloud Native Runtimes (Knative) - Knative does not support
applications with persistent volume claims.

**Important Note:** As of vSphere 7.0U2, Tanzu on vSphere does not support `ReadWriteMany` natively. This capability is
scheduled to come in vSphere 7.0U3. So we will use helm to install an open source tool that is a part of upstream
Kubernetes to enable `ReadWriteMany` access mode through the use of a pre-provisioned NFS server.

This BLOG is extremely helpful in enabling ReadWriteMany for vSphere with an open source tool that will enable
`ReadWriteMany` persistent volume claims based on an existing NFS server:
https://core.vmware.com/blog/using-readwritemany-volumes-tkg-clusters

## Add DNS Records for NFS Servers

Note: this section and the following assume IP addresses and domain names that are available on my homelab. Modify
as necessary for your environment.

Add the following DNS records:

| Name                               | IP Address     |
|------------------------------------|----------------|
| fs1.nfs.tanzubasic.tanzuathome.net | 192.168.138.21 |
| fs2.nfs.tanzubasic.tanzuathome.net | 192.168.138.22 |
| fs3.nfs.tanzubasic.tanzuathome.net | 192.168.138.23 |

## Setup the vSAN File Service

1. Log on to the vCenter where Tanzu Basic is installed (Workload-Cluster in my case)
1. Select the cluster, then navigate to Configure>VSAN>Services
1. Chose "Enable" in the File Service
1. vSAN File Services Parameters:

   | Parameter    | Value                                               |
   |--------------|-----------------------------------------------------|
   | Domain       | nfs.tanzubasic.tanzuathome.net                      |
   | DNS          | 192.168.128.1                                       |
   | DNS Suffixes | nfs.tanzubasic.tanzuathome.net                      |
   | Network      | DVPG-Supervisor-Management-Network                  |
   | Subnet Mask  | 255.255.255.0                                       |
   | Gateway      | 192.168.138.1                                       |
   | IP Addresses | 192.168.138.21 (fs1.nfs.tanzubasic.tanzuathome.net) |
   | IP Addresses | 192.168.138.22 (fs2.nfs.tanzubasic.tanzuathome.net) |
   | IP Addresses | 192.168.138.23 (fs3.nfs.tanzubasic.tanzuathome.net) |

1. Once the vSAN File Services are enabled, create a new file share:
   1. Select the cluster
   1. Navigate to Configure>vSAN>File Shares
   1. Add a new file share called "openemr" and allow access from any IP address

Once the file share is created, look at the details and obtain the NFS 4.1 export path.
In my setup this was `fs1.nfs.tanzubasic.tanzuathome.net:/vsanfs/openemr`. You will need this information when you configure
the cluster for OpenEMR.

## Configure the Open Source Provisioner

The file `01-NfsProvisionerValues.yml` contains configuration values for the NFS external provisioner. Alter this
file with the NFS server and path obtained from the file share you created above.

```shell
kubectl create namespace infra

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

helm repo update

helm install nfs-subdir-external-provisioner --namespace infra nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
 -f 01-NfsProvisionerValues.yml
```

After these commands execute successfully, there will be a storage class `nfs-external` available for use in your cluster.
When you create a persistent volume claim using this storage class, the provisioner will create a subdirectory in the NFS share
