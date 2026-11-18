# Lab 03 – Redes virtuales hub-and-spoke con Bicep

Ejercicio de Microsoft Learn *Creación y configuración de redes virtuales*, desplegado como código (Bicep) en lugar de con el portal.

## Arquitectura

| Red virtual | Espacio de direcciones | Subredes |
|---|---|---|
| hub-vnet | 10.0.0.0/16 | AzureFirewallSubnet → 10.0.0.0/26 |
| app-vnet | 10.1.0.0/16 | frontend → 10.1.0.0/24 · backend → 10.1.1.0/24 |

Peering en los dos sentidos (`app-to-hub` y `hub-to-app`), con acceso entre redes y tráfico reenviado permitido.

## Comandos clave

```bash
az group create --name rg-redes-lab --location spaincentral
az bicep build --file main.bicep --stdout > /dev/null && echo "PLANTILLA OK"
az deployment group what-if --resource-group rg-redes-lab --template-file main.bicep
az deployment group create --resource-group rg-redes-lab --template-file main.bicep
az network vnet peering list --resource-group rg-redes-lab --vnet-name app-vnet -o table
az group delete --name rg-redes-lab --yes --no-wait
```

## Lecciones

- **Bicep** = sintaxis más legible que ARM JSON; se compila a ARM JSON. Admite comentarios (`//`).
- **Nombre simbólico** (`hubVnet`) = referencia interna de la plantilla; **`name`** = nombre real en Azure. Bicep deduce las dependencias a partir de las referencias (`hubVnet.id`).
- **Imperativo** (comandos `az` uno a uno) frente a **declarativo** (plantilla: describes el estado final).
- **what-if** muestra qué se creará, modificará o eliminará antes de desplegar.
- El peering es **entre redes virtuales**, se configura **en los dos sentidos** (estado `Initiated` → `Connected`), no es transitivo y exige rangos que **no se solapen**.
- Subredes con nombre obligatorio: `AzureFirewallSubnet` (≥ /26), `AzureBastionSubnet` (≥ /26), `GatewaySubnet` (/27 recomendado).
- Azure reserva **5 IPs por subred** (.0 red, .1 puerta de enlace, .2 y .3 DNS, última difusión): una /24 deja 251 utilizables; la subred mínima es /29.
- Hub-and-spoke: servicios compartidos (firewall, VPN, Bastion) en el hub; aplicaciones en los spokes.
