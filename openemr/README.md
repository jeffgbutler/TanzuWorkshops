# Installing OpenEMR in vSphere with Tanzu

Description of installing OpenEMR in vSphere native Kubernetes Clusters.

This work is based on the OpenEMR minikube deployment described here:
https://github.com/openemr/openemr-devops/tree/master/kubernetes/minikube. Deploying OpenEMR to a single node
minikube based cluster is relatively easy. Things get a bit more complex when deploying OpenEMR to a multi-node
cluster or to multiple clusters. Describing and overcoming those issues is one of the goals of this project.

Prerequisite: vSphere 7 with workload management enabled. I'm using a setup based on William Lam's
nested vSphere environment. Details here: https://github.com/lamw/vsphere-with-tanzu-nsx-advanced-lb-automated-lab-deployment

Architectural Goals:

1. MySql and Redis installed via TAC (Kubeapps)
1. phpMyAdmin installed via Tanzu Cloud Native Runtimes (Knative)
1. OpenEMR installed as a native Kubernetes application that can be scaled

Initially, we will start with everything in a single cluster. Later we will use two clusters - "data" and "compute" 

## Cluster Creation

Using the vSphere UI, create a namespace "openemr-ns". Login to the namespace with kubectl:

```bash
kubectl vsphere login --server 192.168.139.128 -u administrator@vsphere.local --insecure-skip-tls-verify

kubectl config use-context openemr-ns
```

Create a cluster:

```bash
kubectl apply -f 00-unifiedcluster.yml
```

Wait for the cluster to be created (about 20 minutes). Check progress with the following command:

```bash
kubectl get TanzuKubernetesClusters
```

Logout of the management cluster and login to your new cluster:

```bash
kubectl vsphere logout

kubectl vsphere login --server 192.168.139.152 --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name tkgs-cluster-1 -u administrator@vsphere.local \
  --insecure-skip-tls-verify

kubectl config use-context tkgs-cluster-1
```

## Install Kubeapps

We will use Kubeapps to install MySQL, Redis, and phpMyAdmin.

Kubeapps is installed via a Helm chart. If you do not have helm installed, install it

```bash
brew install helm
```

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl create namespace kubeapps
```

Users - even admin users - have very little authority in TKGS clusters initially. We'll need to create role bindings
for Kubeapps before we try to install it. So run the role binding script:

```bash
kubectl apply -f 01-KubeappsRoleBindings.yml
```

Now install Kubeapps. This command will install Kubeapps in the `kubeapps` namespace and will provision a load balancer for
the UI. Once you run this command, it will take a few minutes to install. You can monitor the progress by watching
pod creation status in the `kubeapps` namespace.

```bash
helm install kubeapps --namespace kubeapps --set frontend.service.type=LoadBalancer bitnami/kubeapps
```

Create a simple service acount for interacting with Kubeapps (note this is not recommended for production clusters).

```
kubectl create --namespace default serviceaccount kubeapps-operator

kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator
```

Now obtain the secret for logging in to Kubeapps:

```
kubectl get secret $(kubectl get serviceaccount kubeapps-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' \
  | grep kubeapps-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' && echo
```

Save the token somewhere convenient for logging in to Kubeapps. The token will look something like the following.

```
eyJhbGciOiJSUzI1NiIsImtpZCI6IlhjZmxzUm1oSFAyUl90R2RPSFhhOW1sY0M2T2lYNGZDVmpVS1ctSWdvWWcifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Imt1YmVhcHBzLW9wZXJhdG9yLXRva2VuLTlncDg3Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6Imt1YmVhcHBzLW9wZXJhdG9yIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiMTYxMWE0MGQtNmU5MC00NTNmLThiMGQtNTllODhiMWJmMDJlIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6a3ViZWFwcHMtb3BlcmF0b3IifQ.E8n1El-qrDA2AnuLroK_66fvfziVJCTB2X5ScBU3CFYG_9NMhrIYijePvP5-CXpa3wjWYnmH0gNRW-RlFEVLzOP29NJP40s8lcdxkkhAHis_Zm1uXYpye74Ti2IN_HfAkhTSaufWULdTlA1EMbu3mK-WWwh1Uidj9u3_V5sZ-PeLAbv5fVxcP2P3RRPHJ-mglpSG6CH5fsHDmRSs4enjPS_hpRY-WRuELw8Id1B7SsRZKGGwnYH1gaBkCwgTBebLfWzVq9nZOPu_2lAVavyGT7rHg_xOespGY2ygAYQqGTqLAUn1v6EOGz-qz3fsYTd9j_p4gnTKwhS9hescORQzUA
```

Get the IP address of the kubeapps service:

```
kubectl get svc kubeapps -n kubeapps
```

Go to Kubeapps, sign in with token above: http://192.168.139.156

## OpenEMR Namespace Setup

Create a namespace for Open EMR called `openemr` with the following command:

```bash
kubectl create namespace openemr
```

Enable the default service account in the `openemr` namespace to deploy pods by executing the following command:

```bash
kubectl apply -f 02-OpenEMRRoleBinding.yml
```


## Install Redis

1. Login to Kubeapps if you are not already logged in
1. Set the current context in Kubeapps to the `openemr` namespace
1. Go th the "Catalog" tab and search for "redis"
1. Choose "redis" - not "redis-cluster"
1. Choose "Deploy" for the latest version
1. Change the name to "openemr-redis"
1. Change the architecture to "standalone"
1. Disable password authentication
1. Disable persistence
1. Switch to the YAML tab
1. Find the property `serviceAccount:create` and set it to `false`
1. Hit the "Deploy" button

You can watch the progress with

```bash
watch kubectl get all -n openemr
```

## Install MySQL

1. Login to Kubeapps if you are not already logged in
1. Set the Current context in Kubeapps to the `openemr` namespace
1. Go th the "Catalog" tab and search for "maria"
1. Choose "mariadb"
1. Choose "Deploy" for the latest version
1. Change the name to "openemr-mysql"
1. Change the architecture to "standalone"
1. Set the MariaBD root password to "root"
1. Clear the MariaDB custom database field
1. Disbale persistence
1. Switch to the YAML tab
1. Find the property `serviceAccount:create` and set it to `false`
1. Hit the "Deploy" button

You can watch the progress with

```bash
watch kubectl get all -n openemr
```

## Install Cloud Native Runtimes

In this section, we will install Tanzu Cloud Native Runtimes. First, install the pre-requisite tools.

### Install Carvel Tools

```bash
brew tap vmware-tanzu/carvel

brew install kapp ytt kbld
```

### Install Knative CLI

1. Download the client for your machine from here: https://github.com/knative/client/releases
1. Rename the executable to `kn` and place it in your path (`/usr/local/bin` on MacOS/Linux)
1. Make the file executable if on MacOS/Linux (`chmod +x /usr/local/bin/kn`)
1. If you are on MacOS, allow the file to run with Gatekeeper (`sudo xattr -d com.apple.quarantine /usr/local/bin/kn`)

### Install Cloud Native Runtimes

1. Download and untar the latest cloud native runtimes binary from Tanzu Network (http://network.pivotal.io)
1. From the untarred directory, execute the following command:

   ```bash
   serverless_provider=tkgs ./bin/install-serverless.sh
   ```

1. Accept the installation, then wait for the install to finish (takes a few minutes)

1. Once the installation is finished, you will need to apply a role binding to allow Knative to deploy pods in the `openemr`
   namespace:

   ```bash
   kubectl apply -f 03-KnativePSP.yml
   ```

   **Important Note:** this applies a very broad pod security policy and is required with cloud native runtimes
   version 0.2.0. Later versions will use a more restricted PSP, so keep en eye on the release notes.

### Setup DNS for Knative

Tanzu Cloud Native Runtimes uses Knative serving, Contour, and Envoy. This allows applications deployed
with Knative to use a standard ingress controller. In this section, we'll setup Knative and DNS so that
applications deployed with Cloud Native Runtimes will be easily exposed.

First, setup a custom domain for Knative serving by modifying and executing `04-KnativeCustomDomain.yml`. You should
replace `mypcp.tanzuathome.net` with a DNS name you can control. You will need to add a DNS "A" record for this domain.

Now find the external IP address of the ingress controller with this command:

```bash
kubectl get service envoy -n contour-external
```

Add a wildcard DNS record to your DNS using the IP address and domain you configured (for example, in my setup the IP address is 192.168.139.157 and the DNS entry is "*.mypcp.tanzuathome.net")


#### Knative Verification Test (Optional)
If you want to try a test application to check basic functionality of the cloud native runtimes, run the following:

```bash
kn service create helloworld-go -n openemr \
 --image gcr.io/knative-samples/helloworld-go --env TARGET="from Serverless"
```

After the app is deployed, it should be available at "http://helloworld-go.openemr.mypcp.tanzuathome.net"

You can delete the test application with the following:

```bash
kn service delete helloworld-go -n openemr
```

## Install phpMyAdmin

```bash
kn service create phpmyadmin -n openemr \
   --image phpmyadmin/phpmyadmin --port 80 --env PMA_HOSTS="openemr-mysql-mariadb"
```

You can create the same service with the following:

```bash
kubectl apply -f 05-KnativePhpMyAdmin.yml
```

The service will be available at http://phpmyadmin.openemr.mypcp.tanzuathome.net

## Install OpenEMR

OpenEMR is not a fully cloud native application - it requires several volume mounts. This causes issues when trying
to scale instances on a multi-node cluster. The persistent volume claims in the Minikube deployment use an access mode
of `ReadWriteOnce` - which means that the volume can only be mounted to a single node. This works well in Minikube,
but fails in a scaled and multi-node environment. So we need to setup vSphere to allow access mode `ReadWriteMany`.
This is also the reason that OpenEMR cannot be deployed with Cloud Native Runtimes (Knative) - Knative does not support
applications with persistent volume claims.

### Enabling ReadWriteMany Access Mode

**Important Note:** As of vSphere 7.0U2, Tanzu on vSphere does not support `ReadWriteMany` natively. This capability is
scheduled to come in vSphere 7.0U3.

This BLOG is extremely helpful in enabling ReadWriteMany for vSphere with an open source tool that will enable
`ReadWriteMany` persistent volume claims based on an existing NFS server:
https://core.vmware.com/blog/using-readwritemany-volumes-tkg-clusters

#### Setup the vSAN File Service

1. Add the following DNS records:

   | Name                                        | IP Address     |
   |---------------------------------------------|----------------|
   | fs1.file-service.tanzubasic.tanzuathome.net | 192.168.138.21 |
   | fs2.file-service.tanzubasic.tanzuathome.net | 192.168.138.22 |
   | fs3.file-service.tanzubasic.tanzuathome.net | 192.168.138.23 |


1. Select the cluster, then navigate to Configure>VSAN>Services
1. Chose "Enable" in the File Service
1. vSAN File Services Parameters:

   | Parameter    | Value                                                        |
   |--------------|--------------------------------------------------------------|
   | Domain       | file-service.tanzubasic.tanzuathome.net                      |
   | DNS          | 192.168.128.1                                                |
   | DNS Suffixes | file-service.tanzubasic.tanzuathome.net                      |
   | Network      | DVPG-Supervisor-Management-Network                           |
   | Subnet Mask  | 255.255.255.0                                                |
   | Gateway      | 192.168.138.1                                                |
   | IP Addresses | 192.168.138.21 (fs1.file-service.tanzubasic.tanzuathome.net) |
   | IP Addresses | 192.168.138.22 (fs2.file-service.tanzubasic.tanzuathome.net) |
   | IP Addresses | 192.168.138.23 (fs3.file-service.tanzubasic.tanzuathome.net) |

1. Once the vSAN File Services are enabled, create a new file share:
   1. Select the cluster
   1. Navigate to Configure>vSAN>File Shares
   1. Add a new file share called "openemr" and allow access from any IP address

Once the file share is created, look at the details and obtain the NFS 4.1 export path.
In my setup this was `fs1.file-service.tanzubasic.tanzuathome.net:/vsanfs/openemr`. You will need this in 
the next step.

#### Install the Open Source Provisioner

The file `06-NfsProvisionerValues.yml` contains configuration values for the NFS external provisioner. Alter this
file with the NFS server and path obtained from the file share you created above.

Now install the NFS external provisioner with the following commands:

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner

helm repo update

kubectl create namespace infra

helm install nfs-subdir-external-provisioner --namespace infra \
   nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -f 06-NfsProvisionerValues.yml
```

#### Install OpenEMR

Create the persistent volume claims for OpenEMR:

```bash
kubectl apply -f 07-OpenEMRPVC.yml
```

Create the OpenEMR Deployment:

```bash
kubectl apply -f 08-OpenEMRDeployment.yml
```

Create the OpenEMR Service:

```bash
kubectl apply -f 09-OpenEMRService.yml
```

Obtain the IP address of OpenEMR:

```bash
kubectl get service openemr -n openemr
```

For me, the external IP address is 192.168.139.158.  Access OpenEMR at https://192.168.139.158. Login with admin/pass.

## Teardown

```bash
kubectl delete -f 07-OpenEMRPVC.yml \
              -f 08-OpenEMRDeployment.yml \
              -f 09-OpenEMRService.yml
```

```bash
kubectl delete -f 05-KnativePhpMyAdmin.yml \
```
