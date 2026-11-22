# Lab 07 – Conectividad entre sitios: peering regional y global, Network Watcher y rutas personalizadas

Ejercicio de Microsoft Learn *Implementación de la conectividad entre sitios* (lab 05 oficial del AZ-104), adaptado a Azure for Students: VMs Linux (puerto 22 en lugar de 3389) y regiones permitidas por la directiva de la suscripción.

## Arquitectura

| VNet | Región | Espacio | Subred | VM |
|---|---|---|---|---|
| az104-05-vnet0 | Spain Central | 10.50.0.0/22 | 10.50.0.0/24 | az104-05-vm0 (10.50.0.4) |
| az104-05-vnet1 | Spain Central | 10.51.0.0/22 | 10.51.0.0/24 | az104-05-vm1 (10.51.0.4) |
| az104-05-vnet2 | Poland Central | 10.52.0.0/22 | 10.52.0.0/24 | az104-05-vm2 (10.52.0.4) |

## Pasos y resultados

1. `setup-intersite.sh`: 3 VNets + 3 VMs Ubuntu sin IP pública.
2. **Network Watcher → Solución de problemas de conexión** vm0 → 10.51.0.4:22 **sin peering**: *Inaccesible*, próximo salto *Ninguno*, NSG saliente *Denegar* (la IP no pertenece a `VirtualNetwork`).
3. **Peerings**: vnet0↔vnet1 (regional, desde el portal, que crea los dos sentidos) y vnet0↔vnet2, vnet1↔vnet2 (**globales**, por CLI). Estado `Connected`, *Totalmente sincronizado*.
4. **Ejecutar comando** (RunShellScript) en vm0: `nc -zv -w 3 <IP> 22` → conecta con vm1 y vm2.
5. **Ruta personalizada (UDR)** en subnet0 de vnet0: `10.52.0.0/22` → *VirtualAppliance* `10.50.0.100` (sin NVA real). **Próximo salto** muestra la tabla `rt-vnet0`, y vm0 ya no llega a vm2 (timeout); vm1 sigue accesible.

## Comandos clave

```bash
# Regiones permitidas por la directiva de la suscripción
az policy assignment list --query "[].{nombre:displayName, regiones:parameters.listOfAllowedLocations.value}" -o json

# Peering global (un sentido; repetir en el otro)
az network vnet peering create -g az104-05-rg1 -n vnet0-to-vnet2 --vnet-name az104-05-vnet0 \
  --remote-vnet az104-05-vnet2 --allow-vnet-access --allow-forwarded-traffic

# Probar desde dentro de la VM sin conectarse a ella
az vm run-command invoke -g az104-05-rg1 -n az104-05-vm0 --command-id RunShellScript \
  --scripts "nc -zv -w 3 10.52.0.4 22"

# Ruta personalizada
az network route-table create -g az104-05-rg1 -n rt-vnet0
az network route-table route create -g az104-05-rg1 --route-table-name rt-vnet0 -n a-vnet2-por-nva \
  --address-prefix 10.52.0.0/22 --next-hop-type VirtualAppliance --next-hop-ip-address 10.50.0.100
az network vnet subnet update -g az104-05-rg1 --vnet-name az104-05-vnet0 -n subnet0 --route-table rt-vnet0

az group delete --name az104-05-rg1 --yes --no-wait
```

Equivalente en PowerShell (Windows): `Invoke-AzVMRunCommand -ResourceGroupName az104-05-rg1 -VMName az104-05-vm0 -CommandId RunPowerShellScript -ScriptString 'Test-NetConnection 10.51.0.4 -Port 3389'`

## Lecciones

- Dos VNets sin peering no tienen ruta entre sí (próximo salto *Ninguno*), aunque estén en la misma región.
- Peering regional y **global** se configuran igual; ambos usan la red troncal de Microsoft e IPs privadas. No es transitivo.
- Con peering, el rango remoto pasa a formar parte de la etiqueta `VirtualNetwork` (regla AllowVnetOutBound 65000).
- **Network Watcher**: uno por región (NetworkWatcherRG). Herramientas: solución de problemas de conexión, comprobación de flujo de IP, próximo salto, captura de paquetes, registros de flujo.
- **Ejecutar comando** permite lanzar scripts en VMs sin IP pública ni conexión RDP/SSH.
- **UDR > ruta del sistema** (incluida la del peering). Si el siguiente salto no existe, el tráfico se descarta. *Próximo salto* indica qué tabla se aplica.
- Errores de capacidad: `SkuNotAvailable` (tamaño no disponible en la región) y `ZonalAllocationFailed` → otro tamaño u otra región. Dos recursos no pueden llamarse igual en el mismo RG aunque estén en regiones distintas.
- Cancelar la espera de un comando `az` (*Long-running operation wait cancelled*) **no** cancela la operación en Azure.
