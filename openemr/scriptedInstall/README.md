# Installing OpenEMR in vSphere with Tanzu

Description of installing OpenEMR in vSphere native Kubernetes Clusters in a fully scripted manner.

Architectural Goals:

1. MySql, Redis, and phpMyAdmin installed via Bitnami Helm charts
1. OpenEMR installed as a native Kubernetes application that can be scaled

Initially, we will start with everything in a single cluster. Later we will use two clusters - "data" and "compute" 

## Cluster Creation

Follow the steps outlined in the cluster creation section.

## Cluster Preperation

From the cluster preparation section, install the NFS server and create the `openemr` file share.

## Installation

Run the script `installOpenEMR.sh`

The script takes just a few minutes to run, but OpenEMR will not be functional until it initializes - which takes about 15 minutes.

## Teardown

Run the script `uninstallOpenEMR.sh`

Delete the `openemr` file share in your NFS server.
