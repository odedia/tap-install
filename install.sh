#!/bin/bash

mkdir -p generated

export INSTALL_REGISTRY_HOSTNAME=registry.tanzu.vmware.com
export INSTALL_REGISTRY_USERNAME=$(cat values.yaml | grep tanzunet -A 3 | awk '/username:/ {print $2}')
export INSTALL_REGISTRY_PASSWORD=$(cat values.yaml  | grep tanzunet -A 3 | awk '/password:/ {print $2}')

kubectl create ns tap-install
tanzu secret registry add tap-registry \
  --username ${INSTALL_REGISTRY_USERNAME} --password ${INSTALL_REGISTRY_PASSWORD} \
  --server ${INSTALL_REGISTRY_HOSTNAME} \
  --export-to-all-namespaces --yes --namespace tap-install
tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.4.0-build.24 \
  --namespace tap-install
tanzu package repository get tanzu-tap-repository --namespace tap-install

ytt -f tap-values.yaml -f values.yaml --ignore-unknown-comments > generated/tap-values.yaml

DEVELOPER_NAMESPACE=$(cat values.yaml  | grep developer_namespace | awk '/developer_namespace:/ {print $2}')
kubectl create ns $DEVELOPER_NAMESPACE

tanzu package install tap -p tap.tanzu.vmware.com -v 1.4.0-build.24 --values-file generated/tap-values.yaml -n tap-install

tanzu package repository add tbs-full-deps-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:1.7.1 \
  -n tap-install

tanzu package installed update --install full-tbs-deps -p full-tbs-deps.tanzu.vmware.com -v 1.7.1 -n tap-install

# install external dns
kubectl create ns tanzu-system-ingress
ytt --ignore-unknown-comments -f values.yaml -f ingress-config/ | kubectl apply -f-

# configure developer namespace
export CONTAINER_REGISTRY_HOSTNAME=$(cat values.yaml | grep container_registry -A 3 | awk '/hostname:/ {print $2}')
export CONTAINER_REGISTRY_USERNAME=$(cat values.yaml | grep container_registry -A 3 | awk '/username:/ {print $2}')
export CONTAINER_REGISTRY_PASSWORD=$(cat values.yaml | grep container_registry -A 3 | awk '/password:/ {print $2}')
tanzu secret registry add registry-credentials --username ${CONTAINER_REGISTRY_USERNAME} --password ${CONTAINER_REGISTRY_PASSWORD} --server ${CONTAINER_REGISTRY_HOSTNAME} --namespace tap-install --export-to-all-namespaces --yes

kubectl label namespaces demos apps.tanzu.vmware.com/tap-ns=""
