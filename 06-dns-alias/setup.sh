#!/bin/bash
# Lab 06 - Entorno para el registro de alias: 2 VMs web + Load Balancer Standard
# Adaptado a Azure for Students (Spain Central, sin zonas)
set -e

RG=rg-alias-lab
LOC=spaincentral
SIZE=Standard_B2ats_v2      # si da error de capacidad: Standard_B2s_v2 o Standard_B1s

echo ">> Grupo de recursos"
az group create --name $RG --location $LOC -o none

echo ">> Red virtual, subred y NSG (permitir HTTP 80)"
az network vnet create -g $RG -n vnet-web --address-prefix 10.2.0.0/16 \
  --subnet-name snet-web --subnet-prefix 10.2.0.0/24 -o none
az network nsg create -g $RG -n nsg-web -o none
az network nsg rule create -g $RG --nsg-name nsg-web -n Allow-HTTP --priority 100 \
  --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 80 -o none
az network vnet subnet update -g $RG --vnet-name vnet-web -n snet-web --network-security-group nsg-web -o none

echo ">> IP pública y Load Balancer Standard"
az network public-ip create -g $RG -n myPublicIP --sku Standard -o none
az network lb create -g $RG -n myLoadBalancer --sku Standard --public-ip-address myPublicIP \
  --frontend-ip-name fe-web --backend-pool-name be-web -o none
az network lb probe create -g $RG --lb-name myLoadBalancer -n probe-http \
  --protocol Http --port 80 --path / -o none
az network lb rule create -g $RG --lb-name myLoadBalancer -n rule-http --protocol Tcp \
  --frontend-port 80 --backend-port 80 --frontend-ip-name fe-web --backend-pool-name be-web \
  --probe-name probe-http --disable-outbound-snat true -o none
az network lb outbound-rule create -g $RG --lb-name myLoadBalancer -n outbound-web \
  --frontend-ip-configs fe-web --protocol All --address-pool be-web -o none

echo ">> cloud-init: instala nginx y una página con el nombre de la VM"
cat > cloud-init.txt <<'CI'
#cloud-config
packages:
  - nginx
runcmd:
  - echo "<h1>Hola desde $(hostname)</h1>" > /var/www/html/index.html
CI

for i in 1 2; do
  echo ">> NIC y VM webVM$i"
  az network nic create -g $RG -n nic-webVM$i --vnet-name vnet-web --subnet snet-web \
    --lb-name myLoadBalancer --lb-address-pools be-web -o none
  az vm create -g $RG -n webVM$i --image Ubuntu2204 --size $SIZE --nics nic-webVM$i \
    --admin-username azureuser --generate-ssh-keys --custom-data cloud-init.txt -o none
done

echo ">> IP pública del balanceador:"
az network public-ip show -g $RG -n myPublicIP --query ipAddress -o tsv
