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

helm install $operator_name "./operator" \
    --values="./out/$override_file_name" \
    --namespace=$namespace \
    --wait 

cd $cwd