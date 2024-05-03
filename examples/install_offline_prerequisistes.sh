kubectl=kubectl
cert_manager_version=1.9.1

echo "INSTALL HELM"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh

echo "INSTALL CERT-MANAGER"
sudo $kubectl create namespace cert-manager --dry-run=client -o yaml | $kubectl apply -f-
sudo helm repo add jetstack https://charts.jetstack.io
sudo helm repo update
sudo helm install cert-manager jetstack/cert-manager --namespace cert-manager  --version $cert_manager_version --set installCRDs=true
sudo $kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v$cert_manager_version/cert-manager.yaml

