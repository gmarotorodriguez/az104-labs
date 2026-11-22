#!/bin/bash
# Lab 07 - Conectividad entre sitios: 3 VNets con una VM Linux cada una (sin peering todavía)
# Adaptado a Azure for Students. Cambia REGION2 si tienes otra región permitida.
set -e

RG=az104-05-rg1
REGION1=spaincentral
REGION2=switzerlandnorth          # pon aquí la segunda región permitida, si la hay
SIZE=Standard_B2ats_v2        # si falla por capacidad: Standard_B2s_v2

echo ">> Grupo de recursos"
az group create --name $RG --location $REGION1 -o none

crear() {   # $1=num  $2=región  $3=prefijo VNet  $4=prefijo subred
  echo ">> VNet az104-05-vnet$1 ($3) en $2"
  az network vnet create -g $RG -n az104-05-vnet$1 -l $2 \
    --address-prefix $3 --subnet-name subnet0 --subnet-prefix $4 -o none
  echo ">> VM az104-05-vm$1 (sin IP pública)"
  az vm create -g $RG -n az104-05-vm$1 -l $2 --image Ubuntu2204 --size $SIZE \
    --vnet-name az104-05-vnet$1 --subnet subnet0 --public-ip-address "" --nsg "" \
    --admin-username azureuser --generate-ssh-keys -o none
}

# crear 0 $REGION1 10.50.0.0/22 10.50.0.0/24
crear 1 $REGION1 10.51.0.0/22 10.51.0.0/24
crear 2 $REGION2 10.52.0.0/22 10.52.0.0/24

echo ">> IPs privadas:"
az vm list-ip-addresses -g $RG --query "[].{vm:virtualMachine.name, ip:virtualMachine.network.privateIpAddresses[0]}" -o table
