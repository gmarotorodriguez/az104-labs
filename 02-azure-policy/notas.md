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
