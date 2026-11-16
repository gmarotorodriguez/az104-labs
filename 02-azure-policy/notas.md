# Lab 02 – Azure Policy como código

## Bloque 1: Deny de ubicaciones y directiva personalizada de etiquetas

### Qué se hizo
1. Grupo de recursos `rg-policy-lab` en Spain Central.
2. Asignación de la directiva integrada **Allowed locations** (solo `spaincentral`) con efecto Deny.
3. Definición personalizada `exigir-etiqueta-entorno` (`regla.json` + `parametros.json`), con el efecto como parámetro (Audit / Deny / Disabled).
4. Asignación en modo **Audit** → recurso sin etiqueta creado, pero marcado como **no conforme**.
5. Misma definición reasignada en modo **Deny** → recurso sin etiqueta **bloqueado** (`RequestDisallowedByPolicy`); con `--tags entorno=dev` se crea.
6. Informe de cumplimiento: 1 recurso no conforme (el creado en Audit). Deny no modifica recursos existentes.

### Comandos clave
```bash
RG_ID=$(az group show --name rg-policy-lab --query id -o tsv)

az policy assignment create --name ubicaciones-permitidas \
  --policy e56962a6-4747-49cd-b67b-bf8b01975c4c --scope $RG_ID \
  --params '{"listOfAllowedLocations":{"value":["spaincentral"]}}'

az policy definition create --name exigir-etiqueta-entorno \
  --rules regla.json --params parametros.json --mode Indexed

az policy assignment create --name exigir-entorno \
  --policy exigir-etiqueta-entorno --scope $RG_ID \
  --params '{"efecto":{"value":"Deny"}}'

az provider register --namespace Microsoft.PolicyInsights
az policy state trigger-scan --resource-group rg-policy-lab --no-wait
az policy state summarize --resource-group rg-policy-lab
```

### Lecciones
- **Definición** = la regla; **asignación** = aplicarla a un ámbito con unos parámetros.
- Varias directivas se evalúan todas: si cualquiera deniega, se deniega (las listas de regiones permitidas se cruzan).
- `RequestDisallowedByAzure` = directiva de Microsoft (Azure for Students); `RequestDisallowedByPolicy` = directiva propia.
- Buena práctica: primero **Audit** para medir, luego **Deny**.
- Error `SubscriptionNotRegistered` → registrar el proveedor de recursos (`Microsoft.PolicyInsights`).

## Bloque 2: efecto Modify + tarea de corrección

### Qué se hizo
1. Etiqueta `entorno=dev` en el grupo de recursos (las etiquetas NO se heredan solas).
2. Asignación de la directiva integrada **Inherit a tag from the resource group if missing** (efecto **Modify**) con **identidad administrada asignada por el sistema** y rol Contributor en el RG.
3. **Tarea de corrección** con `ReEvaluateCompliance` → la cuenta creada en el bloque 1 sin etiqueta recibe `entorno=dev` (1 de 1 correcto).

### Comandos clave
```bash
az group update --name rg-policy-lab --tags entorno=dev

az policy assignment create --name heredar-entorno \
  --policy ea3f2387-9b95-492a-a190-fcdc54f7b070 --scope $RG_ID \
  --params '{"tagName":{"value":"entorno"}}' \
  --mi-system-assigned --location spaincentral \
  --identity-scope $RG_ID --role Contributor

az policy remediation create --name corregir-entorno \
  --policy-assignment heredar-entorno --resource-group rg-policy-lab \
  --resource-discovery-mode ReEvaluateCompliance

az role assignment list --scope $RG_ID -o table
```

### Lecciones
- Deny, Audit y Append **no corrigen** recursos existentes; **Modify** sí, con una **tarea de corrección**.
- **Modify y DeployIfNotExists necesitan identidad administrada** (con un rol RBAC) porque cambian recursos sin nadie delante.
- Identidad del sistema: se crea y se borra con la asignación. Del usuario: reutilizable entre varias.
- Una identidad administrada aparece en RBAC como **ServicePrincipal**.
- Se heredan RBAC, Policy y bloqueos; las **etiquetas no**.
