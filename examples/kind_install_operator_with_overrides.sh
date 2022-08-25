#!/bin/sh
set -o errexit

override_file_name="operator-values-override.yaml"
namespace="tanzu-postgres"
operator_name="postgres-operator"

helm install $operator_name "./operator" \
    --values="./out/$override_file_name" \
    --namespace=$namespace \
    --wait 