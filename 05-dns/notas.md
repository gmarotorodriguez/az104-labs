# Lab 05 – Azure DNS: zona pública y zona privada

Ejercicio de Microsoft Learn *Creación de una zona DNS y un registro A con Azure DNS* (parte A) más un extra con zona privada (parte B). Hecho en el portal; abajo, los comandos `az` equivalentes.

## Parte A: zona DNS pública

- Zona `<ZONA_PUBLICA>.com` → se crean solos los registros **NS** (4 servidores de Azure: `.com`, `.net`, `.org`, `.info`) y **SOA**.
- Registro **A** `www` → `10.10.10.10`, TTL 1 h.
- Comprobación preguntando directamente a un servidor NS de Azure (el dominio no está delegado):

```bash
nslookup www.<ZONA_PUBLICA>.com ns1-XX.azure-dns.com   # → 10.10.10.10
```

## Parte B: zona DNS privada

- Zona privada `wwi.internal` + **vínculo de red virtual** a la VNet de la VM con **registro automático**.
- Azure crea solo el registro A `vm1` → IP privada de la VM (TTL 10 s).
- Desde la VM: `Resolve-DnsName vm1.wwi.internal` → IP privada. Desde Cloud Shell: `NXDOMAIN` (su red no está enlazada).

## Comandos equivalentes

```bash
# Pública
az network dns zone create --resource-group <RG> --name <ZONA_PUBLICA>.com
az network dns record-set a add-record --resource-group <RG> \
  --zone-name <ZONA_PUBLICA>.com --record-set-name www --ipv4-address 10.10.10.10
az network dns record-set ns show --resource-group <RG> --zone-name <ZONA_PUBLICA>.com --name @

# Privada
az network private-dns zone create --resource-group <RG> --name wwi.internal
az network private-dns link vnet create --resource-group <RG> --zone-name wwi.internal \
  --name link-vm1 --virtual-network <VNET> --registration-enabled true
az network private-dns record-set a list --resource-group <RG> --zone-name wwi.internal -o table
```

## Lecciones

- **NS** = qué servidores son **autoritativos** para la zona; el nivel superior (`.com`) los usa para **delegar**. Se configuran en el **registrador**. TTL del NS: 48 h → los cambios de delegación tardan en propagarse.
- **SOA** = datos de autoridad de la zona (servidor principal, número de serie, tiempos).
- `@` = la propia zona (*zone apex*).
- Las zonas DNS son recursos **globales** (sin región).
- **Pública**: visible desde Internet. **Privada**: solo desde las VNets enlazadas; no tiene NS porque no se delega.
- **Registro automático**: Azure crea, actualiza y borra los registros A de las VMs de la VNet enlazada. Una VNet solo puede tener registro automático en **una** zona privada, pero puede enlazarse para resolución a muchas.
- **168.63.129.16** = DNS interno de Azure; los NSG no lo bloquean.
- `NXDOMAIN` = el nombre no existe para ese servidor DNS.
- En Windows: `Resolve-DnsName` es de **PowerShell** (`PS C:\>`), no de cmd; `nslookup` funciona en ambos.
