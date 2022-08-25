#!/bin/sh
set -o errexit

override_file_name="operator-values-override.yaml"
namespace="tanzu-postgres"
operator_name="postgres-operator"
offline_path="/home/dmitry/Downloads"
operator_version="1.8.0"
filename="postgres-for-kubernetes-v$operator_version"

cwd=$(pwd)
cd $offline_path
cd $filename

operatorImage="$registry/postgres-operator"
postgresImage="$registry/postgres-instance"

ytt -f $override_file_name \
    --data-value-yaml operatorImage=$operatorImage \
    --data-value-yaml postgresImage=$postgresImage \
    --output-files "./out"

helm install $operator_name "./operator" \
    --values="./out/$override_file_name" \
    --namespace=$namespace \
    --wait 

cd $cwd