#!/bin/bash

case "${1:linux}" in
	darwin) PRODUCT_ID=1375915;;
	linux) PRODUCT_ID=1375916;;
esac

pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.4.0-rc.8' --product-file-id=$PRODUCT_ID
mkdir tanzu
tar -xvf "tanzu-framework-darwin-amd64-v0.25.0.9.tar" -C tanzu
export TANZU_CLI_NO_INIT=true
cd tanzu
sudo install "cli/core/v0.25.0/tanzu-core-$1_amd64" /usr/local/bin/tanzu
tanzu version

tanzu plugin install --local cli all
tanzu plugin list
cd ..