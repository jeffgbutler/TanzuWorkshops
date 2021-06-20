# Installing OpenEMR in vSphere with Tanzu

Description of installing OpenEMR in vSphere native Kubernetes Clusters in a fully scripted manner.

Architectural Goals:

1. MySql, Redis, and phpMyAdmin installed via Bitnami Helm charts
1. OpenEMR installed as a native Kubernetes application that can be scaled

Initially, we will start with everything in a single cluster. Later we will use two clusters - "data" and "compute"

## Prerequisites

- You must have access to a Kubernetes cluster. If you are using Tanzu on vSphere you can follow the steps outlined
  in the [cluster creation](../clusterCreation) section.
- The cluster must have a storage class named `nfs-external` that supports access mode of `ReadWriteMany`. You can
  follow the steps in the [create NFS provisioner](../createNFS) section for details on how to accomplish this
  with vSAN on vSphere

## Installation

Run the script `installOpenEMR.sh`

The script takes just a few minutes to run, but OpenEMR will not be functional until it initializes - which takes about 15 minutes.

## Teardown

Run the script `uninstallOpenEMR.sh`

Delete the `openemr` file share in your NFS server.
