# Helm installation

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

-- > copia il file nginx-helm_values.yml dal repo <--

helm install helmed oci://registry-1.docker.io/bitnamicharts/nginx -f nginx-helm_values.yml