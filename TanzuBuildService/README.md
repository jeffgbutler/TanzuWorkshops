## Create Cluster for TBS
```shell
kubectl vsphere login --server 192.168.139.3 -u administrator@vsphere.local --insecure-skip-tls-verify

kubectl config use-context test-namespace

kubectl apply -f 01-CreateTBSCluster.yml
```

**Important Note:** Added the CA for LetsEncrypt! to the cluster definition. Generated the Base64 string with the following:

```shell
sudo base64 -i /etc/letsencrypt/live/tanzuathome.net/chain.pem
```

Wait for the cluster to be created (about 20-30 minutes). Check progress with the following command:

```shell
kubectl get TanzuKubernetesClusters
```

Logout of the management cluster and login to your new cluster (replace the IP address and user ID below with the IP address of
your vSphere control plane and your TKGS credentials):

```shell
kubectl vsphere logout

kubectl vsphere login --server 192.168.139.3 --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name tbs-cluster -u administrator@vsphere.local \
  --insecure-skip-tls-verify

kubectl config use-context tbs-cluster
```

## Create Harbor User and Project

- Create project tbs-images
- Create Robot account and attach to tbs-images project 

robot$tbs-robot/FcfaVpZPUSYvDva9oFfiLMobkYtjKnZK

## Disable Pod Security Policy on TKGS

```shell
kubectl create clusterrolebinding default-tkg-admin-privileged-binding \
  --clusterrole=psp:vmware-system-privileged \
  --group=system:authenticated
```

## Install Tanzu Build Service

1. Install KP CLI

   ```shell
   brew tap vmware-tanzu/kpack-cli
   brew install kp
   ```

1. Install kapp, ytt, kbld, imgpck (from Homebrew tap vmware-tanzu/carvel)
1. `docker login registry.tanzu.vmware.com`
1. `docker login harbor.tanzuathome.net`
1. `imgpkg copy -b "registry.tanzu.vmware.com/build-service/bundle:1.3.1" --to-repo harbor.tanzuathome.net/tbs-images/build-service --registry-ca-cert-path ~/LetsEncryptR3.pem`
1. `imgpkg pull -b "harbor.tanzuathome.net/tbs-images/build-service:1.3.1" -o /tmp/bundle --registry-ca-cert-path ~/LetsEncryptR3.pem`

```shell
ytt -f /tmp/bundle/values.yaml \
    -f /tmp/bundle/config/ \
    -f /Users/jeffbutler/LetsEncryptR3.pem \
	-v kp_default_repository='harbor.tanzuathome.net/tbs-images/build-service' \
	-v kp_default_repository_username='admin' \
	-v kp_default_repository_password='Harbor12345' \
	-v pull_from_kp_default_repo=true \
	| kbld -f /tmp/bundle/.imgpkg/images.yml -f- \
	| kapp deploy -a tanzu-build-service -f- -y
```

(took about 15 minutes)

## Import Dependencies

Download a dependencies file from PivNet (Tanzu Build Service Dependencies)

Login to all registries:

```shell
docker login registry.tanzu.vmware.com
docker login registry.pivotal.io
docker login harbor.tanzuathome.net
```

Import the dependencies:

```shell
kp import -f ~/Downloads/descriptor-100.0.200.yaml --registry-ca-cert-path ~/LetsEncryptR3.pem
```

This took about 15 minutes and had to be restarted a few times due to weird TLS handshake issues.

## Setup Registry Secret for Harbor

- Create a project `tbs-builds` in Harbor
- Store a registry secret for Harbor in TBS

```shell
kp secret create harbor-registry-creds --registry harbor.tanzuathome.net --registry-user admin
```

## Run a Test Build

```shell
kp image create tbs-sample --tag harbor.tanzuathome.net/tbs-builds/tbs-sample --git https://github.com/buildpacks/samples --sub-path ./apps/java-maven --wait
```

Useful KP commands:

```shell
kp image list (shows all build definitions)
kp build list (shows all builds)
kp build logs tbs-sample -b 1
kp build status tbs-sample
```

## Uninstall Tanzu Build Service

```shell
kapp delete -a tanzu-build-service
```

