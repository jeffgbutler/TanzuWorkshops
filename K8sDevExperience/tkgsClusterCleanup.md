# Cluster Cleanup

You should not just delete the cluster - it is better to delete the individual components first. This will help recycle load
balancer IPs.

1. Delete any services you installed via the Knative CLI. For example:

   ```shell
   kn service delete payment-calculator
   ```

1. Delete any applications you deployed through kubeapps

1. Delete Any Application Name Spaces

   ```shell
   kubectl delete ns cnr-demo
   ```

1. Uninstall Cloud Native Runtimes:

   ```shell
   kapp delete -a cloud-native-runtimes -n cloud-native-runtimes
   kubectl delete ns cloud-native-runtimes
   ```

1. Delete the Kapp Controller

   ```shell
   kapp delete -a kc

   kubectl delete ClusterRoleBinding kapp-controller-psp-role-binding
   ```

1. Delete Kubeapps:

   ```shell
   helm uninstall kubeapps -n kubeapps

   kubectl delete ns kubeapps
   ```

1. Delete any persistent volume claims you may have created

1. Logout of the cluster, login to the control plane, delete the cluster

   ```shell
   kubectl vsphere logout
   
   kubectl vsphere login --server 192.168.139.3 -u administrator@vsphere.local --insecure-skip-tls-verify

   kubectl config use-context test-namespace

   kubectl delete TanzuKubernetesCluster dev-cluster
   ```
