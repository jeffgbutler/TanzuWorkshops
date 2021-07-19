# Cluster Preparation

This page shows how to create and prepare a TKGS cluster for a simplified K8S developer experience. This will show how to
do the following:

- Create a TKGS cluster (Tanzu on vSphere)
- Install and Configure Kubeapps (Tanzu Application Catalog)
- Install and Configure Cloud Native Runtimes (Knative)

## Pre-Requisites

A pre-requisite is that you have access to a vSphere cluster where workload management has been enabled. One way to accomplish that
is to use a nested vSphere 7 environment. William Lam has instructions for creating a nested vSphere environment here:
https://github.com/lamw/vsphere-with-tanzu-nsx-advanced-lb-automated-lab-deployment. My own environment is based on his
work with the main differences being the basic networking setup, and I am using more current versions of ESXi and VCenter
than he describes in his script. Other than that, I am using his script basically as-is.

Also available from William's site are the nested ESXi appliances you will need: https://williamlam.com/nested-virtualization

## Create a Kubernetes Cluster on TKGS

Using the vSphere UI, create a namespace `test-namespace`.

Login to the `test-namespace` namespace with kubectl (replace the IP address and user ID below with the IP address of your vSphere
control plane and your TKGS credentials):

```shell
kubectl vsphere login --server 192.168.139.2 -u administrator@vsphere.local --insecure-skip-tls-verify

kubectl config use-context test-namespace
```

Create a cluster:

```shell
kubectl apply -f 01-CreateCluster.yml
```

Wait for the cluster to be created (about 20-30 minutes). Check progress with the following command:

```shell
kubectl get TanzuKubernetesClusters
```

Logout of the management cluster and login to your new cluster (replace the IP address and user ID below with the IP address of
your vSphere control plane and your TKGS credentials):

```shell
kubectl vsphere logout

kubectl vsphere login --server 192.168.139.2 --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name dev-cluster -u administrator@vsphere.local \
  --insecure-skip-tls-verify

kubectl config use-context dev-cluster
```

TKGS requires that we assign explicit permission to the default service account to allow it to deploy pods. Execute the
following to assign TKGS permissions (this step will be different, or perhaps not required, on other Kubernetes distributions):

```shell
kubectl apply -f 02-RoleBinding.yml
```

## Install Kubeapps

We will use Kubeapps to install Redis. Kubeapps is installed via Helm chart.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update
```

Create a namespace for Kubeapps:

```bash
kubectl create namespace kubeapps
```

Users - even admin users - have very little authority in TKGS clusters initially. We'll need to create role bindings
for Kubeapps before we try to install it. So run the role binding script:

```bash
kubectl apply -f 03-KubeappsRoleBindings.yml
```

Now install Kubeapps. This command will install Kubeapps in the `kubeapps` namespace and will provision a load balancer for
the UI. Once you run this command, it will take a few minutes to install. You can monitor the progress by watching
pod creation status in the `kubeapps` namespace.

```bash
helm install kubeapps --namespace kubeapps --set frontend.service.type=LoadBalancer bitnami/kubeapps
```

You can watch the progress of the Kubeapps install with the following (takes 2-3 minutes):

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
eyJhbGciOiJSUzI1NiIsImtpZCI6IlZnMUYtN1lIZUpUR0NUZjQxSFBTN21GSHJwcGtXcC1CRFZOTXZ4LXhzeDAifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Imt1YmVhcHBzLW9wZXJhdG9yLXRva2VuLWJsOGNtIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6Imt1YmVhcHBzLW9wZXJhdG9yIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiZjFkNDE2YjQtYWM5OS00MzRjLWFjZDctYzBlMmU3NzhkZWNkIiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6a3ViZWFwcHMtb3BlcmF0b3IifQ.OmG4SqTrQXvVrTHJ27NoRmFulslNy6pGYGFDYDA7wRY6lZIQ_jwAjJgm6ffMwhIKqyjqSZYYrZtpx07qhBwzeciqjiAKmkFSoEShgk1EGfCVjZK9ZjMQ-klyHHdw4L8Kgh571sUxizh46n8791gUzfyCLGj4370iaJXxnz4xSjpUyxZqMjMlqzPDgtwwrKPUCu6Y793vergRk1CfXa-Xhpnmc8OzQPXTZNdoMC99qmJNFgpp20w1at2MHrzB018xHPM5oMspmpZM9w6FdjzPd4lsk4elPTlKJ4060_9XxRDDnjHhsIxVsjS92UwOIRVDa0GMFnAu4L6pvUbewdUG5g
```

Get the IP address of the kubeapps service:

```
kubectl get svc kubeapps -n kubeapps
```

Go to Kubeapps, sign in with token above: http://192.168.139.9

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

### Install Cloud Native Runtimes 1.0.0

**Important Note:** These instructions are tested with Cloud Native Runtimes version 1.0.0+build.44. This is a beta release,
so things might change in the future.

Install instructions (VMware internal): https://docs-staging.vmware.com/en/Cloud-Native-Runtimes-for-VMware-Tanzu/1.0/tanzu-cloud-native-runtimes-1-0/GUID-install.html

1. Install the Kapp Controller in your Kubernetes Cluster (about 1 minute)

   ```shell
   kubectl apply -f 04-KappControllerRoleBinding.yml

   kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
   ```

1. Download and untar the latest cloud native runtimes binary from Tanzu Network (http://network.pivotal.io)
1. From the untarred directory, execute the following command (about 3 minutes):

   ```bash
   cnr_provider=tkgs ./bin/install.sh
   ```

1. Accept the installation defaults, then wait for the install to finish (takes a few minutes)

1. Create a namespace for demo:

   ```shell
   kubectl create namespace cnr-demo
   ```

1. Apply pod security policy for the new namespace:

   ```shell
   kubectl apply -f 05-KnativePSP.yml
   ```

### Setup DNS for Knative

Tanzu Cloud Native Runtimes uses Knative serving, Contour, and Envoy. This allows applications deployed
with Knative to use a standard ingress controller. In this section, we'll setup Knative and DNS so that
applications deployed with Cloud Native Runtimes will be easily exposed.

First, setup a custom domain for Knative serving by modifying and executing `04-KnativeCustomDomain.yml`. You should
replace `dev.tkgs.tanzuathome.net` with a DNS name you can control. You will need to add a DNS "A" record for this domain.

```bash
kubectl apply -f 06-KnativeCustomDomain.yml
```

Now find the external IP address of the ingress controller with this command:

```bash
kubectl get service envoy -n contour-external
```

Add a wildcard DNS record to your DNS using the IP address and domain you configured (for example, in my setup the IP address is 192.168.139.10
and the DNS entry is "*.dev.tkgs.tanzuathome.net")


#### Knative Verification Test (Optional)
If you want to try a test application to check basic functionality of the cloud native runtimes, run the following:

```shell
kn service create helloworld-go -n cnr-demo \
--image gcr.io/knative-samples/helloworld-go --env TARGET='from Cloud Native Runtimes' \
--user 1001
```

After the app is deployed, it should be available at "http://helloworld-go.cnr-demo.dev.tkgs.tanzuathome.net"

You can delete the test application with the following:

```shell
kn service delete helloworld-go -n cnr-demo
```
