# BiblioTech - Biblioteca Universitaria

> **Plataforma de gestión bibliotecaria universitaria** basada en microservicios, con integración de IA, mensajería asíncrona y despliegue en Azure Kubernetes Service.
>
> **Proyecto académico** — Ingeniería de Sistemas | Parcial I - 2026  
> **Universidad de los Llanos** — Facultad de Ciencias Básicas e Ingeniería

---

## Tabla de Contenidos

1. [Descripción General](#1-descripción-general)
2. [Stack Tecnológico](#2-stack-tecnológico)
3. [Arquitectura del Sistema](#3-arquitectura-del-sistema)
4. [Frontend](#4-frontend)
5. [Microservicios Backend](#5-microservicios-backend)
6. [Base de Datos](#6-base-de-datos)
7. [Mensajería y Eventos](#7-mensajería-y-eventos)
8. [Integración con IA](#8-integración-con-ia)
9. [Despliegue](#9-despliegue)
10. [Infraestructura en Azure](#10-infraestructura-en-azure)
11. [CI/CD](#11-cicd)
12. [Equipo](#12-equipo)
13. [Estado Actual](#13-estado-actual)
14. [Guías y Documentación](#14-guías-y-documentación)
15. [Planificación Futura](#15-planificación-futura)
16. [Roadmap](#16-roadmap)
17. [Anexo A — Archivos Obsoletos (Era VM)](#anexo-a--archivos-obsoletos-era-vm)
18. [Anexo B — Guía de Configuración de Dominio/DNS](#anexo-b--guía-de-configuración-de-dominiodns)
19. [Anexo C — Automatización Pendiente](#anexo-c--automatización-pendiente)

---

## 1. Descripción General

### Problema Resuelto

Las bibliotecas universitarias enfrentan múltiples desafíos: autenticación centralizada para distintos servicios, gestión eficiente del catálogo de libros, búsqueda avanzada con filtros, consultas en lenguaje natural mediante un asistente inteligente (chatbot), y recomendaciones de libros potenciadas por IA. BiblioTech resuelve todo esto con una arquitectura de microservicios escalable.

### Objetivos Clave

- Sistema modular y desacoplado mediante microservicios
- Múltiples proveedores de IA con fallback automático
- Comunicación asíncrona (Azure Service Bus + Redis Streams)
- Despliegue en Azure Kubernetes Service
- Documentación completa con diagramas y guías reproducibles
- Repositorios separados con CI/CD independiente (frontend + backend)

### Usuarios y Roles

| Rol | Descripción |
|-----|------------|
| **Usuario** | Consulta el catálogo, usa el chatbot, recibe recomendaciones |
| **Bibliotecario** | Administra el catálogo (CRUD de libros), gestiona usuarios |
| **Admin** | Acceso total: gestión de roles, usuarios, libros y configuración |

---

## 2. Stack Tecnológico

### Core

| Tecnología | Versión | Uso |
|------------|---------|-----|
| React | 19.x | Framework de frontend |
| Vite | 8.x | Build tool |
| Tailwind CSS | 3.x | Estilos |
| .NET Web API | 10.0 | Identity Service (auth) |
| Node.js / Express | 18 LTS / 20 LTS | Catalog & Chatbot Services |
| PostgreSQL | 16 Alpine | Base de datos (local) |
| Azure Database for PostgreSQL | Flexible Server | Base de datos (producción) |
| Azure Managed Redis | Standard C1 | Streams de eventos (producción) |
| Redis | 7 Alpine | Streams de eventos (local) |
| RabbitMQ | 3 Management Alpine | Mensajería asíncrona (local) |
| Azure Service Bus | Standard | Mensajería asíncrona (producción) |
| Docker / Docker Compose | Latest | Contenedores y orquestación local |
| Kubernetes (AKS) | Latest | Orquestación en producción |

### Proveedores de IA

| Proveedor | Modelo | Propósito |
|-----------|--------|-----------|
| Hugging Face | `facebook/bart-large-mnli` | Recomendaciones (zero-shot classification) |
| Google Gemini | `gemini-2.5-flash` | Chatbot principal |
| Groq Cloud | `llama-3.1-8b-instant` | Fallback 1 del chatbot |
| OpenRouter | `mistralai/mistral-7b-instruct:free` | Fallback 2 del chatbot |
| Local | Respuestas controladas | Fallback final |

### Infraestructura Cloud (Producción)

| Servicio | SKU | Propósito |
|----------|-----|-----------|
| AKS | 1 nodo Standard_D2s_v3 | Orquestación principal |
| ACR | Basic | Registro de imágenes Docker |
| Azure Database for PostgreSQL | Flexible Server | Base de datos gestionada |
| Azure Managed Redis | Standard C1 | Cache y Streams de eventos |
| Azure Service Bus | Standard | Mensajería asíncrona |

---

## 3. Arquitectura del Sistema

```
┌─────────────┐     ┌──────────────────────────────────────────┐
│   Cliente   │────▶│              Frontend (React)            │
│  (Browser)  │     │  Vite + Tailwind + React Router DOM      │
└─────────────┘     └──────────┬───────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │  Ingress-Nginx K8s   │
                    │  (LoadBalancer)      │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Identity Service │  │ Catalog Service  │  │ Chatbot Service  │
│  .NET 10 Web API │  │ Node.js/Express  │  │ Node.js/Express  │
│  Puerto 5132     │  │ Puerto 3002      │  │ Puerto 3003      │
│  JWT + RBAC      │  │ CRUD + AI Recs   │  │ Multi-AI Chat    │
└────────┬────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                    │                      │
         ▼                    ▼                      ▼
┌───────────────────────────────────────────────────────────┐
│      Azure Database for PostgreSQL (catalog_db)            │
│  USERS · ROLES · PERMISSIONS · BOOKS · CHAT_MESSAGES      │
└───────────────────────────────────────────────────────────┘
         │                    │                      │
         ▼                    ▼                      ▼
┌──────────────────┐   ┌───────────────────┐   ┌──────────────────┐
│  Azure Service   │   │  Azure Managed    │   │   RabbitMQ       │
│  Bus (prod)      │   │  Redis (prod)     │   │   (local only)   │
│  library-logging │   │  chatbot_events   │   │                  │
│  queue           │   │  Streams          │   │                  │
└──────────────────┘   └───────────────────┘   └──────────────────┘
```

### Flujo de Autenticación

1. El usuario envía credenciales al frontend
2. Frontend llama a `POST /api/auth/login` en Identity Service
3. Identity Service valida contra Azure Database for PostgreSQL y emite un JWT
4. El frontend almacena el JWT en `localStorage`
5. Cada petición subsecuente incluye `Authorization: Bearer <token>`
6. Catalog Service y Chatbot Service validan el JWT contra Identity Service (`/introspect`)

### Flujo del Chatbot con Multi-Fallback

1. Usuario envía mensaje → `POST /api/chatbot/messages`
2. Chatbot Service valida JWT contra Identity Service
3. Publica evento `chat.message.received` en Azure Managed Redis Streams
4. Obtiene contexto del catálogo desde Catalog Service
5. Construye prompt y prueba proveedores en cadena:
   - **Gemini** → si falla → **Groq** → si falla → **OpenRouter** → si falla → **Local**
6. Publica evento `chat.message.completed` o `chat.message.failed`
7. Retorna respuesta con info del proveedor/modelo usado

### Flujo de Mensajería (Catálogo)

1. Catalog Service publica eventos (`book.created`, `book.recommended`)
2. En producción: usa **Azure Service Bus** (`library-logging-queue`)
3. En local: usa **RabbitMQ** (`library_events` exchange fanout)

---

## 4. Frontend

### Estructura de Rutas

| Ruta | Componente | Protección |
|------|-----------|------------|
| `/` | Redirección a `/catalog` | — |
| `/login` | `LoginPage` | Solo invitados |
| `/register` | `RegisterPage` | Solo invitados |
| `/catalog` | `CatalogPage` | Autenticado |
| `/admin` | `AdminPage` | Admin o Bibliotecario |

### Componentes Principales

```
src/
├── api/
│   ├── auth.api.js        # Login/register
│   ├── catalog.api.js     # CRUD libros + recomendaciones IA
│   ├── chatbot.api.js     # Mensajes del chatbot
│   ├── roles.api.js       # Gestión de roles
│   └── users.api.js       # Gestión de usuarios
├── components/
│   ├── common/
│   │   ├── NavBar.jsx
│   │   ├── ProtectedRoute.jsx
│   │   ├── RoleGuard.jsx
│   │   └── Spinner.jsx
│   ├── books/
│   │   ├── BookCard.jsx
│   │   ├── BookFilters.jsx
│   │   └── BookForm.jsx
│   ├── chatbot/
│   │   └── ChatbotWidget.jsx
│   └── roles/
│       └── RoleCard.jsx
├── context/
│   └── AuthContext.jsx     # Estado global de autenticación
├── hooks/
│   ├── useAuth.js
│   ├── useBooks.js
│   ├── useRoles.js
│   └── useUsers.js
└── App.jsx                # Router principal
```

### Características Implementadas

- Autenticación JWT con persistencia en `localStorage`
- Protección de rutas por autenticación y roles
- Catálogo con paginación, filtros (título, autor, categoría, disponibilidad)
- Recomendaciones IA de libros con TF-IDF + zero-shot classification
- Widget flotante de chatbot accesible tras autenticación
- Panel de administración con gestión de libros, usuarios y roles
- Tema visual institucional (rojo universitario `#7f1d1d` → `#dc2626`)
- Diseño responsive con Tailwind CSS
- Cancelación de requests HTTP con AbortController (`auth.api.js`, `AuthContext.jsx`)
- Lazy loading con `React.lazy()` + `<Suspense>` en rutas pesadas

---

## 5. Microservicios Backend

### 5.1 Identity Service (.NET 10.0 Web API)

**Ubicación:** `biblioteca-microservicios/mini-identity-api-dotnet-main/`  
**Puerto:** `5132`

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/auth/login` | POST | Inicio de sesión |
| `/api/auth/register` | POST | Registro de usuario |
| `/api/auth/me` | GET | Perfil del usuario autenticado |
| `/api/auth/introspect` | POST | Validación de token para servicios internos |
| `/health` | GET | Health check |

**Características:**
- Entity Framework Core con PostgreSQL (Azure Database for PostgreSQL en prod)
- JWT stateless con claims de roles
- Swagger UI en `/swagger`
- RBAC completo
- MediatR (CQRS) para queries de usuarios: `GetAllUsersQuery`, `GetUserByIdQuery`
- Specification Pattern: `UserByStatusSpecification`, `UserByRoleSpecification`, `UserBySearchSpecification`
- Refresh tokens con tabla `refresh_tokens` y endpoint `/api/auth/refresh`
- Dapper para repositorios con SQL optimizado
- Result Pattern (`Result<T>`) en Application layer
- Cookies httpOnly para JWT + refresh tokens
- Azure Key Vault integrado vía `DefaultAzureCredential` para JWT Key

### 5.2 Catalog Service (Node.js 18 + Express)

**Ubicación:** `biblioteca-microservicios/catalog-service/`  
**Puerto:** `3002`

| Endpoint | Método | Descripción | Auth |
|----------|--------|-------------|------|
| `/api/catalog/health` | GET | Health check | No |
| `/api/catalog/books` | GET | Listar libros (con filtros) | JWT |
| `/api/catalog/books` | POST | Crear libro | Admin/Bibliotecario |
| `/api/catalog/books/:id` | PUT | Actualizar libro | Admin/Bibliotecario |
| `/api/catalog/books/:id` | DELETE | Eliminar libro | Admin/Bibliotecario |
| `/api/catalog/books/ai/recommendations` | POST | Recomendaciones IA | JWT |

**Características:**
- Sequelize ORM + PostgreSQL
- Express Validator para validaciones
- Integración con Hugging Face Inference API
- Publicación de eventos en Azure Service Bus (producción) o RabbitMQ (local)
- JWT validation contra Identity Service
- CQRS: `BookQueryController` (GET) y `BookCommandController` (POST/PUT/DELETE/PATCH) separados
- TF-IDF para scoring de relevancia (`RetrievalEngine` con `natural`)
- Circuit breaker + retry exponencial en llamadas a Hugging Face
- `composeMiddleware()` desde `biblioteca-shared` para middleware declarativo
- `IBookRecommender` como interfaz explícita de la fachada `AiService`

### 5.3 Chatbot Service (Node.js 20 + Express)

**Ubicación:** `biblioteca-microservicios/chatbot-service/`  
**Puerto:** `3003`

| Endpoint | Método | Descripción | Auth |
|----------|--------|-------------|------|
| `/api/chatbot/health` | GET | Health check | No |
| `/api/chatbot/messages` | POST | Enviar mensaje al chatbot | JWT |

**Características:**
- Cadena de proveedores IA con fallback automático: Gemini → Groq → OpenRouter → Local
- Redis Streams (Azure Managed Redis en prod) para logging de eventos
- Contexto del catálogo en tiempo real con `CatalogContextService` (token por request)
- Validación JWT contra Identity Service
- `AiProviderRegistry` con Strategy Pattern
- Chain of Responsibility (`AiProviderHandler`) para fallback declarativo

---

## 6. Base de Datos

### Esquema PostgreSQL (`catalog_db`)

```sql
-- Identidad y Autorización
USERS           (id UUID PK, username, email, password_hash, status, created_at, updated_at)
ROLES           (id UUID PK, name, description)
USER_ROLES      (id UUID PK, user_id FK, role_id FK, assigned_at)
PERMISSIONS     (id UUID PK, code, description)
ROLE_PERMISSIONS(id UUID PK, role_id FK, permission_id FK)

-- Catálogo
BOOKS               (id UUID PK, title, author, isbn, editorial, year, 
                     categories JSON, total_copies, available_copies, 
                     description, created_at, updated_at)
BOOK_AVAILABILITY   (id UUID PK, book_id FK, reservation_date, status)

-- Chatbot
CHAT_MESSAGES       (id UUID PK, user_id FK, message, response, 
                     ai_provider, ai_model, created_at)
```

### Seed Data

El archivo `init.sql` contiene ~250+ libros que incluyen:
- **Técnicos:** Ingeniería de software, machine learning, sistemas distribuidos, bases de datos
- **Literatura:** Autores latinoamericanos (Borges, Cortázar, García Márquez, Vargas Llosa, etc.)

### Producción vs Local

| Componente | Local (Docker Compose) | Producción (AKS) |
|-----------|----------------------|-------------------|
| PostgreSQL | Contenedor `postgres:16-alpine` | Azure Database for PostgreSQL Flexible Server |
| Redis | Contenedor `redis:7-alpine` | Azure Managed Redis Standard C1 |
| Mensajería | RabbitMQ 3 Management | Azure Service Bus Standard |

---

## 7. Mensajería y Eventos

### Azure Service Bus (Producción)

- **Queue:** `library-logging-queue`
- **Namespace:** `sb-biblioteca-edu-alex25`
- **Eventos:**
  - `book.created` — Cuando se crea un libro
  - `book.recommended` — Cuando se genera una recomendación
- **Uso:** Comunicación asíncrona entre servicios del catálogo

### RabbitMQ (Solo Local)

- **Exchange:** `library_events` (tipo fanout)
- **Activo solo cuando `AZURE_SERVICE_BUS_CONNECTION_STRING` está vacío
- **Uso:** Desarrollo local, mismo comportamiento que Service Bus

### Azure Managed Redis Streams (Producción)

- **Stream:** `chatbot_events`
- **Host:** `redis-biblioteca-edu-alex25.centralus.redis.azure.net:10000` (TLS)
- **Eventos:**
  - `chat.message.received` — Mensaje recibido
  - `chat.message.completed` — Respuesta generada
  - `chat.message.failed` — Error en la generación
- **Uso:** Logging y trazabilidad de interacciones del chatbot

---

## 8. Integración con IA

### Recomendaciones de Libros (Catalog Service)

- **API:** Hugging Face Inference API
- **Modelo:** `facebook/bart-large-mnli`
- **Técnica:** Zero-shot classification (MNLI)
- **Flujo:**
  1. Toma una descripción o preferencia del usuario
  2. Clasifica contra categorías disponibles
  3. Retorna libros coincidentes
- **Fallback:** Respuesta local si la API no está disponible

### Chatbot Inteligente (Chatbot Service)

- **Cadena de proveedores (en orden):**

| Orden | Proveedor | Modelo | API Key |
|-------|-----------|--------|---------|
| 1° | Google Gemini | `gemini-2.5-flash` | `GEMINI_API_KEY` |
| 2° | Groq Cloud | `llama-3.1-8b-instant` | `GROQ_API_KEY` |
| 3° | OpenRouter | `mistralai/mistral-7b-instruct:free` | `OPENROUTER_API_KEY` |
| 4° | Local | Respuestas predefinidas | — |

- **Contexto:** El chatbot consulta el catálogo en tiempo real para responder preguntas específicas sobre libros disponibles
- **Trazabilidad:** Cada respuesta incluye qué proveedor/modelo se utilizó

---

## 9. Despliegue

### 9.1 Local (Docker Compose)

```bash
docker compose up -d
```

Orquesta 7 contenedores:

| Servicio | Puerto | Depende de |
|----------|--------|------------|
| postgres | 5432 | — |
| rabbitmq | 5672, 15672 | — |
| redis | 6379 | — |
| identity-service | 5132 | postgres |
| catalog-service | 3002 | postgres, rabbitmq, identity-service |
| chatbot-service | 3003 | redis, identity-service |
| frontend | 4173 | — |

### 9.2 Azure Kubernetes Service (AKS) — **Principal**

**URL actual:** `https://bibliotechu.duckdns.org`  
**Cluster:** `aks-biblioteca-edu`  
**Resource Group:** `rg-biblioteca-aks-edu`  
**ACR:** `acrbibliotecaedu.azurecr.io`

**Imágenes en ACR:**
```
acrbibliotecaedu.azurecr.io/biblioteca/identity-service
acrbibliotecaedu.azurecr.io/biblioteca/catalog-service
acrbibliotecaedu.azurecr.io/biblioteca/chatbot-service
acrbibliotecaedu.azurecr.io/biblioteca/frontend
```

**Estructura Kustomize (Backend):**

```
biblioteca-microservicios/k8s/
├── base/
│   ├── namespace.yaml
│   ├── configmap.yaml          # Conexión a servicios gestionados de Azure
│   ├── identity-service.yaml
│   ├── catalog-service.yaml
│   ├── chatbot-service.yaml
│   └── ingress.yaml
├── infrastructure/
│   └── in-cluster/             # Infra local opcional (postgres, rabbitmq, redis)
├── overlays/
│   ├── aks/                    # Con dominio (bibliotechu.duckdns.org)
│   │   ├── configmap-patch.yaml
│   │   ├── ingress-patch.yaml  # Host + TLS + cert-manager annotation
│   │   └── kustomization.yaml
│   └── aks-no-domain/          # Sin dominio (solo IP)
│       ├── remove-ingress-host.yaml
│       └── kustomization.yaml
```

**Estructura Kustomize (Frontend):**

```
Biblioteca-Frontend/k8s/
├── base/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── overlays/
│   ├── aks/                    # Con dominio
│   └── aks-no-domain/          # Sin dominio (activo actualmente)
```

**Actualmente desplegado con overlay `aks`** usando el dominio `bibliotechu.duckdns.org` con TLS/SSL via Let's Encrypt (cert-manager).

### Variable KUSTOMIZE_OVERLAY en GitHub

Para que el CI/CD use el overlay con dominio + TLS automáticamente al hacer push a `main`:

**🔹 Diferencia entre Secrets y Variables:**

| Tipo | Nombre | Se ve en logs | Ejemplo |
|------|--------|---------------|---------|
| **Repository variable** | `KUSTOMIZE_OVERLAY` | ✅ Sí, se muestra | `k8s/overlays/aks` |
| **Repository secret** | `AZURE_CREDENTIALS` | ❌ No, oculto | `{ "clientId": "..." }` |

Usa **variables** para configuraciones no sensibles (rutas, URLs) y **secrets** para credenciales (API keys, passwords).

**🔹 Cómo configurarlo:**

1. Ve a tu repositorio en GitHub → **Settings** → **🖼️ Variables and secrets** → **Actions**
2. En la pestaña **Variables**, pulsa **"New repository variable"**
3. Crea dos (una para cada repo):

   **Repo Frontend** (`Biblioteca-Frontend`):
   ```
   Name:  KUSTOMIZE_OVERLAY
   Value: k8s/overlays/aks
   ```

   **Repo Backend** (`biblioteca-microservicios`):
   ```
   Name:  KUSTOMIZE_OVERLAY
   Value: k8s/overlays/aks
   ```

4. El pipeline automáticamente usará el overlay `aks` (con dominio `bibliotechu.duckdns.org` + TLS)
5. Para volver al modo IP (sin dominio), cambia el valor a `k8s/overlays/aks-no-domain` o borra la variable

**🔹 Cómo funciona en el código:**

```yaml
env:
  KUSTOMIZE_OVERLAY: ${{ vars.KUSTOMIZE_OVERLAY || 'k8s/overlays/aks-no-domain' }}
```

- `vars.KUSTOMIZE_OVERLAY` → toma el valor de la variable de GitHub si existe
- `|| 'k8s/overlays/aks-no-domain'` → si no existe la variable, usa este valor por defecto

**🔹 Otras variables que puedes necesitar en GitHub:**

| Variable/Secret | Dónde | Propósito |
|----------------|-------|-----------|
| `AKS_RESOURCE_GROUP` | Variables | Grupo de recursos de Azure |
| `AKS_CLUSTER_NAME` | Variables | Nombre del cluster AKS |
| `ACR_NAME` | Variables | Nombre del Azure Container Registry |
| `ACR_LOGIN_SERVER` | Variables | Servidor de login del ACR |
| `PUBLIC_BASE_URL` | Variables | URL base del frontend (`https://bibliotechu.duckdns.org`) |
| `AZURE_CREDENTIALS` | Secrets | JSON de autenticación para Azure login |
| `POSTGRES_PASSWORD` | Secrets | Password de la base de datos |
| `REDIS_URL` | Secrets | URL de conexión a Redis gestionado |
| `AZURE_SERVICE_BUS_CONNECTION_STRING` | Secrets | Cadena de conexión de Service Bus |
| `HF_API_TOKEN` / `GEMINI_API_KEY` / etc. | Secrets | API keys de los proveedores IA |

### DNS y dominio

| Dominio | IP | Estado |
|---------|----|--------|
| `bibliotechu.duckdns.org` | `52.158.169.2` | ✅ Activo con SSL |
| Token DuckDNS | Configurado en `duckdns-token.txt` | ✅ No subir a Git |

Para actualizar el DNS después de reiniciar AKS:

```powershell
.\azure\update-dns.ps1
```

---

## 10. Infraestructura en Azure

### Recursos en Azure

| Recurso | Nombre | SKU | Estado |
|---------|--------|-----|--------|
| Resource Group | `rg-biblioteca-aks-edu` | — | Activo |
| AKS Cluster | `aks-biblioteca-edu` | 1x Standard_D2s_v3, tier free | Activo |
| ACR | `acrbibliotecaedu` | Basic | Activo |
| Azure Database for PostgreSQL | `pg-biblioteca-edu-alex25` | Flexible Server | Activo |
| Azure Managed Redis | `redis-biblioteca-edu-alex25` | Standard C1 | Activo |
| Azure Service Bus | `sb-biblioteca-edu-alex25` | Standard | Activo |

### Scripts de Automatización

| Script | Propósito |
|--------|-----------|
| `azure/create-aks-education.ps1` | Crear RG + ACR Basic + AKS (1 nodo) + ingress-nginx |
| `azure/deploy-aks.ps1` | Build → Push ACR → Secrets → Manifiestos → Rollout |
| `azure/setup-ssl.ps1` | Instalar cert-manager + ClusterIssuer Let's Encrypt |
| `azure/create-managed-services.ps1` | Crear PostgreSQL, Redis, Service Bus gestionados |
| `azure/rollback.ps1` | Revertir deployments a versión anterior |
| `azure/update-dns.ps1` | Actualizar registro A de DuckDNS con IP del ingress |
| `azure/cleanup.ps1` | Limpiar PVCs huérfanos e imágenes sin tag en ACR |
| `azure/aks-stop.ps1` | Detener AKS (ahorrar créditos Education) |
| `azure/aks-start.ps1` | Iniciar AKS + refrescar kubeconfig |
| `azure/aks-status.ps1` | Verificar estado del cluster/node pool |
| `azure/aks-delete-resource-group.ps1` | Eliminar grupo de recursos completo |

### Conexiones a Servicios Gestionados

**ConfigMap de producción** (`k8s/base/configmap.yaml`):
```yaml
DB_HOST: pg-biblioteca-edu-alex25.postgres.database.azure.com
DB_PORT: "5432"
DB_SSL: "true"
RABBITMQ_URL: ""  # Vacío = usa Azure Service Bus
REDIS_URL: ""     # Se conecta via secret a Azure Managed Redis
```

### Gestión de Costos (Azure Education)

- El cluster AKS se detiene cuando no está en uso (`aks-stop.ps1`)
- Se inicia bajo demanda (`aks-start.ps1`)
- ACR Basic es de bajo costo (~$5/mes)
- Azure Database for PostgreSQL Flexible Server tiene costo (~$25/mes)
- Azure Managed Redis Standard C1 tiene costo (~$30/mes)
- Azure Service Bus Standard tiene costo (~$10/mes)

---

## 11. CI/CD

Los repositorios están separados, cada uno con su propio pipeline:

### Backend

**Archivo:** `biblioteca-microservicios/.github/workflows/backend-aks-ci-cd.yml`  
**Acción:** push a `main` en el repo backend

**Pipeline:**
1. Checkout del código
2. Validación (Node, .NET)
3. Build de 3 imágenes (identity, catalog, chatbot)
4. Push a ACR
5. Actualización de deployments en AKS
6. Rollback automático en caso de fallo del rollout
7. Health check post-deploy (`/health`, `/api/catalog/health`, `/api/chatbot/health`)
8. Inicialización de base de datos (ejecuta `init.sql` si hay base local)
9. Overlay configurable via variable `KUSTOMIZE_OVERLAY` (default: `aks-no-domain`)

### Frontend

**Archivo:** `Biblioteca-Frontend/.github/workflows/frontend-aks-ci-cd.yml`  
**Acción:** push a `main` en el repo frontend

**Pipeline:**
1. Checkout del código
2. Validación (lint + build)
3. Build de imagen Docker
4. Push a ACR (`acrbibliotecaedu.azurecr.io/biblioteca/frontend`)
5. Actualización del deployment en AKS
6. Rollback automático en caso de fallo del rollout
7. Health check post-deploy (HTTP 200/302 en la URL pública)
8. Overlay configurable via variable `KUSTOMIZE_OVERLAY` (default: `aks-no-domain`)

---

## 12. Equipo

| Miembro | Rol | Contribuciones |
|---------|-----|----------------|
| **Joshua** | Frontend Developer | React, Tailwind, API clients, Context/Hooks, componentes UI, lazy loading, AbortController |
| **Steve** | Backend + DevOps | Chatbot Service, integración multi-IA, Docker, Azure, CI/CD, Chain of Responsibility, Strategy |
| **Juan** | Backend Developer | Catalog Service, Identity Service, PostgreSQL, RabbitMQ, Hugging Face, CQRS, MediatR, Specification, TF-IDF, Facade, Decorator |

---

## 13. Estado Actual

### ✅ Completado y Operacional

- **Dominio:** `https://bibliotechu.duckdns.org` con SSL/TLS via Let's Encrypt
- **SSL/TLS:** cert-manager instalado + ClusterIssuer operativo + certificados emitidos y válidos
- **HTTP→HTTPS:** Redirect 308 configurado en los ingress
- **DuckDNS:** Token registrado, DNS actualizado a IP del ingress (`52.158.169.2`)
- **Repositorios separados:** Frontend y backend en repos independientes con CI/CD propio
- **Azure Service Bus:** Implementado y desplegado como reemplazo de RabbitMQ en producción
- **Azure Database for PostgreSQL:** En uso como base de datos gestionada
- **Azure Managed Redis:** En uso para Streams de eventos del chatbot
- **Frontend:** Build exitoso, lint sin errores
- **Backend:** Todos los servicios compilados y funcionando
- **AKS:** Todos los pods en estado `Running (1/1)`
- **Health checks:** Pasando en todos los servicios
- **CI/CD:** Health check post-deploy, rollback automático e init DB integrados
- **Chatbot:** Funcional con Gemini AI (probado end-to-end con JWT)
- **Redis Streams:** Almacenando eventos correctamente
- **Scripts de automatización:** Rollback, DNS update, cleanup, managed services creation
- **Credenciales por defecto:** `admin` / `admin`

### Patrones de Diseño — Estado Completo

Ver [ARQUITECTURA.md](ARQUITECTURA.md) para el análisis detallado de **27 patrones y principios** implementados, incluyendo:

- **SOLID:** SRP, OCP, LSP, ISP, DIP — todos verificados con evidencia
- **Gof:** Strategy, Observer, Facade, Decorator, Proxy, Chain of Responsibility, State, Builder, Factory, Singleton
- **Arquitectural:** CQRS, Mediator (MediatR), Specification, Repository, Circuit Breaker, Result Pattern, Outbox
- **Frontend:** AbortController, TanStack Query, custom hooks, Error Boundary, lazy loading

### Últimas Validaciones

- `npm run lint` ✅
- `npm run build` ✅
- `npm audit --audit-level=high` ✅
- `docker compose config --quiet` ✅
- `docker compose build` ✅
- `dotnet test` ✅
- Kustomize rendering (frontend + backend) ✅
- Endpoints de salud y funcionales verificados ✅

---

## 14. Guías y Documentación

| Archivo | Descripción | Estado |
|---------|-------------|--------|
| `README.md` | Descripción general del proyecto | Actual |
| `ARQUITECTURA.md` | Análisis detallado de patrones SOLID, diseño, mejoras frontend/backend | Nueva |
| `PROYECTO_COMPLETO.md` | Documentación completa del proyecto | **← Este archivo** |
| `ROADMAP.md` | Plan de mejora y evolución del proyecto | Actual |
| `GUIA_AKS.md` | Guía paso a paso para AKS con Azure Education | Actual |
| `Links.txt` | Enlaces a repositorios en GitHub | Actual |
| `.env.example` | Template de variables de entorno | Actual |
| `docker-compose.yml` | Orquestación para desarrollo local | Actual |

---

## 15. Planificación Futura

### Pendientes Inmediatos

| Prioridad | Tarea | Descripción |
|-----------|-------|-------------|
| Alta | Desplegar overlay `aks` en AKS | `kubectl apply -k biblioteca-microservicios/k8s/overlays/aks` y frontend equivalente |
| Alta | Ejecutar `setup-ssl.ps1` | Instalar cert-manager en AKS para que Let's Encrypt emita certificados |
| Alta | Ejecutar `update-dns.ps1` | Actualizar DuckDNS con la IP del ingress |
| Media | Eliminar dependencia de RabbitMQ | Ya no se usa en producción, remover del código si se desea |
| Media | Limpiar archivos de la era VM | Eliminar `GUIA_DESPLIEGUE_AZURE.md` y `cloud-init-docker.yml` |

### Corto Plazo

| Prioridad | Tarea | Descripción |
|-----------|-------|-------------|
| Media | Dashboard de monitoreo | Métricas de uso del chatbot y el catálogo |
| Media | Notificaciones de errores | Alertas cuando un health check falle |
| Baja | Separar completamente RabbitMQ del código | Ya no es necesario en producción |

### Mediano Plazo

| Prioridad | Tarea | Descripción |
|-----------|-------|-------------|
| Alta | Escalar replicas | 2-3 réplicas por servicio en producción |
| Alta | Más proveedores IA | Ampliar cadena de fallback del chatbot |
| Media | Mejoras en recomendaciones | Feedback loop: usuario califica recomendaciones |
| Media | Panel de analytics | Dashboard con métricas de uso (chatbot, catálogo) |
| Media | Implementar WebSockets | Streaming de respuestas del chatbot en tiempo real |
| Media | Internacionalización | Soporte multi-idioma (inglés, portugués) |
| Baja | App móvil | Versión React Native o PWA avanzada |

### Largo Plazo

| Prioridad | Tarea | Descripción |
|-----------|-------|-------------|
| Alta | Préstamos y reservas | Sistema completo de préstamos con fechas, multas y renovaciones |
| Alta | Notificaciones | Email/SMS para recordatorios de devolución |
| Media | Integración LDAP/SAML | Autenticación institucional (estudiantes y profesores) |
| Media | Módulo de adquisiciones | Sugerir y votar por nuevos libros |
| Media | Reportes avanzados | Exportar estadísticas en PDF/Excel |
| Baja | Módulo de eventos | Gestión de talleres, charlas y actividades de la biblioteca |
| Baja | Integración con OCLC/WorldCat | Enriquecer metadatos de libros |

---

## 16. Roadmap

```
2026 — Parcial I (Completado)
├── MVP funcional con 7 microservicios
├── Despliegue en AKS operativo (https://bibliotechu.duckdns.org)
├── 4 proveedores de IA integrados
├── Mensajería asíncrona (Azure Service Bus + Redis Streams)
├── Repositorios separados con CI/CD independiente
├── Azure Database for PostgreSQL Flexible Server
├── Azure Managed Redis
├── SSL/TLS con Let's Encrypt y cert-manager
├── Scripts de automatización (managed services, rollback, DNS, cleanup)
├── CI/CD pipelines con health check, rollback automático e init DB
└── Documentación completa

2027 (Mediano plazo)
├── Escalado horizontal
├── Analytics y monitoreo
├── WebSockets para chatbot
├── Internacionalización
└── App móvil

2028+ (Largo plazo)
├── Sistema de préstamos y reservas
├── Notificaciones multicanal
├── Integración LDAP/SAML
├── Módulo de adquisiciones
├── Reportes avanzados
└── Integración OCLC/WorldCat
```

---

## Variables de Entorno

```
# PostgreSQL (local)
POSTGRES_DB=catalog_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123

# Puertos
FRONTEND_PORT=4173
IDENTITY_PORT=5132
CATALOG_PORT=3002
CHATBOT_PORT=3003

# URLs de Servicios (Frontend - local)
VITE_AUTH_SERVICE_URL=http://localhost:5132
VITE_CATALOG_SERVICE_URL=http://localhost:3002
VITE_CHATBOT_SERVICE_URL=http://localhost:3003
CORS_ORIGINS=http://localhost:4173,http://localhost:5173

# AI - Recomendaciones
AI_PROVIDER=huggingface
HF_API_TOKEN=****
HF_MODEL=facebook/bart-large-mnli

# AI - Chatbot (Multi-Provider)
CHATBOT_PROVIDER=gemini
GEMINI_API_KEY=****
GEMINI_MODEL=gemini-2.5-flash
GROQ_API_KEY=****
GROQ_MODEL=llama-3.1-8b-instant
OPENROUTER_API_KEY=****
OPENROUTER_MODEL=mistralai/mistral-7b-instruct:free
OPENROUTER_REFERER=http://localhost:4173
OPENROUTER_TITLE=Biblioteca U

# Redis Streams (local)
REDIS_URL=redis://localhost:6379
CHATBOT_STREAM_NAME=chatbot_events
CHATBOT_STREAM_GROUP=chatbot_logger

# Azure Service Bus (Producción - opcional en local)
AZURE_SERVICE_BUS_CONNECTION_STRING=****
AZURE_SERVICE_BUS_QUEUE=library-logging-queue



---

## Anexo A — Guión de Demostración en Vivo

1. Verificar despliegue en AKS:
   ```powershell
   kubectl get pods -n biblioteca
   kubectl get ingress -n biblioteca
   ```
2. Abrir el frontend: `https://bibliotechu.duckdns.org`
3. Iniciar sesión: `admin` / `admin`
4. Abrir el widget de chatbot (esquina inferior derecha)
5. Preguntar: `Recomiendame un libro disponible sobre arquitectura de software.`
6. Validar que la respuesta incluye proveedor/modelo usado
7. Health checks:
   ```powershell
   Invoke-RestMethod "https://bibliotechu.duckdns.org/api/catalog/health"
   Invoke-RestMethod "https://bibliotechu.duckdns.org/api/chatbot/health"
   ```
8. Validar Redis Streams:
   ```powershell
   kubectl exec deployment/redis -n biblioteca -- redis-cli XLEN chatbot_events
   kubectl logs deployment/chatbot-service -n biblioteca --tail=120
   ```
9. Verificar eventos `chat.message.received` y `chat.message.completed` en logs

## Anexo B — Checklist de Entrega

- [x] Aplicación Dockerizada con Docker Compose
- [x] Despliegue en Azure Kubernetes Service (AKS)
- [x] SSL/TLS con Let's Encrypt y cert-manager
- [x] Dominio DuckDNS activo
- [x] CI/CD con GitHub Actions
- [x] Integración de IA: Hugging Face, Gemini, Groq, OpenRouter
- [x] Fallback automático entre proveedores IA
- [x] Mensajería asíncrona: Azure Service Bus + Redis Streams
- [x] Repositorios separados (frontend/backend) con CI/CD independiente
- [x] Documentación completa y guías reproducibles

## Anexo C — Referencias

- **ROADMAP.md**: Plan de mejora y evolución del proyecto
- **GUIA_AKS.md**: Guía paso a paso para AKS con Azure Education
- **Biblioteca-Frontend/DEPLOYMENT.md**: Despliegue y CI/CD del frontend
- **biblioteca-microservicios/DEPLOYMENT.md**: Despliegue y CI/CD del backend

---

> **BiblioTech** — Proyecto académico de la Universidad de los Llanos  
> Ingeniería de Sistemas | Mayo 2026
