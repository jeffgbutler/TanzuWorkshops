```
kubectl vsphere login --server 192.168.139.3 -u administrator@vsphere.local --insecure-skip-tls-verify

kubectl apply -f 01-CreateCluster.yaml

kubectl vsphere logout

kubectl vsphere login --server 192.168.139.3 --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name tap-cluster -u administrator@vsphere.local \
  --insecure-skip-tls-verify

# open PSP cluster wide
kubectl create clusterrolebinding default-tkg-admin-privileged-binding \
  --clusterrole=psp:vmware-system-privileged \
  --group=system:authenticated

brew upgrde kapp

# kubectl apply -f 02-KappControllerRoleBinding.yaml

kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.29.0/release.yml

kubectl get pods -A | grep kapp-controller

# kubectl apply -f 03-SecretgenControllerRoleBinding.yaml

kapp deploy -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.6.0/release.yml

kubectl get pods -A | grep secretgen-controller

# kubectl apply -f 04-CertManagerRoleBinding.yaml

kapp deploy -a cert-manager -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml

kubectl get deployment cert-manager -n cert-manager -o yaml | grep 'app.kubernetes.io/version: v'

kubectl create namespace flux-system

kubectl create clusterrolebinding default-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=flux-system:default

kapp deploy -a flux-source-controller -n flux-system \
  -f https://github.com/fluxcd/source-controller/releases/download/v0.15.4/source-controller.crds.yaml \
  -f https://github.com/fluxcd/source-controller/releases/download/v0.15.4/source-controller.deployment.yaml
```

# Install Packages

```shell
kubectl create ns tap-install

tanzu imagepullsecret add tap-registry \
  --username jgbutler@pivotal.io --password 'U.N24ui]!iw5dNG[(a' \
  --registry registry.tanzu.vmware.com \
  --export-to-all-namespaces --namespace tap-install

tanzu package repository add tanzu-tap-repository \
    --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:0.2.0 \
    --namespace tap-install

tanzu package repository get tanzu-tap-repository --namespace tap-install

tanzu package available list --namespace tap-install

Make a cnr_values.yaml file setting provider: tkgs

tanzu package install cloud-native-runtimes -p cnrs.tanzu.vmware.com -v 1.0.2 -n tap-install -f cnr-values.yaml --poll-timeout 30m

```

```shell
tanzu package installed list -n tap-install
tanzu package installed delete cloud-native-runtimes -n tap-install

kubectl delete secret cloud-native-runtimes-tap-install-values -n tap-install
kubectl delete clusterrolebinding cloud-native-runtimes-tap-install-cluster-rolebinding
kubectl delete clusterrole cloud-native-runtimes-tap-install-cluster-role
kubectl delete sa cloud-native-runtimes-tap-install-sa -n tap-install

tanzu package install cloud-native-runtimes -p cnrs.tanzu.vmware.com -v 1.0.2 -n tap-install -f cnr-values.yaml --poll-timeout 30m
```

# Teardown

```shell
kapp delete -a flux-source-controller -n flux-system

kubectl delete clusterrolebinding default-admin

kubectl delete namespace flux-system

kapp delete -a cert-manager

kapp delete -a sg

kapp delete -a kc
```
