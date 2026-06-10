# Plan de Migración a Nueva Cuenta Azure

## Objetivo

Migrar BiblioTech a una nueva suscripción Azure, manteniendo la arquitectura de microservicios con costos mínimos. Usa una cuenta nueva (estudiantil o gratuita) aprovechando los beneficios de 12 meses de servicios gratuitos.

---

## Presupuesto Estimado: ~$0.05/mes

| Recurso | Tier | Costo/mes | Nota |
|---|---|---|---|
| AKS | Free (1 node B2pls_v2) | $0 | 750h gratis/mes |
| PostgreSQL | Flexible Server B1MS | $0 | 750h gratis/mes (12m) |
| Service Bus | Basic | ~$0.05 | $0.05/millón operaciones |
| ACR | Basic | $0 | 1 registro gratis (12m) |
| Redis | In-cluster (pod) | $0 | Consumo del node |
| Key Vault | Standard | <$0.01 | Operaciones mínimas |
| Public IP | Standard | $0 | 1500h gratis/mes |
| **Total** | | **~$0.06/mes** | |

---

## Arquitectura

```
Standard_B2pls_v2 (1 vCPU, 4GB RAM) — GRATIS
├── ingress-nginx (pod)
├── identity-service (pod)      ~150Mi
├── catalog-service (pod)       ~150Mi
├── chatbot-service (pod)       ~150Mi
├── redis (pod)                 ~80Mi
└── system/k8s                  ~200Mi
    Total: ~730Mi / 4096Mi ✓

Azure Managed Services (FUERA de K8s)
├── PostgreSQL Flexible Server B1MS   GRATIS 12m
└── Service Bus Basic                 ~$0.05/mes
```

---

## Archivos a Modificar

### 1. `biblioteca-microservicios/k8s/base/identity-service.yaml`

Reducir resources (líneas 88-94):

```yaml
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 192Mi
```

---

### 2. `biblioteca-microservicios/k8s/base/catalog-service.yaml`

Reducir resources (líneas 149-155):

```yaml
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 192Mi
```

---

### 3. `biblioteca-microservicios/k8s/base/chatbot-service.yaml`

Reducir resources (líneas 120-126):

```yaml
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 192Mi
```

---

### 4. `biblioteca-microservicios/k8s/base/configmap.yaml`

```yaml
  DB_HOST: "pg-biblioteca-edu.postgres.database.azure.com"
  REDIS_URL: "redis://redis:6379"
```

---

### 5. `biblioteca-microservicios/k8s/base/secret.template.yaml`

```yaml
  REDIS_URL: "redis://redis:6379"
  AZURE_SERVICE_BUS_CONNECTION_STRING: "Endpoint=sb://sb-biblioteca-edu.servicebus.windows.net/;..."
```

---

### 6. `biblioteca-microservicios/k8s/infrastructure/in-cluster/redis.yaml`

Reducir resources y agregar maxmemory:

```yaml
          command:
            - redis-server
            - --appendonly
            - "yes"
            - --maxmemory
            - "64mb"
            - --maxmemory-policy
            - "allkeys-lru"
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
```

Reducir PVC:

```yaml
      storage: 512Mi
```

---

### 7. `Biblioteca-Frontend/k8s/base/deployment.yaml`

Reducir resources (líneas 36-42):

```yaml
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 96Mi
```

---

### 8. `biblioteca-microservicios/azure/create-aks-education.ps1`

```powershell
[string]$NodeVmSize = "Standard_B2pls_v2"
```

---

### 9. `biblioteca-microservicios/azure/create-managed-services.ps1`

Eliminar la sección 4 (creación de Redis) — Redis será in-cluster.
Cambiar Service Bus de `Standard` -> `Basic`:

```powershell
az servicebus namespace create `
  --sku Basic
```

---

### 10. `biblioteca-microservicios/azure/deploy-aks.ps1` — Bugfix CORS

Corregir `CORS_ORIGIN` (singular) → `CORS_ORIGINS` (plural) en `Update-ConfigMap-IP`:
```json
"CORS_ORIGINS": "http://$ingressIP",
```

### 11. `biblioteca-microservicios/azure/deploy-aks.ps1` — Bugfix VITE build args

Corregir `VITE_API_URL` → `VITE_AUTH_SERVICE_URL`, `VITE_CATALOG_SERVICE_URL`, `VITE_CHATBOT_SERVICE_URL`:
```powershell
$buildArgs = @{
    "VITE_AUTH_SERVICE_URL" = "http://$ingressIP"
    "VITE_CATALOG_SERVICE_URL" = "http://$ingressIP"
    "VITE_CHATBOT_SERVICE_URL" = "http://$ingressIP"
}
```

### 12. `biblioteca-microservicios/azure/deploy-aks.ps1` — ACR name + auth

- `$acrName` → `acrbibliotecaedu`, `$registryUrl` → `acrbibliotecaedu.azurecr.io`
- Eliminado `Get-RegistryPassword` (admin credentials)
- `Docker-Login` ahora usa `az acr login --name $acrName` en vez de admin creds
- Eliminado `ACR_USERNAME`/`ACR_PASSWORD` del `Create-Or-Update-Secrets` (AKS ya tiene AcrPull vía `--attach-acr`)

### 13. Manifests K8s — image ACR name

Actualizado `image:` en los 4 deployments:
- `catalog-service.yaml`, `chatbot-service.yaml`, `identity-service.yaml` → `acrbibliotecaedu.azurecr.io/<name>:latest`
- `frontend/deployment.yaml` → `acrbibliotecaedu.azurecr.io/biblioteca-frontend:latest`

---



## Paso a Paso: Crear Infraestructura en Azure

### 1. Crear cuenta

1. Ir a https://azure.microsoft.com/free/students
2. Registrarse con correo universitario
3. Verificar identidad estudiantil
4. Completar registro (tarjeta de verificación, no se cobra)
5. Ejecutar `az login` y confirmar la nueva suscripción

### 2. Crear Resource Group

```powershell
az group create --name "rg-biblioteca-aks-edu" --location "centralus"
```

### 3. Crear PostgreSQL Flexible Server (**GRATIS** 12 meses)

```powershell
$PG_PASSWORD = "BiblioPg2026!"

az postgres flexible-server create `
  --resource-group "rg-biblioteca-aks-edu" `
  --location "centralus" `
  --name "pg-biblioteca-edu" `
  --admin-user "biblioadmin" `
  --admin-password $PG_PASSWORD `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --public-access 0.0.0.0 `
  --storage-size 32 `
  --version 16 `
  --yes

az postgres flexible-server db create `
  --resource-group "rg-biblioteca-aks-edu" `
  --server-name "pg-biblioteca-edu" `
  --database-name "catalog_db"
```

### 4. Crear Service Bus Basic (~$0.05/mes)

```powershell
az servicebus namespace create `
  --resource-group "rg-biblioteca-aks-edu" `
  --location "centralus" `
  --name "sb-biblioteca-edu" `
  --sku Basic

az servicebus queue create `
  --resource-group "rg-biblioteca-aks-edu" `
  --namespace-name "sb-biblioteca-edu" `
  --name "library-logging-queue"

$SB_CONN = az servicebus namespace authorization-rule keys list `
  --resource-group "rg-biblioteca-aks-edu" `
  --namespace-name "sb-biblioteca-edu" `
  --name RootManageSharedAccessKey `
  --query primaryConnectionString -o tsv

Write-Host "SB_CONN: $SB_CONN"
```

### 5. Crear ACR Basic (**GRATIS** 12 meses)

```powershell
az acr create `
  --resource-group "rg-biblioteca-aks-edu" `
  --name "acrbibliotecaedu" `
  --sku Basic `
  --admin-enabled true
```

### 6. Crear AKS con B2pls_v2 (**GRATIS**)

```powershell
az aks create `
  --resource-group "rg-biblioteca-aks-edu" `
  --name "aks-biblioteca-edu" `
  --location "centralus" `
  --node-count 1 `
  --node-vm-size "Standard_B2pls_v2" `
  --tier free `
  --enable-managed-identity `
  --attach-acr "acrbibliotecaedu" `
  --generate-ssh-keys

az aks get-credentials `
  --resource-group "rg-biblioteca-aks-edu" `
  --name "aks-biblioteca-edu" `
  --overwrite-existing
```

### 7. Instalar NGINX Ingress (Helm)

```powershell
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace `
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

# Esperar a que se asigne la IP
Start-Sleep -Seconds 60
$INGRESS_IP = kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
Write-Host "Ingress IP: $INGRESS_IP"
```

---

## Deploy Manual

### 1. Actualizar `.env`

```env
POSTGRES_HOST=pg-biblioteca-edu.postgres.database.azure.com
POSTGRES_DB=catalog_db
POSTGRES_USER=biblioadmin
POSTGRES_PASSWORD=BiblioPg2026!
REDIS_URL=redis://redis:6379
AZURE_SERVICE_BUS_CONNECTION_STRING=Endpoint=sb://sb-biblioteca-edu.servicebus.windows.net/;...
```

### 2. Build y push imágenes

```powershell
cd biblioteca-microservicios

az acr login --name acrbibliotecaedu
$ACR = "acrbibliotecaedu.azurecr.io"
$TAG = "v1"

# Backend
docker build -t "$ACR/biblioteca/identity-service:$TAG" .\mini-identity-api-dotnet-main\mini-identity-api-dotnet-main
docker build -t "$ACR/biblioteca/catalog-service:$TAG" .\catalog-service
docker build -t "$ACR/biblioteca/chatbot-service:$TAG" .\chatbot-service
docker push "$ACR/biblioteca/identity-service:$TAG"
docker push "$ACR/biblioteca/catalog-service:$TAG"
docker push "$ACR/biblioteca/chatbot-service:$TAG"

# Frontend
cd ..\Biblioteca-Frontend
docker build `
  --build-arg VITE_AUTH_SERVICE_URL="http://$INGRESS_IP" `
  --build-arg VITE_CATALOG_SERVICE_URL="http://$INGRESS_IP" `
  --build-arg VITE_CHATBOT_SERVICE_URL="http://$INGRESS_IP" `
  -t "$ACR/biblioteca/frontend:$TAG" .
docker push "$ACR/biblioteca/frontend:$TAG"

cd ..\biblioteca-microservicios
```

### 3. Aplicar infraestructura in-cluster

```powershell
# Namespace
kubectl create namespace biblioteca --dry-run=client -o yaml | kubectl apply -f -

# Redis (in-cluster)
kubectl apply -f k8s/infrastructure/in-cluster/redis.yaml -n biblioteca
```

### 4. Crear secrets

```powershell
kubectl create secret generic biblioteca-secrets `
  --namespace biblioteca `
  --from-literal=POSTGRES_PASSWORD="BiblioPg2026!" `
  --from-literal=HF_API_TOKEN="hf_xxx" `
  --from-literal=GEMINI_API_KEY="gemini_xxx" `
  --from-literal=GROQ_API_KEY="gsk_xxx" `
  --from-literal=OPENROUTER_API_KEY="sk-or-xxx" `
  --from-literal=REDIS_URL="redis://redis:6379" `
  --from-literal=AZURE_SERVICE_BUS_CONNECTION_STRING="$SB_CONN" `
  --dry-run=client -o yaml | kubectl apply -f -
```

### 5. Aplicar servicios

```powershell
kubectl apply -k k8s/overlays/aks -n biblioteca

cd ..\Biblioteca-Frontend
kubectl apply -k k8s/overlays/aks -n biblioteca
cd ..\biblioteca-microservicios
```

### 6. Actualizar ConfigMap con IP

```powershell
$patch = "{""data"":{""CORS_ORIGINS"":""https://bibliotechu.duckdns.org,http://bibliotechu.duckdns.org"",""OPENROUTER_REFERER"":""https://bibliotechu.duckdns.org""}}"
$patch | kubectl patch configmap biblioteca-config -n biblioteca --type merge -p $patch
```

### 7. Actualizar imágenes

```powershell
kubectl set image deployment/identity-service identity-service="$ACR/biblioteca/identity-service:$TAG" -n biblioteca
kubectl set image deployment/catalog-service catalog-service="$ACR/biblioteca/catalog-service:$TAG" -n biblioteca
kubectl set image deployment/chatbot-service chatbot-service="$ACR/biblioteca/chatbot-service:$TAG" -n biblioteca
kubectl set image deployment/biblioteca-frontend frontend="$ACR/biblioteca/frontend:$TAG" -n biblioteca
```

### 8. Esperar rollout

```powershell
kubectl rollout status deployment/redis -n biblioteca --timeout=120s
kubectl rollout status deployment/identity-service -n biblioteca --timeout=300s
kubectl rollout status deployment/catalog-service -n biblioteca --timeout=300s
kubectl rollout status deployment/chatbot-service -n biblioteca --timeout=300s
kubectl rollout status deployment/biblioteca-frontend -n biblioteca --timeout=180s
```

### 9. Actualizar DuckDNS

```powershell
.\azure\update-dns.ps1
```

### 10. Verificar

```powershell
kubectl get pods -n biblioteca
kubectl get ingress -n biblioteca
kubectl get nodes

Invoke-RestMethod "https://bibliotechu.duckdns.org/health"
Invoke-RestMethod "https://bibliotechu.duckdns.org/api/catalog/health"
Invoke-RestMethod "https://bibliotechu.duckdns.org/api/chatbot/health"
```

---

## Cambios en GitHub Actions (CI/CD)

### Secrets que DEBEN cambiarse

| Secret | Motivo del cambio |
|---|---|
| `AZURE_CREDENTIALS` | Service principal atado a la suscripción anterior. **Regenerar completo.** |
| `POSTGRES_PASSWORD` | Nuevo servidor PostgreSQL, nueva contraseña |
| `REDIS_URL` | Cambia de `rediss://...` a `redis://redis:6379` (in-cluster) |
| `AZURE_SERVICE_BUS_CONNECTION_STRING` | Nuevo namespace Service Bus, nueva connection string |

### Secrets que NO cambian

| Secret | Motivo |
|---|---|
| `HF_API_TOKEN` | API key de Hugging Face, no depende de Azure |
| `GEMINI_API_KEY` | API key de Google, no depende de Azure |
| `GROQ_API_KEY` | API key de Groq, no depende de Azure |
| `OPENROUTER_API_KEY` | API key de OpenRouter, no depende de Azure |

### Variables que cambian

| Variable | Nuevo valor |
|---|---|
| `AKS_RESOURCE_GROUP` | `rg-biblioteca-aks-edu` (igual) |
| `AKS_CLUSTER_NAME` | `aks-biblioteca-edu` (igual) |
| `ACR_NAME` | `acrbibliotecaedu` (cambió: era acrbiblioalex25) |
| `ACR_LOGIN_SERVER` | `acrbibliotecaedu.azurecr.io` (cambió) |
| `POSTGRES_HOST` | `pg-biblioteca-edu.postgres.database.azure.com` |
| `POSTGRES_USER` | `biblioadmin` (igual) |
| `PUBLIC_BASE_URL` | `https://bibliotechu.duckdns.org` (igual) |
| `VITE_AUTH_SERVICE_URL` | `http://<NUEVA_IP>` |
| `VITE_CATALOG_SERVICE_URL` | `http://<NUEVA_IP>` |
| `VITE_CHATBOT_SERVICE_URL` | `http://<NUEVA_IP>` |

### Regenerar AZURE_CREDENTIALS

Ejecuta este comando **con la nueva suscripción activa**:

```powershell
$SUBSCRIPTION_ID = az account show --query id -o tsv
az ad sp create-for-rbac `
  --name "sp-biblioteca-github" `
  --role Contributor `
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-biblioteca-aks-edu" `
  --sdk-auth
```

Copia el JSON completo como el secret `AZURE_CREDENTIALS` en **ambos repositorios**:
- `Biblioteca-Frontend` (Settings → Secrets and variables → Actions)
- `biblioteca-microservicios` (Settings → Secrets and variables → Actions)

### Dónde actualizar en GitHub

Para cada repositorio:

| Ubicación | Qué actualizar |
|---|---|
| Settings → Secrets → Actions → `AZURE_CREDENTIALS` | Regenerar con nuevo service principal |
| Settings → Secrets → Actions → `POSTGRES_PASSWORD` | Nueva contraseña |
| Settings → Secrets → Actions → `REDIS_URL` | `redis://redis:6379` |
| Settings → Secrets → Actions → `AZURE_SERVICE_BUS_CONNECTION_STRING` | Nueva connection string |
| Settings → Variables → `POSTGRES_HOST` | `pg-biblioteca-edu.postgres.database.azure.com` |
| Settings → Variables → `VITE_AUTH_SERVICE_URL` | Nueva IP del ingress |
| Settings → Variables → `VITE_CATALOG_SERVICE_URL` | Nueva IP del ingress |
| Settings → Variables → `VITE_CHATBOT_SERVICE_URL` | Nueva IP del ingress |

---

## Resumen de Cambios Realizados

| # | Archivo | Cambio |
|---|---|---|
| 1 | `identity-service.yaml` | Resources reducidos a 50m/64Mi req, 100m/192Mi lim |
| 2 | `catalog-service.yaml` | Resources reducidos a 50m/64Mi req, 100m/192Mi lim |
| 3 | `chatbot-service.yaml` | Resources reducidos a 50m/64Mi req, 100m/192Mi lim |
| 4 | `frontend/deployment.yaml` | Resources reducidos a 25m/32Mi req, 50m/96Mi lim |
| 5 | `redis.yaml` | Maxmemory 64mb, resources reducidos, PVC 512Mi |
| 6 | `configmap.yaml` | DB_HOST nuevo, REDIS_URL añadido |
| 7 | `secret.template.yaml` | REDIS_URL a `redis://redis:6379` |
| 8 | `create-aks-education.ps1` | VM size a Standard_B2pls_v2 |
| 9 | `create-managed-services.ps1` | Quitada creación Redis, Service Bus a Basic |
| 10 | `deploy-aks.ps1` | Bugfix: CORS_ORIGIN → CORS_ORIGINS |
| 11 | `deploy-aks.ps1` | Bugfix: VITE_API_URL → VITE_AUTH/CATALOG/CHATBOT_URL |
| 12 | `deploy-aks.ps1` | ACR name → `acrbibliotecaedu`, login con `az acr login` |
| 13 | 4 manifests YAML | image: `acrbibliotecaedu.azurecr.io/...` |

## Notas Importantes

- **PostgreSQL B1MS es gratis por 12 meses** con Azure for Students
- **Service Bus Basic** cobra ~$0.05/mes por operaciones mínimas
- **Redis corre como pod** dentro del cluster — $0 extra
- **AKS B2pls_v2 es gratis por 12 meses** (750h/mes)
- **ACR Basic es gratis por 12 meses**
- El B2pls_v2 (1 vCPU, 4GB RAM) es suficiente para el proyecto con las optimizaciones de resources
- Si no es suficiente, cambiar a B2s (~$15/mes extra) pero reduce cuánto dura el crédito
- Los secrets de AI (Hugging Face, Gemini, Groq, OpenRouter) **no necesitan cambiarse**
