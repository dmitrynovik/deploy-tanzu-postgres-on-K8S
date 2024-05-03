dbname=$(sudo kubectl -n tanzu-postgres get secret tanzu-postgres-instance-db-secret -o go-template='{{.data.dbname | base64decode}}')
username=$(sudo kubectl -n tanzu-postgres get secret tanzu-postgres-instance-db-secret -o go-template='{{.data.username | base64decode}}')
password=$(sudo kubectl -n tanzu-postgres get secret tanzu-postgres-instance-db-secret -o go-template='{{.data.password | base64decode}}')

echo "dbname: $dbname"
echo "username: $username"
echo "password: $password"


