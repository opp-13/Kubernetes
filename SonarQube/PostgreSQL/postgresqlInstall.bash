#! /bin/bash

helm repo add bitnami https://charts.bitnami.com/bitnami

  helm upgrade --install postgres bitnami/postgresql \
    --namespace db --create-namespace \
    --set global.postgresql.auth.postgresPassword=sonarPass \
    --set global.postgresql.auth.username=sonarUser \
    --set global.postgresql.auth.password=sonarPass \
    --set global.postgresql.auth.database=sonarDB \
    --set primary.persistence.enabled=true \
    --set primary.persistence.size=20Gi \
    --set primary.persistence.storageClass=nfs-client