# Lab 04 – Grupos de seguridad de red (NSG)

Ejercicio de Microsoft Learn *Implementación de grupos de seguridad de red*. Hecho en el portal; abajo, los comandos `az` equivalentes.

## Escenario

1. VM Windows `vm1` **sin NSG** y sin puertos de entrada → el RDP **no conecta** (IP pública Standard = cerrada por defecto).
2. NSG `nsg-vm1` asociado a la **subred** de la VM.
3. Regla de entrada **prioridad 300**: permitir RDP (TCP 3389) **solo desde mi IP** → el RDP conecta.
4. Regla de salida **prioridad 4000**: denegar la etiqueta de servicio **Internet** → la VM deja de navegar, pero la sesión RDP sigue viva (NSG con estado).

## Comandos equivalentes

```bash
az group create --name rg-nsg-lab --location spaincentral

# VM sin zona (en Spain Central los tamaños B con zona daban ZonalAllocationFailed)
az vm create --resource-group rg-nsg-lab --name vm1 \
  --image MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest \
  --size Standard_B2s_v2 --admin-username localadmin \
  --public-ip-sku Standard --nsg ""

az network nsg create --resource-group rg-nsg-lab --name nsg-vm1 --location spaincentral

az network vnet subnet update --resource-group rg-nsg-lab \
  --vnet-name <VNET> --name <SUBNET> --network-security-group nsg-vm1

az network nsg rule create --resource-group rg-nsg-lab --nsg-name nsg-vm1 \
  --name Allow-RDP-MiIP --priority 300 --direction Inbound --access Allow \
  --protocol Tcp --source-address-prefixes <MI_IP> --destination-port-ranges 3389

az network nsg rule create --resource-group rg-nsg-lab --nsg-name nsg-vm1 \
  --name Deny-Internet-Out --priority 4000 --direction Outbound --access Deny \
  --protocol '*' --destination-address-prefixes Internet --destination-port-ranges '*'

az group delete --name rg-nsg-lab --yes --no-wait
```

## Reglas predeterminadas (no se pueden borrar, sí anular con prioridad menor)

| Sentido | Prioridad | Regla | Efecto |
|---|---|---|---|
| Entrada | 65000 | AllowVnetInBound | Tráfico dentro de la VNet y redes emparejadas |
| Entrada | 65001 | AllowAzureLoadBalancerInBound | Sondeos del Load Balancer |
| Entrada | 65500 | DenyAllInBound | Todo lo demás, denegado |
| Salida | 65000 | AllowVnetOutBound | Tráfico hacia la VNet |
| Salida | 65001 | AllowInternetOutBound | Salida a Internet |
| Salida | 65500 | DenyAllOutBound | Todo lo demás, denegado |

## Lecciones

- Prioridad 100–4096 para reglas propias; **número más bajo = se evalúa antes**; la primera que coincide gana.
- NSG **con estado**: la respuesta a una conexión permitida no necesita regla en el otro sentido.
- `Internet`, `VirtualNetwork`, `AzureLoadBalancer` son **etiquetas de servicio**, mantenidas por Microsoft.
- **IP pública Standard**: cerrada por defecto (la Basic se retiró en 2025).
- Abrir RDP a *Cualquiera* es mala práctica: mejor **mi IP**, **Azure Bastion** o **JIT**.
- Las conexiones ya establecidas y la **caché del navegador** pueden engañar al probar una regla: probar con conexiones nuevas (`Test-NetConnection`).
- `ZonalAllocationFailed` = falta de capacidad en esa zona → probar **sin zona**, otra zona u otro tamaño.
