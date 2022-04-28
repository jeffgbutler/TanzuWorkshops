# Tanzu Community Edition Workshop for Windows

Workshop for Tanzu Community Edition with intructions written specifically for Windows users.

**Important:** this workshop is based on version 0.11.0 or greater of Tanzu Community Edition.
The instructions will not work if you use earlier versions.

## Pre-Requisites

Install:

- Docker Desktop: https://docs.docker.com/desktop/windows/install/
- Chocolatey: https://chocolatey.org/install
- Knative CLI: https://github.com/knative/client/releases (download latest binary, rename to "kn", add to path)
- Kpack CLI: https://github.com/vmware-tanzu/kpack-cli/releases (download latest binary, rename to "kp", add to path)

You must also have write access to a container registry. There are several places in the workshop where you will need
to enter credentials and configuration information for your registry. Examples of the various values are as follows:

- Dockerhub:
  - kpack.kp_default_repository in app toolkit configuration: `your-name/kpack`
  - docker_server in the Kpack secret: `https://index.docker.io/v1/`
  - spec.tag in the Kpack Builder configuration: `your-name/builder`
  - spec.tag in the Kpack Image configuration: `your-name/spring-pet-clinic`
- Harbor (create a Harbor project for tce - I created a project called "tce"):
  - kpack.kp_default_repository in app toolkit configuration: `harbor.tanzuathome.net/tce/kpack`
  - docker_server in the Kpack secret: `harbor.tanzuathome.net`
  - spec.tag in the Kpack Builder configuration: `harbor.tanzuathome.net/tce/builder`
  - spec.tag in the Kpack Image configuration: `harbor.tanzuathome.net/tce/spring-pet-clinic`
- GCR:
  - kpack.kp_default_repository in app toolkit configuration: `gcr.io/your-project/kpack`
  - docker_server in the Kpack secret: `gcr.io`
  - spec.tag in the Kpack Builder configuration: `gcr.io/your-project/builder`
  - spec.tag in the Kpack Image configuration: `gcr.io/your-project/spring-pet-clinic`


## Exercise 1: Install and Test Tanzu Community Edition

> Important Concepts to cover in an overview:
>
> - Unmanaged vs. Managed Clusters
> - Tanzu CLI and CLI plugins
> - Tanzu Package Management with Kapp

Install Tanzu Community Edition (TCE) with Chocolatey:

```powershell
choco install tanzu-community-edition --version 0.11.0
```

Note that it is important to specify the version! TCE is currently a moderated package at Chocolatey and this version is not
set as the default.

Installing TCE does not create Kubernetes clusters. Rather, it installs the Tanzu CLI and several plugins that enable
you to create clusters and manage packages in clusters.

Create a cluster:

```shell
tanzu unmanaged-cluster create tceworkshop --port-map '80:80,443:443'
```

This will create a single node unmanaged Kubernetes cluster using **Kind** (Kubernetes in Docker) on your local workstation.
Unmanaged clusters are suitable for short lived experimentation and learning (such as this workshop). They also start very quickly.
This cluster will have the following characteristics:

- Ports 80 and 443 are exposed on your workstation to allow easier access to workloads deployed on the cluster
- The kapp controller will be installed to support Tanzu package management
- The cluster will have the package catalog for Tanzu configured

Unmanaged clusters are not suitable for production workloads. For production workloads, TCE can create "managed clusters"
in a variety of cloud based environments, on vSphere, and even on Docker on your workstation if you so desire.

Once the cluster is up, `kubectl` should be configured to connect to it. You can test this by running the following:

```shell
kubectl get nodes
```

You should see a single node named something like `tceworkshop-control-plane`.

You can deploy a test image with the following command:

```shell
kubectl run kuard --restart=Never --image=gcr.io/kuar-demo/kuard-amd64:blue
```

Once the pod is running, enter the following command to access it:

```shell
kubectl port-forward kuard 8080:8080
```

Now you should be able to access the pod in a browser at http://localhost:8080

Assuming all this works, then enter `ctrl-c` to stop the port forward, then enter the following command to delete
the pod:

```shell
kubectl delete pod kuard
```

## Exercise 2: Tanzu Packages

Your TCE unmanaged cluster comes pre-configured with access to a rich catalog of packages that can be easily
installed into the cluster. To see a list of available packages, enter the following command:

```shell
tanzu package available list
```

You should see a list of 15-20 packages. Many are standard open source building blocks of a Kubernetes platform
like Prometheus, Grafana, Cert Manager, External DNS, etc. Tanzu makes it very easy to install these componants.

Most packages have several versions available. You can see the available versions of a package with a command like the
following (this will show all available versions of cert manager):

```shell
tanzu package available list cert-manager.community.tanzu.vmware.com
```

Most packages can be configured with values specific to your needs. If you want to see the configuration options for
a package, enter a command like the following:

```shell
tanzu package available get cert-manager.community.tanzu.vmware.com/1.6.1 --values-schema
```

This command will show that cert manager version 1.6.1 accepts a single parameter `namespace` and the default
value is `cert-manager`. Package installs can accept a YAML "values file" that contains configuration parameters.
We will see an example of this in the next section.

## Exercise 3: Configure and Install the App Toolkit

> Important Concepts to cover in an overview:
>
> - Overview of the App Toolkit Package

The App Toolkit is a composite package (it bundles other packages together). It is a simple way to install
a group of packages that are relevant to application developers including:

- Contour - a Kubernetes ingress controller
- Kpack - an image building tool
- Knative Serving - a Kubernetes framework that simplifies application deployments
- Cartographer - a tool for creating software supply chains
- Several others

With this exercise we will install and configure the app toolkit for use on a local workstation. Take a look
at the file [01-app-toolkit-values.yaml](01-app-toolkit-values.yaml) in this directory. This file contains
configuration values for several of the packages in the app toolkit (Contour, Knative, and Kpack). For now, the
important things to know are these:

- Applications deployed to the app toolkit will have generated DNS names that are sub-domains of
  `127-0-0-1.nip.io`. This is a convenient DNS trick - the IP address for this domain is
  `127.0.0.1` - or `localhost` - so it will work on everyone's workstation.
- Kpack is configured to talk to a Harbor instance in Jeff's homelab. You will need to change these
  values to match a container registry you have access to

Once you have updated the default repository values, install the app toolkit with the following command:

```powershell
tanzu package install app-toolkit --package-name app-toolkit.community.tanzu.vmware.com `
  --version 0.1.0 --values-file 01-app-toolkit-values.yaml
```

This command will run for a few minutes. Once the package install finishes reconciling, you can see the full list
of installed packages with the following command:

```shell
tanzu package installed list -A
```

Let's deploy an application with Knative as a test. This can be done in two ways - with the Knative CLI or with Kubectl
and a YAML file.

### Deploy a Knative Application with the Knative CLI

The Knative CLI is a very simple way to deploy an application to Knative. It does not have as much
flexability as using the full Kubactl/YAML method, but it does have sensable defaults for many situations.
Let's deploy Kuard with Knative:

```shell
kn service create kuard --image gcr.io/kuar-demo/kuard-amd64:blue
```

Once the command completes, the application should be available at http://kuard.default.127-0-0-1.nip.io/

Take a look at what got created in your cluster:

```shell
kubectl get all
```

You should see pods, services, a deployment, a replica set, and several other objects related to Knative. You can see
that Knative is doing quite a lot with a simple command! Knative has also generated a URL for this application and
configured the ingress controller (Contour in this case). By default, the URL is calculated as
`app_name.namespace.base_domain` - where `base_domain` is what we configured when we installed the app toolkit
(`127-0-0-1.nip.io` in this case).

By default, Knative sets up "scale to zero" functionality for the services it deploys. This because Knative started
as a "serverless" toolkit for Kubernetes. You can see this in action by watching the pod - it will eventually go away
and only the other Knative objects will remain. Once the pod is gone, you can still hit the application but it
will be slow initially as Knative will spin up a new pod once traffic starts flowing again.

Once you are finished experimenting with Knative, you can delete the service with the following command:

```shell
kn service delete kuard
```

### Deploy a Knative Application with Kubectl

The file [02-kuard-service.yaml](02-kuard-service.yaml) in this directory contains YAML for acheiving the
same deployment of Kuard we did above with one exception - we turn off "scale to zero" functionality. This can
also be accomplished with the CLI (see the `--scale-min` parameter).

Deploy the service with Kubectl:

```shell
kubectl apply -f 02-kuard-service.yaml
```

The app should be avilable at http://kuard.default.127-0-0-1.nip.io/

Everything should be the same as before except that with this deployment the app will not scale to zero.

Once you are finished experimenting, you can delete the service with the CLI as before, or also with Kubectl: 

```shell
kn service delete kuard

kubectl delete -f 02-kuard-service.yaml
```

Knative has many features and configuration options. For details see the official documentation
here: https://knative.dev/docs/

## Exercise 4: Configure Kpack

Instructions adapted from here: https://github.com/pivotal/kpack/blob/main/docs/tutorial.md

Create a registry secret:

```powershell
kubectl create secret docker-registry kpack-registry-credentials `
    --docker-username=admin `
    --docker-password=Harbor12345 `
    --docker-server=harbor.tanzuathome.net `
    --namespace default
```

```powershell
kubectl apply -f 03-kpack-values.yaml
```

Deploy a test build:

```powershell
kubectl apply -f 04-kpack-test-image.yaml
```

## Cleanup

```powershell
tanzu unmanaged-cluster delete tceworkshop
```
