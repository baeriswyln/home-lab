#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <namespace> <secret-name>"
  exit 1
fi

NAMESPACE="$1"
SECRET_NAME="$2"

echo "Extracting credentials from secret ${SECRET_NAME} in namespace ${NAMESPACE}..."

TOKEN=$(kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" -o jsonpath='{.data.token}' | base64 -d)

SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

KUBECONFIG_CONTENT=$(cat <<EOF
apiVersion: v1
kind: Config
clusters:
- name: cluster
  cluster:
    certificate-authority-data: ${CA}
    server: ${SERVER}
contexts:
- name: github
  context:
    cluster: cluster
    namespace: ${NAMESPACE}
    user: github-actions
current-context: github
users:
- name: github-actions
  user:
    token: ${TOKEN}
EOF
)

echo
echo "=============================="
echo "Add this value to GitHub Secret: KUBE_CONFIG"
echo "=============================="
echo

echo "$KUBECONFIG_CONTENT" | base64 -w0
echo