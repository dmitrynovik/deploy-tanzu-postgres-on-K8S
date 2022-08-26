#!/bin/bash  
set -eo pipefail

# Parameters with default values (can override):
serviceaccount=rabbitmq
namespace="tanzu-postgres"
kubectl=kubectl
registry="registry.tanzu.vmware.com"
operator_version="1.8.0"
postgres_version=$operator_version
instance_name="tanzu-postgres-instance"
install_helm=1
install_cert_manager=1
create_registry_secret=1
install_operator=1
servers=1
storage_size=1G
storage_class_name="standard"
cpu=0.8
memory=800Mi
backup_location=""
service_type=ClusterIP
log_level=""
certificate_secret_name=""

wait_pod_timeout=120s
cert_manager_version=1.9.1
operator_name="postgres-operator"
unpack_to_dir="/tmp"
offline=1
offline_path="~/Downloads"
filename="postgres-for-kubernetes-v$operator_version"
filename_with_extension="$filename.tar.gz"
push_images_to_local_registry=1
high_availability=1

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

case $kubectl in
    "oc") openshift=1 ;;
    *) openshift=0 ;;
esac

if [ -z $vmwareuser ]
then
     echo "vmwareuser not set"
     exit 1
fi

if [ -z $vmwarepassword ] 
then
     echo "vmwarepassword not set"
     exit 1
fi

echo "CREATE NAMESPACE $namespace if it does not exist..."
$kubectl create namespace $namespace --dry-run=client -o yaml | $kubectl apply -f-

if [ $create_registry_secret -eq 1 ]
then
     echo "CREATE DOCKER REGISTRY SECRET"
     $kubectl create secret docker-registry regsecret --namespace=$namespace --docker-server=$registry \
          --docker-username="$vmwareuser" --docker-password="$vmwarepassword" --dry-run=client -o yaml \
          | $kubectl apply -f-
fi

if [ $offline -ne 1 ]
then
     postgresImage="registry.tanzu.vmware.com/tanzu-sql-postgres/postgres-instance:$postgres_version"

     if [ $install_helm -eq 1 ]
     then
          echo "INSTALL HELM"
          curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
          chmod +x get_helm.sh
          ./get_helm.sh
     fi

     if [ $install_cert_manager -eq 1 ]
     then
          echo "INSTALL CERT-MANAGER"
          $kubectl create namespace cert-manager --dry-run=client -o yaml | $kubectl apply -f-
          helm repo add jetstack https://charts.jetstack.io
          helm repo update
          helm install cert-manager jetstack/cert-manager --namespace cert-manager  --version $cert_manager_version --set installCRDs=true
          $kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v$cert_manager_version/cert-manager.yaml
     fi

     if [ $install_operator -eq 1 ]
     then
          echo "CONNECTING TO REGISTRY: $registry"
          export HELM_EXPERIMENTAL_OCI=1
          helm registry login -u $vmwareuser -p $vmwarepassword $registry
          tmp_dir="$unpack_to_dir/postgres-operator-chart"
          if [[ -d $tmp_dir ]] ; then
               rm -rf $tmp_dir
          fi
          helm pull "oci://$registry/tanzu-sql-postgres/postgres-operator-chart" --version v$operator_version --untar --untardir $unpack_to_dir

          echo "INSTALL POSTGRES OPERATOR"
          helm install $operator_name $unpack_to_dir/postgres-operator/ --wait --namespace $namespace
          helm ls --namespace $namespace
          sleep 10
     fi

else
     # offline installation
     operatorImage="$registry/postgres-operator:v$operator_version"
     postgresImage="$registry/postgres-instance:v$postgres_version"

     if [ $push_images_to_local_registry -eq 1 ]
     then
          cwd=$(pwd)
          cd $offline_path

          echo "UNZIPPING ARCHIVE: $filename_with_extension"
          if [[ ! -f $filename_with_extension ]] ; then
               echo "ERROR: FILE $filename_with_extension MISSING!"
               exit 1
          fi
          tar xzf $filename_with_extension
          cd $filename

          echo "LOADING POSTGRES IMAGE..."
          docker load -i ./images/postgres-instance
          
          echo "LOADING POSTGRES K8S OPERATOR IMAGE..."
          docker load -i ./images/postgres-operator

          echo "VERIFYING IMAGES:"
          docker images "postgres-*"

          INSTANCE_IMAGE_NAME="${registry}/postgres-instance:$(cat ./images/postgres-instance-tag)"
          echo "PUSHING ${INSTANCE_IMAGE_NAME} to $registry"
          docker tag $(cat ./images/postgres-instance-id) ${INSTANCE_IMAGE_NAME}
          docker push ${INSTANCE_IMAGE_NAME}

          OPERATOR_IMAGE_NAME="${registry}/postgres-operator:$(cat ./images/postgres-operator-tag)"
          echo "PUSHING ${OPERATOR_IMAGE_NAME} to $registry"
          docker tag $(cat ./images/postgres-operator-id) ${OPERATOR_IMAGE_NAME}
          docker push ${OPERATOR_IMAGE_NAME}
     fi

     if [ $install_operator -eq 1 ]
     then
          echo "INSTALL POSTGRES OPERATOR"
          override_file_name="operator-values-override.yaml"
          cp "$cwd/$override_file_name" ./

          ytt -f $override_file_name \
               --data-value-yaml operatorImage=$operatorImage \
               --data-value-yaml postgresImage=$postgresImage \
               --output-files "./out"

          helm install $operator_name "./operator" \
               --values="./out/$override_file_name" \
               --namespace=$namespace \
               --wait 

          helm ls --namespace $namespace
          $kubectl get serviceaccount
          cd $cwd
          sleep 10
     fi
fi

echo "CREATE $clustername CLUSTER"
ytt -f postgres-crd.yml \
     --data-value-yaml backup_location=$backup_location \
     --data-value-yaml certificate_secret_name=$certificate_secret_name \
     --data-value-yaml storage_class_name=$storage_class_name \
     --data-value-yaml storage_size=$storage_size \
     --data-value-yaml cpu=$cpu \
     --data-value-yaml memory=$memory \
     --data-value-yaml instance_name=$instance_name \
     --data-value-yaml image=$postgresImage \
     --data-value-yaml high_availability=$high_availability \
     --data-value-yaml service_type=$service_type \
     --data-value-yaml log_level=$log_level \
     --data-value-yaml servers=$servers \
     | $kubectl --namespace=$namespace apply -f-

$kubectl -n $namespace get postgres $instance_name -o yaml

