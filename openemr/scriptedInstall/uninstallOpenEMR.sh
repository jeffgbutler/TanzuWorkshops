#!/bin/bash

# Delete OpenEMR Service
kubectl delete -f 08-OpenEMRService.yml

# Delete OpenEMR Deployment
kubectl delete -f 07-OpenEMRDeployment.yml

# Delete persistent volume claims for OpenEMR
kubectl delete -f 06-OpenEMRPVC.yml

# Delete phpMyAdmin
helm uninstall openemr-phpmyadmin --namespace openemr

# Delete MariaDB (MySQL)
helm uninstall openemr-mysql --namespace openemr

# Delete Redis
helm uninstall openemr-redis --namespace openemr

# Delete openemr namespace
kubectl delete -f 01-Namespace.yml
