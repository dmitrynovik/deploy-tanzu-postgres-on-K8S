#!/bin/sh
set -o errexit

override_file_name="operator-values-override.yaml"
namespace="tanzu-postgres"
operator_name="postgres-operator"
offline_path="/home/dmitry/Downloads"

cwd=$(pwd)
cd $offline_path

helm install $operator_name "./operator" \
    --values="./out/$override_file_name" \
    --namespace=$namespace \
    --wait 

cd $cwd