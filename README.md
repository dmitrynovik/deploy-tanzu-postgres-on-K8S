# Deployment script for installation of Tanzu Postgres for Kubernetes

## To make this work, you must have:
- *NIX Operating System
- `kubectl` utility pointing to K8S cluster
- `carvel/ytt` installed
## Online option
Pass `registry_user` and `registry_password` parameters. Also, `--offline 0`
Example:
```
./install.sh --registry_user USER --registry_password PASS --offline 0
```
It installs
* Helm (if N/A)
* Cert-manager (if N/A)
* Postgres operator
* Creates postgres instance

## Offline option
### Prerequisistes
* Helm 
* Cert-manager
* Tar CLI (to run `tar -xvf`)
* Downloaded archive file e.g. `postgres-for-kubernetes-v1.8.0.tar.gz`
* Local registry

Pass `--offline 1`, `--registry <REGIDTRY URL>`, `--offline_path` and `--filename_with_extension`
  Example:
  ```
  ./install.sh --registry "localhost:5001" --offline_path "/home/dmitry/Downloads" --filename_with_extension "postgres-for-kubernetes-v1.8.0.tar.gz" --registry_user USER --registry_password PASS
  ```

## Production
Override `cpu`, `memory` and `backup_location` (see below).

## Optional parameters
| Parameter | Default Value | Meaning |
|:----------|:--------------|:--------|
|namespace  | tanzu-postgres| The namespace to install Tanzu Postgres |
|kubectl    | kubectl       | Pass `--kubectl oc` to install on OpenShift (experimental) |
|registry   | registry.tanzu.vmware.com | Image registry. Override if installing in air-gapped environment. |
|instance_name | tanzu-postgres-instance | |
| operator_version | `1.8.0` | |
| postgres_version | `1.8.0` | |
| install_helm | 1 | in online installation, pass `1` to install Helm |
| install_cert_manager | 1 | in online installation, pass `1` to install Cert Manager |
| create_registry_secret| 1 | `1` if to create private registry secret to download image  |
| install_operator| 1 | `1` if to install Postgres K8S operator  |
| storage_size | 1G | |
| storage_class_name | `standard`| |
| storage_size | 1G | |
| cpu | 0.8 | |
| memory | 800Mi |
| backup_location | `N/A`| |
| service_type | `ClusterIP` | |
| log_level | `N/A` | Pass `Debug` to log logs |
| certificate_secret_name | `N/A` | |
| cert_manager_version | `1.9.1` | |
| operator_name | `postgres-operator` | The name of Postgres operator Helm Chart |
| unpack_to_dir | `/tmp` | |
| offline | `1` | Pass `1` for the air-gapped environment |
| offline_path | `~/Downloads` | If air-gapped, where to look for archive file |
| filename_with_extension | The full file name of the archive |
| push_images_to_private_registry | `1` | If offline, whether to push images to private registry (default: `Yes`) |
| high_availability | `1` | If to create HA mirror |