# Install and Configure Cloud Native Runtimes

Login to the cluster you created:

```shell
kubectl vsphere logout

kubectl vsphere login --server 192.168.139.3 --tanzu-kubernetes-cluster-namespace test-namespace \
  --tanzu-kubernetes-cluster-name dev-cluster -u administrator@vsphere.local \
  --insecure-skip-tls-verify
```

## Install Carvel Tools

```shell
brew tap vmware-tanzu/carvel
brew install kapp ytt kbld
```

## Install Knative CLI

On Mac...

```shell
brew tap knative/client
brew install kn
```

Otherwize...

1. Download the Knative client for your machine from here: https://github.com/knative/client/releases
1. Rename the executable to `kn` and place it in your path (`/usr/local/bin` on MacOS/Linux)
1. Make the file executable if on MacOS/Linux (`chmod +x /usr/local/bin/kn`)
1. If you are on MacOS, allow the file to run with Gatekeeper (`sudo xattr -d com.apple.quarantine /usr/local/bin/kn`)

## TKGS Permissions

If you are on vSphere with Tanzu (TKGS), then you will need some permissions setup to install the Kapp controller
and other items. For a POC, it is easiest to enable any authenticated account with a command like the following
(this is not recommended for production clusters):

```shell
kubectl create clusterrolebinding default-tkg-admin-privileged-binding \
  --clusterrole=psp:vmware-system-privileged \
  --group=system:authenticated
  ```

## Install the Kapp Controller

If the Kapp controller is not installed in your cluster, install it via...

```shell
kapp deploy -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/latest/download/release.yml
```

## Install Cloud Native Runtimes

1. Download and untar the latest cloud native runtimes binary from Tanzu Network (http://network.pivotal.io)
1. From the untarred directory, execute the following command:

   ```shell
   cnr_provider=tkgs ./bin/install.sh
   ```

1. Accept the installation defaults, then wait for the install to finish (takes a few minutes)

## Setup DNS for Knative

Tanzu Cloud Native Runtimes uses Knative serving, Contour, and Envoy. This allows applications deployed
with Knative to use a standard ingress controller. In this section, we'll setup Knative and DNS so that
applications deployed with Cloud Native Runtimes will be easily exposed.

```shell
kubectl edit configmap config-domain -n knative-serving
```

Edit the config map and add `cnr.tanzuathome.net: ""` after the `data` element (indented).

This sets up CNR to route all requests that come in to `cnr.tanzuathome.net`.

Now find the external IP address of the ingress controller with this command:

```bash
kubectl get service envoy -n contour-external
```

Add a wildcard DNS record to your DNS using the IP address and domain you configured (for example, in my setup the IP address is 192.168.139.7
and the DNS entry is "*.cnr.tanzuathome.net")


## Knative Verification Test (Optional)
If you want to try a test application to check basic functionality of the cloud native runtimes, run the following:

```shell
kn service create helloworld-go \
 --image gcr.io/knative-samples/helloworld-go \
 --env TARGET="from Serverless"
```

After the app is deployed, it should be available at "http://helloworld-go.default.cnr.tanzuathome.net"

You can delete the test application with the following:

```bash
kn service delete helloworld-go
```

## Setup TLS

This procedure is for manually setting up TLS. Knative also supports auto generation of certificates.

Generate a certificate for `*.cnr.tanzuathome.net`

Install the certificate in K8S:

```shell
sudo kubectl create -n contour-external secret tls default-cert \
  --key /etc/letsencrypt/live/cnr.tanzuathome.net/privkey.pem \
  --cert /etc/letsencrypt/live/cnr.tanzuathome.net/fullchain.pem
```

Setup the Contour certificate delegation:

```shell
kubectl apply -f 01-TlsDelegation.yaml
```

Set fallback when auto-TLS is disabled:

```shell
kubectl patch configmap config-contour -n knative-serving \
  -p '{"data":{"default-tls-secret":"contour-external/default-cert"}}'
```

Configure Knative to auto-redirct HTTP requests to HTTPS, then change the route template
so that it will work with our single level wildcard.

```shell
kubectl edit cm  -n knative-serving config-network
```

Then add the following indented under `data`:

```yaml
domainTemplate: "{{.Name}}.{{.Domain}}"
httpProtocol: "Redirected"
```

## Cleanup

Delete all applications deployed. To find a list of all applications, enter...

```shell
kn service list -A
```

Then `kn service delete` on each application.

```shell
kapp delete -a cloud-native-runtimes -n cloud-native-runtimes
kubectl delete ns cloud-native-runtimes
kapp delete -a kc
```
