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

## Bloque 3: iniciativa, exención y limpieza

### Qué se hizo
1. **Iniciativa** `gobernanza-basica` (`iniciativa.json` + `iniciativa-parametros.json`) que agrupa *Allowed locations* y la directiva personalizada de etiqueta, con parámetros propios que pasan a cada directiva.
2. Sustituidas las dos asignaciones sueltas por **una sola asignación de la iniciativa**.
3. Prueba Modify + Deny: recurso creado sin etiqueta → Modify la añade antes de que Deny evalúe → se crea sin error.
4. **Exención** (categoría Waiver, con caducidad) de un recurso, solo para la directiva de etiqueta (`policyDefinitionReferenceId`).
5. Al borrar la asignación con identidad del sistema, la identidad desaparece pero la **asignación de rol queda huérfana**.
6. Limpieza: grupo de recursos (arrastra asignaciones, exención y roles del RG) → iniciativa → definición personalizada.

### Comandos clave
```bash
SUB_ID=$(az account show --query id -o tsv)
sed "s|<SUBSCRIPTION_ID>|$SUB_ID|" iniciativa.json > ~/iniciativa-real.json   # fuera del repo

az policy set-definition create --name gobernanza-basica \
  --definitions ~/iniciativa-real.json --params iniciativa-parametros.json

az policy assignment create --name gobernanza \
  --policy-set-definition gobernanza-basica --scope $RG_ID \
  --params '{"regionesPermitidas":{"value":["spaincentral"]},"efectoEtiqueta":{"value":"Deny"}}'

az policy exemption create --name exencion-etiqueta \
  --policy-assignment $ASIG_ID --policy-definition-reference-ids etiquetaEntorno \
  --scope $ST_ID --exemption-category Waiver --expires-on 2026-12-31T23:59:59Z

az group delete --name rg-policy-lab --yes --no-wait
az policy set-definition delete --name gobernanza-basica
az policy definition delete --name exigir-etiqueta-entorno
```

### Lecciones
- **Directiva** = una regla; **iniciativa** = caja de directivas; **asignación** = aplicarlas a un ámbito con parámetros.
- Orden de evaluación: Disabled → Append/Modify → Deny → Audit; después AuditIfNotExists/DeployIfNotExists.
- **Exención** (objeto aparte, aparece como "Exento", con motivo Waiver/Mitigated y caducidad) ≠ **exclusión** (en la asignación, el recurso ni se evalúa).
- Borrar una asignación con identidad puede dejar **asignaciones de rol huérfanas**: hay que limpiarlas.
- Las definiciones viven en la suscripción: no se borran con el grupo de recursos. Primero la iniciativa, luego la definición.
