# Biblioteca U - Microservicios, IA y Kubernetes

**Biblioteca U** es una plataforma integral de gestión de biblioteca universitaria con arquitectura de microservicios, integración de IA, y orquestación con Kubernetes.

## 📑 Tabla de Contenidos

- [Componentes](#componentes)
- [Documentación Clave](#documentación-clave)
- [Inicio Rápido Local](#inicio-rápido-local-docker)
- [Inicio Rápido en Kubernetes (AKS)](#inicio-rápido-kubernetes)
- [Desarrollo](#desarrollo)
- [URLs de Prueba](#urls-locales)
- [Resolver Problemas](#resolver-problemas)
- [Estructura del Proyecto](#estructura-del-proyecto)

---

## Componentes

| Componente | Tecnología | Puerto | Responsabilidad |
| --- | --- | ---: | --- |
| **Frontend** | React 18, Vite, Tailwind, Nginx | 4173 | UI, login, catálogo, admin y widget de chatbot |
| **Identity Service** | .NET 10.0 | 5132 | Autenticación, JWT, roles y permisos |
| **Catalog Service** | Node.js 18, Express | 3002 | CRUD de libros, recomendador IA, eventos RabbitMQ |
| **Chatbot Service** | Node.js 20, Express | 3003 | Chatbot IA con Gemini, Groq, OpenRouter y fallback |
| **PostgreSQL** | 16 Alpine | 5432 | Persistencia: usuarios, libros, roles |
| **RabbitMQ** | 3 Management Alpine | 5672, 15672 | Event broker para eventos del catálogo |
| **Redis Streams** | 7 Alpine | 6379 | Event log para eventos del chatbot |

**Integración de IA:**
- 🔵 **Google Gemini** (principal) → ⚡ **Groq** (fallback 1) → 🤖 **OpenRouter** (fallback 2) → Local (fallback final)

---

## Documentación Clave

### 📋 Documentación General
- **[PROYECTO_COMPLETO.md](PROYECTO_COMPLETO.md)** - Documentación maestra: arquitectura, stack, despliegue, anexos
- **[ARQUITECTURA.md](ARQUITECTURA.md)** - Análisis de patrones de diseño, SOLID y mejoras implementadas (27 patrones)
- **[ROADMAP.md](ROADMAP.md)** - Plan de mejora y evolución del proyecto

### ☁️ Despliegue en Azure (AKS + DuckDNS + SSL)
- **[GUIA_AKS.md](GUIA_AKS.md)** - Guía paso a paso para AKS con Azure Education
- **[azure/README.md](biblioteca-microservicios/azure/README.md)** - Scripts de deployment y configuración

### 🐳 Código Fuente
- **[Biblioteca-Frontend/README.md](Biblioteca-Frontend/README.md)** - Frontend React (repositorio separado)
- **[biblioteca-microservicios/README.md](biblioteca-microservicios/README.md)** - Servicios backend (repositorio separado)
  - [catalog-service/README.md](biblioteca-microservicios/catalog-service/README.md)
  - [chatbot-service/README.md](biblioteca-microservicios/chatbot-service/README.md)
  - [mini-identity-api/README.md](biblioteca-microservicios/mini-identity-api-dotnet-main/mini-identity-api-dotnet-main/README.md)

---

## Inicio Rápido Local (Docker)

### Prerequisitos
- Docker y Docker Compose instalados
- Claves API opcionales (para IA)

### Pasos

1. **Copiar configuración:**
   ```powershell
   Copy-Item .env.example .env
   ```

2. **Configurar claves (opcional para IA):**
   ```env
   HF_API_TOKEN=hf_xxxxx                    # Hugging Face (para recomendaciones)
   GEMINI_API_KEY=AIza_xxxxx                # Google Gemini (principal)
   GROQ_API_KEY=gsk_xxxxx                   # Groq (fallback)
   OPENROUTER_API_KEY=sk-xxxxx              # OpenRouter (fallback)
   CHATBOT_PROVIDER=gemini                  # Proveedor preferido
   ```

3. **Iniciar servicios:**
   ```powershell
   docker compose --env-file .env up -d --build
   ```

4. **Verificar:**
   ```powershell
   docker compose ps
   ```

5. **Acceder:**
   - Frontend: http://localhost:4173
   - Credenciales iniciales: `admin` / `admin`

---

## Inicio Rápido Kubernetes (AKS)

### Prerequisitos
- Azure CLI (`az login`)
- `kubectl` instalado
- Cluster AKS creado

### Pasos

1. **Obtener credenciales:**
   ```powershell
   az aks get-credentials --resource-group rg-biblioteca-aks --name biblioteca-aks
   ```

2. **Deploy con Kustomize:**
   ```powershell
   kubectl apply -k biblioteca-microservicios/k8s/overlays/aks-no-domain/
   ```

3. **Verificar despliegue:**
   ```powershell
   kubectl get pods -n biblioteca
   kubectl get services -n biblioteca
   ```

4. **Obtener IP pública:**
   ```powershell
   kubectl get service frontend -n biblioteca
   ```

5. **Acceder:**
   - Frontend: `http://<EXTERNAL-IP>:4173`

---

## URLs Locales (Docker)

| Servicio | URL | Credenciales |
|----------|-----|---------------|
| **Frontend** | http://localhost:4173 | admin / admin |
| **Identity Swagger** | http://localhost:5132/swagger | - |
| **Catalog Health** | http://localhost:3002/api/catalog/health | - |
| **Chatbot Health** | http://localhost:3003/api/chatbot/health | - |
| **RabbitMQ Management** | http://localhost:15672 | guest / guest |
| **Redis CLI** | `docker compose exec -T redis redis-cli` | - |

---

## Desarrollo

### Servicios independientes

Levanta dependencias compartidas:
```powershell
docker compose up -d postgres rabbitmq redis identity-service
```

Luego ejecuta cada servicio:

**Catalog Service:**
```powershell
cd biblioteca-microservicios/catalog-service
npm install
npm run dev
```

**Chatbot Service:**
```powershell
cd biblioteca-microservicios/chatbot-service
npm install
npm run dev
```

**Frontend:**
```powershell
cd Biblioteca-Frontend
npm install
npm run dev
```

---

## Pruebas

### Probar el Chatbot

1. Inicia sesión en el frontend
2. Abre el widget de chat (esquina inferior derecha)
3. Pregunta algo como:
   ```
   Recomiéndame un libro disponible sobre arquitectura de software.
   ```
4. El widget mostrará la respuesta y el proveedor usado
5. Revisa los eventos:

   ```powershell
   docker compose logs --tail=120 chatbot-service
   docker compose exec -T redis redis-cli XLEN chatbot_events
   ```

---

## Licencia

Proyecto académico - Universidad de los Llanos, 2026

## Contacto

Para preguntas o problemas, revisar:
- [ARQUITECTURA.md](ARQUITECTURA.md) - Patrones, SOLID y mejoras
- [PROYECTO_COMPLETO.md](PROYECTO_COMPLETO.md) - Documentación maestra
- Subcarpetas: README de cada componente

## Despliegue Kubernetes con AKS (Recomendado)

El proyecto esta desplegado en Azure Kubernetes Service con dominio DuckDNS + SSL/TLS via Let's Encrypt.

- Backend/microservicios: [biblioteca-microservicios](biblioteca-microservicios)
- Frontend: [Biblioteca-Frontend](Biblioteca-Frontend)

### Infraestructura actual

| Recurso | Valor |
|---------|-------|
| **Dominio** | `https://bibliotechu.duckdns.org` |
| **Frontend** | `https://bibliotechu.duckdns.org` |
| **APIs** | `https://bibliotechu.duckdns.org` |
| **IP pública AKS** | `52.158.169.2` |
| **ACR** | `acrbiblioalex25.azurecr.io` |
| **AKS** | `aks-biblioteca-edu` |
| **Resource Group** | `rg-biblioteca-aks-edu` |
| **SSL** | Let's Encrypt via cert-manager |

### Crear AKS y ACR

```powershell
az login
.\azure\create-aks-education.ps1 `
  -ResourceGroup "rg-biblioteca-aks-edu" `
  -Location "centralus" `
  -AcrName "acrbiblioalex25" `
  -AksName "aks-biblioteca-edu" `
  -NodeVmSize "Standard_D2s_v3" `
  -NodeCount 1 `
  -InstallIngressNginx
```

### Configurar SSL (primera vez)

```powershell
.\azure\setup-ssl.ps1
```

### Actualizar DNS

```powershell
.\azure\update-dns.ps1
```

Guia paso a paso para Azure Education, redespliegue y ahorro de creditos:

```text
GUIA_AKS_EDUCATION_PASO_A_PASO.md
```

## Despliegue Automatizado en AKS

Para un despliegue completo y automatizado de todos los servicios en el cluster AKS, utiliza el script `deploy-aks.ps1`:

### Requisitos previos

- Azure CLI (`az`) autenticado: `az login`
- Kubernetes CLI (`kubectl`) configurado
- Docker CLI (`docker`) disponible
- Archivo `.env` con las API keys configuradas
- Acceso al cluster AKS activo

### Uso básico

```powershell
# Despliegue completo: build, push de imágenes, secrets, manifiestos y rollout
.\azure\deploy-aks.ps1

# Con archivo .env personalizado
.\azure\deploy-aks.ps1 -envFile "path/to/.env"

# Skipping Docker build (solo actualiza manifiestos)
.\azure\deploy-aks.ps1 -skipBuild

# Inicializar base de datos en el deployment
.\azure\deploy-aks.ps1 -initDb

# Especificar contexto de Kubernetes
.\azure\deploy-aks.ps1 -kubeContext "aks-biblioteca-edu"
```

### Qué hace el script

1. **Valida el entorno**: Verifica que `kubectl`, `docker` y `az` estén disponibles
2. **Autentica con Azure**: Confirma que estás autenticado en Azure CLI
3. **Genera etiqueta de versión**: Crea un tag único con timestamp (ej: `aks-20260522-120000`)
4. **Construye imágenes Docker**:
   - Compila los 3 servicios backend (catalog, chatbot, identity)
   - Compila el frontend inyectando la IP del ingress como variable de entorno
   - Sube todas las imágenes al Azure Container Registry (ACR)
5. **Crea secretos Kubernetes**: Inyecta API keys, credenciales DB y credenciales ACR en el namespace
6. **Aplica manifiestos**: Despliega servicios, deployments, configmaps e ingress usando Kustomize
7. **Configura IP del Ingress**: Actualiza el ConfigMap con la IP pública para CORS
8. **Actualiza deployments**: Establece las nuevas imágenes en cada deployment
9. **Espera rollout**: Verifica que todos los pods pasen a estado `Running`
10. **Inicializa BD** (opcional): Ejecuta `init.sql` en PostgreSQL si la base está vacía

### Ejemplo completo

```powershell
# 1. Asegura .env con claves IA
# HF_API_TOKEN=...
# GEMINI_API_KEY=...
# etc.

# 2. Ejecuta el despliegue
cd "C:\Users\AlexP\OneDrive\Escritorio\Teleco 1"
.\azure\deploy-aks.ps1 -initDb

# 3. Espera el mensaje de éxito y la URL de acceso
# "Access your application at: https://bibliotechu.duckdns.org"
```

### Troubleshooting

```powershell
# Ver logs de un pod específico
kubectl logs -n biblioteca deployment/catalog-service

# Ver estado de todos los servicios
kubectl get all -n biblioteca

# Describir un pod para ver eventos
kubectl describe pod <pod-name> -n biblioteca

# Acceder a shell de un pod
kubectl exec -it <pod-name> -n biblioteca -- /bin/bash
```

## Verificacion realizada

Se verifico:

- `npm run lint` en frontend.
- `npm run build` en frontend.
- `npm audit --audit-level=high` en frontend y chatbot.
- `docker compose config --quiet`.
- `docker compose build chatbot-service frontend catalog-service`.
- `GET /api/chatbot/health`.
- `POST /api/chatbot/messages` con usuario autenticado.
- Redis Streams con eventos publicados en `chatbot_events`.
