# Lab 06 – Registro de alias en el vértice de la zona (Azure DNS + Load Balancer)

Ejercicio de Microsoft Learn *Creación de registros de alias para Azure DNS*. El script de Learn se sustituyó por `setup.sh`, adaptado a Azure for Students (Spain Central, sin zonas).

## Qué se hizo

1. `setup.sh`: VNet + subred + NSG (permitir TCP 80), IP pública Standard, **Load Balancer Standard** (front-end, back-end, sondeo HTTP, regla TCP 80 y regla de salida) y dos VMs Ubuntu con **nginx instalado por cloud-init**.
2. Comprobación del reparto con `curl` en bucle: responden `webVM1` y `webVM2`.
3. Zona DNS pública y **registro A de alias en el vértice (`@`)** apuntando al recurso `myPublicIP`.
4. `nslookup` de la zona (sin `www`) → devuelve la IP del balanceador.

## Comandos clave

```bash
bash setup.sh
IP=$(az network public-ip show -g rg-alias-lab -n myPublicIP --query ipAddress -o tsv)
for i in 1 2 3 4 5 6; do curl -s http://$IP; echo; done

az network dns zone create -g rg-alias-lab -n <ZONA>.com
az network dns record-set a create -g rg-alias-lab -z <ZONA>.com -n "@" \
  --target-resource $(az network public-ip show -g rg-alias-lab -n myPublicIP --query id -o tsv)
nslookup <ZONA>.com ns1-XX.azure-dns.com

az group delete --name rg-alias-lab --yes --no-wait
```

## Lecciones

- **Registro de alias**: un registro A/AAAA/CNAME cuyo valor sale de un **recurso de Azure** (IP pública, Traffic Manager, Front Door, CDN) o de **otro conjunto de registros de la zona**. Se actualiza solo si cambia la IP y evita registros colgados al borrar el recurso.
- En el **vértice** de una zona **no se permite CNAME** → para apuntar el dominio raíz a un balanceador, Traffic Manager o Front Door se usa un **alias**.
- **A** = IPv4, **AAAA** = IPv6, **CNAME** = otro nombre de host.
- Load Balancer: **front-end** (IP de entrada) → **regla** (qué puerto se reparte) → **back-end** (NIC de las VMs); el **sondeo** decide qué VMs están sanas (disponibilidad).
- Balanceador e IP pública **Standard** = cerrados por defecto → hace falta un **NSG** que permita el tráfico. Sin IP pública propia, las VMs salen a Internet con una **regla de salida** (SNAT).
- Reparto por **hash de 5 elementos**, no por turnos: con pocas peticiones sale desigual.
- **cloud-init** = configuración de VMs Linux en el **primer arranque** (`--custom-data`).
- En Bash, `<ALGO>` en la documentación es un marcador: se sustituye **sin** los símbolos `< >` (que son redirecciones).
