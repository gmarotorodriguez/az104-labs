# Lab 08 – Rutas personalizadas (UDR) y aplicación virtual de red (NVA)

Módulo de Microsoft Learn *Administración y control del flujo de tráfico con rutas* (tres ejercicios: rutas personalizadas, NVA y máquinas virtuales, y enrutamiento a través de la NVA). Adaptado a Azure for Students: Spain Central, tamaño `Standard_B2s_v2` y claves SSH en lugar de contraseñas.

## Arquitectura

| Subred | Prefijo | Tabla de rutas | VM |
|---|---|---|---|
| publicsubnet | 10.0.0.0/24 | `publictable`: 10.0.1.0/24 → VirtualAppliance 10.0.2.4 | public (10.0.0.4) |
| privatesubnet | 10.0.1.0/24 | — (rutas del sistema) | private (10.0.1.4) |
| dmzsubnet | 10.0.2.0/24 | — | nva (10.0.2.4, reenvío IP activado) |

VNet `vnet` 10.0.0.0/16, grupo de recursos `rg-rutas-lab`.

## Comandos clave

```bash
RG=rg-rutas-lab
az group create --name $RG --location spaincentral

# Tabla de rutas y ruta personalizada
az network route-table create --name publictable -g $RG --disable-bgp-route-propagation false
az network route-table route create --route-table-name publictable -g $RG --name productionsubnet \
  --address-prefix 10.0.1.0/24 --next-hop-type VirtualAppliance --next-hop-ip-address 10.0.2.4

# Red y subredes
az network vnet create --name vnet -g $RG --address-prefixes 10.0.0.0/16 \
  --subnet-name publicsubnet --subnet-prefixes 10.0.0.0/24
az network vnet subnet create --name privatesubnet --vnet-name vnet -g $RG --address-prefixes 10.0.1.0/24
az network vnet subnet create --name dmzsubnet --vnet-name vnet -g $RG --address-prefixes 10.0.2.0/24
az network vnet subnet update --name publicsubnet --vnet-name vnet -g $RG --route-table publictable

# NVA con IP fija y reenvío IP (en la NIC de Azure y en Linux)
az vm create -g $RG --name nva --vnet-name vnet --subnet dmzsubnet --image Ubuntu2204 \
  --size Standard_B2s_v2 --private-ip-address 10.0.2.4 --admin-username azureuser --generate-ssh-keys
az network nic update --name nvaVMNic -g $RG --ip-forwarding true
ssh azureuser@<IP_PUBLICA_NVA> 'sudo sysctl -w net.ipv4.ip_forward=1'

# VMs de prueba con traceroute instalado por cloud-init
for vm in public private; do
  az vm create -g $RG --name $vm --vnet-name vnet --subnet ${vm}subnet --image Ubuntu2204 \
    --size Standard_B2s_v2 --admin-username azureuser --generate-ssh-keys \
    --custom-data cloud-init.txt --no-wait
done

ssh azureuser@<IP_PUBLICA_public> 'traceroute private --type=icmp'   # 10.0.2.4 → 10.0.1.4
ssh azureuser@<IP_PUBLICA_private> 'traceroute public --type=icmp'   # 10.0.0.4 directo

az group delete --name $RG --yes --no-wait
```

## Lecciones

- Una **UDR** gana a la ruta del sistema y solo afecta al tráfico que **sale** de la subred a la que se asocia la tabla.
- Tipos de siguiente salto: **VirtualAppliance** (firewall/NVA), **VirtualNetworkGateway** (VPN/ExpressRoute), **Internet**, **VnetLocal**, **None** (descartar).
- **BGP**: protocolo con el que los routers anuncian qué redes conocen; con VPN/ExpressRoute, Azure aprende así las rutas de la red local. `--disable-bgp-route-propagation true` (*Propagar rutas de puerta de enlace: No*) impide que esas rutas lleguen a la subred.
- **NVA** = VM que actúa como dispositivo de red (firewall, router, proxy); alternativa a Azure Firewall.
- Una NVA necesita **reenvío IP en dos niveles**: en la **NIC de Azure** (aceptar paquetes no dirigidos a su IP) y en el **sistema operativo** (`net.ipv4.ip_forward=1`, reenviarlos). `sysctl -w` no persiste tras reiniciar (`/etc/sysctl.conf`).
- `traceroute` confirma la ruta: public → private pasa por la NVA; private → public va directo → **enrutamiento asimétrico**. Con un firewall con estado haría falta otra UDR en `privatesubnet`.
- Las subredes nuevas tienen `DefaultOutboundAccess: false` (retirada del acceso de salida predeterminado): para salir a Internet hace falta IP pública, NAT Gateway, balanceador con regla de salida o firewall.
- Las VMs de una misma VNet se resuelven por nombre con el DNS interno de Azure (`*.internal.cloudapp.net`).
