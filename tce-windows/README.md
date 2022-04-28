# Install Tanzu Community Edition for Windows

Instructions for creating standalone (unmanaged) clusters on Windows

## Pre-Reqs

Install:

- Docker Desktop: https://docs.docker.com/desktop/windows/install/
- Chocolatey: https://chocolatey.org/install
- Knative CLI: https://github.com/knative/client/releases (download latest binary, rename to "kn", add to path)
- Kpack CLI: https://github.com/vmware-tanzu/kpack-cli/releases (download latest binary, rename to "kp", add to path)

## Install Tanzu Community Edition

```powershell
choco install tanzu-community-edition --version 0.11.0
```

Create a cluster

```powershell
tanzu unmanaged-cluster create tceworkshop --port-map '80:80,443:443'
```

## Install App Toolkit

```powershell
tanzu package install app-toolkit --package-name app-toolkit.community.tanzu.vmware.com `
  --version 0.1.0 -values-file 01-app-toolkit-values.yaml
```

Deploy an application with Knative as a test

```powershell
kubectl apply -f 02-payment-calculator-service.yaml
```

The app should be avilable at http://payment-calculator.default.127-0-0-1.nip.io/

Delete the test application:

```powershell
kubectl delete -f 02-payment-calculator-service.yaml
```

## Configure Kpack

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
