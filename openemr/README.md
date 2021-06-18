# Installing OpenEMR in vSphere with Tanzu

Description of installing OpenEMR in vSphere native Kubernetes Clusters.

This work is based on the OpenEMR minikube deployment described here:
https://github.com/openemr/openemr-devops/tree/master/kubernetes/minikube. Deploying OpenEMR to a single node
minikube based cluster is relatively easy. Things get a bit more complex when deploying OpenEMR to a multi-node
cluster or to multiple clusters. Describing and overcoming those issues is one of the goals of this project.

Prerequisite: vSphere 7 with workload management enabled. I'm using a setup based on William Lam's
nested vSphere environment. Details here: https://github.com/lamw/vsphere-with-tanzu-nsx-advanced-lb-automated-lab-deployment

This repo contains descriptions for two methods of installing OpenEMR:

1. A [fully Scripted method](./scriptedInstall) (except for some initial vSphere configuration)
1. An [interactive method](./interactiveInstall)
