# Configurar el acceso del CI a Google Play (Workload Identity Federation)

Puesta en marcha **única** para que `release-internal.yml` pueda publicar en la pista interna sin guardar ninguna
clave JSON de Google. Hecho el 2026-10-05 para `com.tramites1cero1.centralizacion`.

| Dato | Valor |
|---|---|
| Proyecto de Google Cloud | `betaappcentralizate` (número `577349260806`) |
| Cuenta de servicio | `play-ci-centralizacion@betaappcentralizate.iam.gserviceaccount.com` |
| Pool / proveedor | `github` / `github-centralizacion` |
| Repositorio autorizado | `desarrollofasemovil/Centralizacion-Flutter` |

## 1. Google Cloud (Cloud Shell, proyecto `betaappcentralizate`)

Requiere rol de Propietario (o *IAM Workload Identity Pool Admin* + *Service Account Admin*).

```bash
gcloud config set project betaappcentralizate
PROJECT_ID=betaappcentralizate
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
SA=play-ci-centralizacion@betaappcentralizate.iam.gserviceaccount.com
POOL=github
PROVIDER=github-centralizacion
REPO=desarrollofasemovil/Centralizacion-Flutter

# APIs
gcloud services enable androidpublisher.googleapis.com iamcredentials.googleapis.com sts.googleapis.com iam.googleapis.com

# Pool (solo si `gcloud iam workload-identity-pools list --location=global` no lo muestra)
gcloud iam workload-identity-pools create $POOL --location=global --display-name="GitHub Actions"

# Proveedor OIDC de GitHub, restringido a ESTE repositorio
gcloud iam workload-identity-pools providers create-oidc $PROVIDER --location=global --workload-identity-pool=$POOL --display-name="GitHub Centralizacion-Flutter" --issuer-uri="https://token.actions.githubusercontent.com" --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" --attribute-condition="assertion.repository=='$REPO'"

# Permitir que el repositorio actúe como la cuenta de servicio
gcloud iam service-accounts add-iam-policy-binding $SA --role=roles/iam.workloadIdentityUser --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL/attribute.repository/$REPO"

# Valor para el secreto GCP_WIF_PROVIDER
gcloud iam workload-identity-pools providers describe $PROVIDER --location=global --workload-identity-pool=$POOL --format='value(name)'
```

- La cuenta de servicio **no** lleva roles de proyecto ni claves JSON: lo único que necesita en Google Cloud es el
  binding `workloadIdentityUser` de arriba.
- La condición `assertion.repository == ...` del proveedor es lo único que impide que otro repositorio de GitHub se
  haga pasar por este. No quitarla.

## 2. Play Console

**Usuarios y permisos → Invitar a nuevos usuarios:**

1. Correo: `play-ci-centralizacion@betaappcentralizate.iam.gserviceaccount.com`.
2. **Permisos de la cuenta:** todo desmarcado.
3. **Permisos de la aplicación → Agregar aplicación** → `com.tramites1cero1.centralizacion`, solo:
   - *Ver información de la aplicación (solo lectura)*
   - *Publicar en canales de prueba*
4. Invitar. Las cuentas de servicio quedan activas sin aceptar ningún correo.

Así la cuenta **no puede publicar en producción**. Los permisos pueden tardar horas en propagarse: mientras tanto la
API devuelve 403 aunque todo esté bien (usar el modo `solo_compilar` del workflow).

## 3. Secretos en GitHub

| Secreto | Valor |
|---|---|
| `GCP_WIF_PROVIDER` | `projects/577349260806/locations/global/workloadIdentityPools/github/providers/github-centralizacion` |
| `GCP_SERVICE_ACCOUNT` | `play-ci-centralizacion@betaappcentralizate.iam.gserviceaccount.com` |

Cargados el 2026-10-05 con `gh secret set`. No son credenciales: sin el proveedor, que solo acepta este repositorio,
no sirven para nada.

## Diagnóstico

| Error | Causa |
|---|---|
| `PERMISSION_DENIED` al crear pool/proveedor | El usuario de Cloud Shell no tiene los roles de arriba |
| `ALREADY_EXISTS` | Ya estaba creado: seguir con el siguiente paso |
| 401 en la guarda del workflow | El token no se canjeó: revisar el binding del paso 1 y `GCP_WIF_PROVIDER` |
| 403 con `ACCESS_TOKEN_SCOPE_INSUFFICIENT` | Problema del YAML (scope del token), no de Play Console |
| 403 sin esa frase | Permisos de Play Console ausentes, en otra app, o aún propagándose |
| 404 en la guarda | Play no reconoce el paquete (`PACKAGE_NAME` del workflow) |
