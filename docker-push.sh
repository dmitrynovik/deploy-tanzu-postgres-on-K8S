registry="127.0.0.1:5001"

INSTANCE_IMAGE_NAME="${registry}/postgres-instance:$(cat /home/dmitry/Downloads/postgres-for-kubernetes-v1.8.0/images/postgres-instance-tag)"
echo "PUSHING ${INSTANCE_IMAGE_NAME}"
docker tag $(cat /home/dmitry/Downloads/postgres-for-kubernetes-v1.8.0/images/postgres-instance-id) ${INSTANCE_IMAGE_NAME}
docker push ${INSTANCE_IMAGE_NAME}