Taken from here: https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-4CCDBB85-2770-4FB8-BF0E-5146B45C9543.html

```shell
kubectl create clusterrolebinding default-tkg-admin-privileged-binding \
  --clusterrole=psp:vmware-system-privileged \
  --group=system:authenticated
```
