set -eo pipefail

# Parameters with default values (can override):
serviceaccount=rabbitmq
namespace="tanzu-postgres"
kubectl=kubectl
registry="registry.tanzu.vmware.com"
operator_version="1.8.0"
gemfire_version="9.15.0"
cluster_name="gemfire-cluster"
install_helm=1
install_cert_manager=1
create_registry_secret=1
install_operator=1
servers=1
storage=1Gi
storageclassname=""
wait_pod_timeout=60s
cert_manager_version=1.9.1
operator_name="postgres-operator"
unpack_to_dir="/tmp"

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

if [ -z $storageclassname ]; then persistent=0; else persistent=1; fi

echo "CREATE NAMESPACE $namespace if it does not exist..."
$kubectl create namespace $namespace --dry-run=client -o yaml | $kubectl apply -f-

if [ $install_helm -eq 1 ]
then
     echo "INSTALL HELM"
     curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
     chmod +x get_helm.sh
     ./get_helm.sh
fi

if [ $install_cert_manager -eq 1 ]
then
     $kubectl create namespace cert-manager
     helm repo add jetstack https://charts.jetstack.io
     helm repo update
     helm install cert-manager jetstack/cert-manager --namespace cert-manager  --version $cert_manager_version --set installCRDs=true
     $kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v$cert_manager_version/cert-manager.yaml
fi

if [ $create_registry_secret -eq 1 ]
then
     echo "CREATE DOCKER REGISTRY SECRET"
     $kubectl create secret docker-registry image-pull-secret --namespace=$namespace --docker-server=$registry \
          --docker-username="$vmwareuser" --docker-password="$vmwarepassword" --dry-run=client -o yaml \
          | $kubectl apply -f-
fi

if [ $install_operator -eq 1 ]
then
    echo "CONNECTING TO REGISTRY: $registry"
    export HELM_EXPERIMENTAL_OCI=1
    helm registry login -u $vmwareuser -p $vmwarepassword $registry
    helm pull "oci://$registry/tanzu-sql-postgres/postgres-operator-chart" --version v$operator_version --untar --untardir $unpack_to_dir

    echo "INSTALL POSTGRES OPERATOR"
    #set +e
    helm install $operator_name $unpack_to_dir/postgres-operator/ --wait --namespace $namespace
    helm ls --namespace $namespace
    #set -eo pipefail
fi

exit 1

# echo "WAIT FOR gemfire-controller-manager TO BE READY"
# $kubectl wait pods -n $namespace -l app.kubernetes.io/component=gemfire-controller-manager \
#      --for condition=Ready --timeout $wait_pod_timeout
# sleep 10

echo "CREATE $clustername CLUSTER"
ytt -f gemfire-crd.yml \
     --data-value-yaml cluster_name=$cluster_name \
     --data-value-yaml image="registry.tanzu.vmware.com/pivotal-gemfire/vmware-gemfire:$gemfire_version" \
     --data-value-yaml servers=$servers \
     --data-value-yaml storage=$storage \
     --data-value-yaml storageclassname=$storageclassname \
     --data-value-yaml persistent=$persistent \
     | $kubectl --namespace=$namespace apply -f-

$kubectl -n $namespace get GemFireClusters




