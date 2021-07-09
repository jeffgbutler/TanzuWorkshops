# Installing OpenEMR in vSphere with Tanzu

Description of installing OpenEMR in vSphere native Kubernetes Clusters with Kubeapps and Cloud Native Runtimes.

Architectural Goals:

1. MySql and Redis installed via TAC (Kubeapps)
1. phpMyAdmin installed via Tanzu Cloud Native Runtimes (Knative)
1. OpenEMR installed as a native Kubernetes application that can be scaled

Initially, we will start with everything in a single cluster. Later we will use two clusters - "data" and "compute" 

## Prerequisites

- You must have access to a Kubernetes cluster. If you are using Tanzu on vSphere you can follow the steps outlined
  in the [cluster creation](../clusterCreation) section.
- The cluster must have a storage class named `nfs-external` that supports access mode of `ReadWriteMany`. You can
  follow the steps in the [create NFS provisioner](../createNFS) section for details on how to accomplish this
  with vSAN on vSphere

## Create and Prepare a Namespact for OpenEMR

We'll install OpenEMR into a namecpase call `openemr`. Create the namespace with this command:

```shell
kubectl create Namespace openemr
```

TKGS requires that we assign explicit permission to the default service account to allow it to deploy pods. Execute the
following to assign TKGS permissions (this step will be different, or perhaps not required, on other Kubernetes distributions):

```shell
kubectl apply -f 01-RoleBinding.yml
```

## Install Kubeapps/Bitnami

We will use Kubeapps to install MySQL and Redis. Kubeapps is installed via Helm chart.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update
```

Create a namspace for Kubeapps:

```bash
kubectl create namespace kubeapps
```

Users - even admin users - have very little authority in TKGS clusters initially. We'll need to create role bindings
for Kubeapps before we try to install it. So run the role binding script:

```bash
kubectl apply -f 02-KubeappsRoleBindings.yml
```

Now install Kubeapps. This command will install Kubeapps in the `kubeapps` namespace and will provision a load balancer for
the UI. Once you run this command, it will take a few minutes to install. You can monitor the progress by watching
pod creation status in the `kubeapps` namespace.

```bash
helm install kubeapps --namespace kubeapps --set frontend.service.type=LoadBalancer bitnami/kubeapps
```

You can watch the progress of the Kubeapps install with the following:

```bash
kubectl get all -n kubeapps
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
eyJhbGciOiJSUzI1NiIsImtpZCI6Ing0ZFRFRlhEUzVLcDV6Q2o2V0xFWmV3akstRko5T1FiZUVBYjN0dkFqcTAifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Imt1YmVhcHBzLW9wZXJhdG9yLXRva2VuLTJtZndrIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6Imt1YmVhcHBzLW9wZXJhdG9yIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiN2E4NmI5MDEtZDY3NC00NzVjLWIzNzQtMmIxNDkxYjBhM2UzIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6a3ViZWFwcHMtb3BlcmF0b3IifQ.TyZoakxQ6HL4rDH0TmwCMbws8QFyaIbOzG7cKV0bFJDfBkI_eztwIxFm6RXQsLTBRMM0-XniBylRxs_6y9RwUA5xvgUobmEJlZIYrH4apkeRKF0vKCLozVKtbu5Vqqoaypueh1dlt1DTZMkon0b6VWT7cAkZcPAoOqpMPABuERvBRWE8SeCNX6HSDm64AlkscEcOqzsdAj-sq7q8UiztWb7ZyHkuM2Cg2mD5v4JeYTq_ykSZTDFaGfKdtzjmUSIT9pFAwh_mEmxWFpGn_x8v4WXfLk-aOhu0N2sxUieQc-UJhq1w7eU361KWxxabHKS7stIiMUyuMhCAJRXLS9uYcw
```

Get the IP address of the kubeapps service:

```
kubectl get svc kubeapps -n kubeapps
```

Go to Kubeapps, sign in with token above: http://192.168.139.7

## Install Redis with the Kubeapps UI

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

## Install MySQL with the Kubeapps UI

(You must either install MySql with the Kubeapps UI or via Helm)

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

1. Download the Knative client for your machine from here: https://github.com/knative/client/releases
1. Rename the executable to `kn` and place it in your path (`/usr/local/bin` on MacOS/Linux)
1. Make the file executable if on MacOS/Linux (`chmod +x /usr/local/bin/kn`)
1. If you are on MacOS, allow the file to run with Gatekeeper (`sudo xattr -d com.apple.quarantine /usr/local/bin/kn`)

### Install Cloud Native Runtimes

1. Download and untar the latest cloud native runtimes binary from Tanzu Network (http://network.pivotal.io)
1. From the untarred directory, execute the following command:

   ```bash
   serverless_provider=tkgs ./bin/install-serverless.sh
   ```

1. Accept the installation defaults, then wait for the install to finish (takes a few minutes)

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

First, setup a custom domain for Knative serving by modifying and executing `03-KnativeCustomDomain.yml`. You should
replace `mypcp.tanzuathome.net` with a DNS name you can control. You will need to add a DNS "A" record for this domain.

```bash
kubectl apply -f 04-KnativeCustomDomain.yml
```

Now find the external IP address of the ingress controller with this command:

```bash
kubectl get service envoy -n contour-external
```

Add a wildcard DNS record to your DNS using the IP address and domain you configured (for example, in my setup the IP address is 192.168.139.8
and the DNS entry is "*.mypcp.tanzuathome.net")


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

The phpMyAdmin tool is a user interface for interacting with MySQL databases. It can easily be installed via Tanzu Cloud Native Runtimes.
You can install it with the `kn` command directly, or through Kubernetes YML. Run either of the following to install phpMyAdmin:

```bash
kn service create phpmyadmin -n openemr \
   --image phpmyadmin/phpmyadmin --port 80 --env PMA_HOSTS="openemr-mysql-mariadb"
```

You can create the same service with the following:

```bash
kubectl apply -f 05-KnativePhpMyAdmin.yml
```

The service will be available at http://phpmyadmin.openemr.mypcp.tanzuathome.net (login with root/root)

## Install OpenEMR

First, make sure you have followed the installation steps for creating an NFS server in the cluster preperation section.

Create the persistent volume claims for OpenEMR:

```bash
kubectl apply -f 06-OpenEMRPVC.yml
```

After the volume claims have been bound, setup the certificates...

1. `mkdir ~/temp/openemr`
1. `mount -t nfs fs1.nfs.tanzubasic.tanzuathome.net:/openemr ~/temp/openemr/`
1. `cd ~/temp/openemr/openemr-letsencryptvolume...`
1. `mkdir -p live/openemr.tanzuathome.net`
1. `cd live/openemr.tanzuathome.net`
1. `sudo cp /etc/letsencrypt/live/tanzuathome.net/fullchain.pem .`
1. `sudo cp /etc/letsencrypt/live/tanzuathome.net/privkey.pem .`
1. `cd ~/temp`
1. `umount ~/temp/openemr`


Create the OpenEMR Deployment:

```bash
kubectl apply -f 07-OpenEMRDeployment.yml
```

This deploys a single instance of OpenEMR. OpenEMR takes quite a long time to initialize. You can follow progress by tailing the pod logs.
For example:

```bash
kubectl logs openemr-798bff8bb9-r9h79 -n openemr -f
```

It takes about 10 minutes to start.

Create the OpenEMR Service:

```bash
kubectl apply -f 08-OpenEMRService.yml
```

Obtain the IP address of OpenEMR:

```bash
kubectl get service openemr -n openemr
```

For me, the external IP address is 192.168.139.7.

Add a DNS A record for `openemr.tanzuathome.net` at IP 192.168.139.7

Access OpenEMR at https://openemr.tanzuathome.net. Login with admin/pass.

Once OpenEMR is up and running, you can scale the deployment with the following command:

```bash
kubectl scale deployment openemr -n openemr --replicas=5
```

Note that an OpenEMR instance takes about 5 minutes to start in scaled mode!
