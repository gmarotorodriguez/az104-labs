# Lab 01 · Plantilla ARM: cuenta de almacenamiento con parámetros y salidas

Módulo de Microsoft Learn: crear y desplegar plantillas de Azure Resource Manager.
Fecha: 1 de octubre de 2026. Herramienta: Azure Cloud Shell (Bash), en lugar de VS Code local.

## Qué hace la plantilla
- Crea una cuenta de almacenamiento `StorageV2` en la región del grupo de recursos.
- Parámetros: `storageName` (3-24 caracteres) y `storageSKU` (solo `Standard_LRS`, `Standard_GRS` o `Standard_ZRS`; por defecto `Standard_LRS`).
- Salida: `storageEndpoint`, con las URLs de la cuenta (blob, file, queue, table, dfs, web).

## Pasos
1. Crear el grupo de recursos y dejarlo por defecto:
   `az group create --name rg-lab02 --location spaincentral`
   `az configure --defaults group="rg-lab02"`
2. Desplegar la plantilla vacía, luego con la cuenta, luego con parámetros y salida:
   `az deployment group create --name <nombre> --template-file azuredeploy.json --parameters storageName=<nombre>`
3. Revisar cada despliegue en el portal: grupo de recursos → Implementaciones.
4. Ver solo las salidas:
   `az deployment group show --name <nombre> --query properties.outputs`
5. Borrar todo: `az group delete --name rg-lab02 --yes --no-wait`

## Errores y cómo se resolvieron
- **InvalidTemplate** al pasar `storageSKU=Premium_LRS`: el valor no estaba en `allowedValues`. La plantilla se valida antes de crear nada.
- **SkuUpdateNotAvailable** al pasar a `Standard_GRS`: Spain Central no tiene región emparejada y GRS la necesita. Error del proveedor `Microsoft.Storage`, no de la plantilla.
- Aviso de Cloud Shell por el proveedor sin registrar: `az provider register --namespace Microsoft.CloudShell`.

## Lo que he aprendido
- Modo **Incremental** (por defecto): volver a desplegar actualiza lo que existe, no duplica. El modo **Completo** borra lo que no esté en la plantilla.
- `[parameters('x')]` lee un parámetro; `reference()` lee propiedades de un recurso ya desplegado.
- Hay dos validaciones: la de la plantilla y la del proveedor de recursos.
- Implementaciones guarda qué plantilla se desplegó, cuándo y si funcionó.
- Cloud Shell sin almacenamiento es efímero: se pierden los archivos al cerrar la sesión.
