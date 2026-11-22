# az104-labs

Laboratorios prácticos de preparación del examen Microsoft AZ-104 (Azure Administrator). Cada carpeta incluye los archivos del laboratorio y un `notas.md` con los pasos, los errores encontrados y lo aprendido.

## Laboratorios

| # | Laboratorio | Contenido |
|---|---|---|
| 01 | [Plantilla ARM](01-plantilla-arm) | Cuenta de almacenamiento con parámetros y salidas, desplegada desde Azure Cloud Shell |
| 02 | [Azure Policy](02-azure-policy) | Ubicaciones permitidas, directiva personalizada de etiqueta (Audit y Deny), efecto Modify con tarea de corrección e identidad administrada, iniciativa, exención y limpieza |
| 03 | [Redes virtuales](03-redes-virtuales) | Hub-and-spoke con Bicep: dos VNets, subredes y peering en los dos sentidos, con what-if previo |
| 04 | [NSG](04-nsg) | Grupos de seguridad de red: reglas predeterminadas, RDP solo desde mi IP, denegar salida a Internet y comportamiento con estado |
| 05 | [Azure DNS](05-dns) | Zona pública con registro A y comprobación con nslookup; zona privada con vínculo de red y registro automático de VMs |
| 06 | [Alias DNS + Load Balancer](06-dns-alias) | Script con Load Balancer Standard, dos VMs con nginx (cloud-init) y registro de alias en el vértice de la zona |
| 07 | [Conectividad entre sitios](07-conectividad-sitios) | Tres VNets en dos regiones, peering regional y global, Network Watcher, Ejecutar comando y ruta personalizada (UDR) |

Repositorio en curso: añado laboratorios a medida que avanzo en el temario.
