# BiblioTech — Roadmap de Mejora

> Plan estratégico de evolución del proyecto post-entrega. Priorizado por fases.

## Verificación rápida del Roadmap

- **Fase 1 (Consolidación y Deuda Técnica):** ✅ Todos los items completados. Incluye: migración JWT a cookies httpOnly, `.env.example` unificado, rate limiting, correlation-id, Observer, CQRS, Mediator + Specification, Facade + Decorator, TF-IDF, AbortController, CatalogContextService seguro, Key Vault, Dapper, refresh tokens, Result Pattern.
- **Fase 2 (Observabilidad y Robustez):** ⏳ Parcial — pino, `/metrics`, circuit breaker, retry exponencial, Correlation ID, tests (13 archivos) implementados; faltan dashboard y alertas.
- **Fase 3 (Funcionalidades de Producto):** ❌ Pendiente — préstamos/reservas, notificaciones multicanal, feedback loop, WebSockets y i18n no implementados.
- **Fase 4 (Escalabilidad y Enterprise):** ❌ Pendiente — HPA, API Gateway, LDAP/SAML y otros items de largo plazo pendientes.


---

## Fase 1: Consolidación y Deuda Técnica (Inmediato — 0-4 semanas)

| Prioridad | Tarea | Motivación |
|-----------|-------|------------|
| Alta | ~~Fusionar documentación duplicada~~ ✅ Completado | Mantener una fuente única de verdad y reducir desinformación |
| Alta | ~~Mover JWT de `localStorage` a cookies `httpOnly`~~ ✅ Completado | Eliminar vulnerabilidad XSS sobre el token de acceso |
| Alta | ~~Unificar `.env.example` y documentar cada variable con descripción~~ ✅ Completado | Reducir errores de configuración en nuevos entornos |
| Media | ~~Eliminar dependencia residual de RabbitMQ en código cloud~~ ✅ Completado | Azure Service Bus ya reemplazó a RabbitMQ en producción |
| Baja | ~~Rate limiting en `catalog-service` y `chatbot-service`~~ ✅ Completado | express-rate-limit: 100/15min general, 30/hr AI, 50/hr chat |
| Baja | ~~Correlation-id / request-id en todos los servicios~~ ✅ Completado | Header X-Correlation-Id propagado frontend → backend .NET/Node |
| Media | ~~Patrón Observer en catalog-service~~ ✅ Completado | BookEventBus (EventEmitter) + MessagingObserver + LoggingObserver |

---

## Fase 2: Observabilidad y Robustez (Corto plazo — 1-2 meses)

| Prioridad | Tarea | Motivación | Estado |
|-----------|-------|------------|--------|
| Alta | Dashboard de monitoreo: métricas de chatbot (eventos/min, proveedor usado, fallos) y catálogo (búsquedas, recomendaciones) | Visibilidad operativa para demo y producción | ❌ Pendiente |
| Alta | ~~Logs estructurados (JSON) con `correlation-id`~~ | Facilitar debugging y auditoría | ✅ Completado (pino + correlationId middleware) |
| Alta | ~~Circuit Breaker para llamadas entre servicios y a APIs de IA~~ | Evitar cascada de fallos | ✅ Completado (AuthHttpClient: 3 fallos, 30s reset + retry exponencial) |
| Media | Alertas automatizadas: health check fallido, fallback de IA activado recurrentemente, error rate > threshold | Detección proactiva de problemas | ❌ Pendiente |
| Media | Tests automatizados: unitarios en cada servicio + tests de integración | Prevenir regresiones en despliegues | ⏳ Parcial (8 archivos de test, cobertura baja) |
| Baja | Health checks mejorados: verificar conectividad a DB, Redis, Service Bus | Detectar problemas de infraestructura | ❌ Pendiente |

---

## Fase 3: Funcionalidades de Producto (Mediano plazo — 3-6 meses)

| Prioridad | Tarea | Motivación |
|-----------|-------|------------|
| Alta | **Sistema de préstamos y reservas**: tabla `LOANS`, estados (`reserved`, `borrowed`, `returned`, `overdue`), fechas de vencimiento, multas | Funcionalidad core de toda biblioteca |
| Alta | **Notificaciones multicanal**: email/SMS para recordatorios de devolución (Azure Communication Services o SendGrid) | Reducir morosidad y mejorar UX |
| Media | **Feedback loop de recomendaciones**: usuario califica recomendaciones (`thumbs up/down`) para mejorar futuras sugerencias | Mejorar calidad del recomendador IA con datos reales |
| Media | **Panel de analytics**: dashboard con métricas de uso (libros más consultados, tópicos más preguntados al chatbot) | Datos para toma de decisiones de la biblioteca |
| Media | **WebSockets para chatbot**: streaming de respuestas token-a-token | UX moderna, sensación de respuesta en tiempo real |
| Media | **Internacionalización (i18n)**: soporte para inglés y portugués en el frontend | Alcance académico internacional |
| Baja | **PWA (Progressive Web App)**: service worker, icono en home screen, acceso offline del catálogo | Mejorar accesibilidad móvil sin desarrollar app nativa |

---

## Fase 4: Escalabilidad y Enterprise (Largo plazo — 6-12 meses)

| Prioridad | Tarea | Motivación |
|-----------|-------|------------|
| Alta | **HPA (Horizontal Pod Autoscaler)** en AKS para escalar réplicas según CPU/memory | Escalabilidad automática ante picos de uso |
| Alta | **API Gateway** (ingress-nginx avanzado o Azure API Management): centralizar rate limiting, auth, routing, y transformación cookie-to-header | Simplificar frontend y mejorar seguridad perimetral |
| Media | **Integración LDAP/SAML**: autenticación institucional de la universidad | SSO con credenciales universitarias existentes |
| Media | **Módulo de adquisiciones**: sugerir y votar por nuevos libros | Involucrar a la comunidad en la expansión del catálogo |
| Media | **Reportes avanzados**: exportar estadísticas en PDF/Excel | Entregables administrativos y académicos |
| Baja | **Integración OCLC/WorldCat**: enriquecer metadatos de libros con datos externos | Catalogación profesional y completa |
| Baja | **App móvil nativa** (React Native) o PWA avanzada | Acceso desde dispositivos móviles con experiencia nativa |

---

## Seguimiento de Decisiones Arquitectónicas (ADR)

| Fecha | Decisión | Estado |
|-------|----------|--------|
| 2026-05 | JWT en `localStorage` → cookies `httpOnly` | Completado |
| 2026-05 | Documentación unificada en `PROYECTO_COMPLETO.md` + `README.md` | Completado |
| 2026-05 | RabbitMQ local → Azure Service Bus en producción | Completado |
| 2026-05 | PostgreSQL/RabbitMQ/Redis in-cluster → Azure Managed Services | Completado |
| 2026-05 | Rate limiting con `express-rate-limit` en catalog-service y chatbot-service | Completado |
| 2026-05 | Correlation-ID: middleware en Node.js, .NET, y axios interceptor en frontend | Completado |
| 2026-05 | Observer Pattern: `BookEventBus` (Subject) + `MessagingObserver` + `LoggingObserver` | Completado |
| 2026-05 | Refresh tokens + cookie httpOnly en .NET Identity API | Completado |
| 2026-05 | Dapper para migración de raw SQL en repositorios .NET | Completado |
| 2026-05 | Circuit breaker + retry exponencial en AuthHttpClient (Node.js) | Completado |
| 2026-05 | TanStack Query (React Query) para fetching en AdminPage | Completado (parcial) |
| 2026-05 | Chain of Responsibility (AiProviderHandler) para fallback IA en chatbot | Completado |
| 2026-05 | Outbox pattern para eventos de libro (tabla `outbox_events` + worker) | Completado |
| 2026-05 | Lazy loading con `React.lazy()` + `Suspense` en frontend | Completado |
| 2026-06 | TF-IDF con `natural` para RetrievalEngine (reemplaza scoring manual) | Completado |
| 2026-06 | CQRS en BookController: `BookQueryController` + `BookCommandController` | Completado |
| 2026-06 | Mediator + Specification Pattern en .NET con MediatR | Completado |
| 2026-06 | Facade: `IBookRecommender` + `AiService` implementa la interfaz | Completado |
| 2026-06 | Decorator: `composeMiddleware()` en biblioteca-shared | Completado |
| 2026-06 | AbortController en AuthContext para cancelación de requests | Completado |
| 2026-06 | Azure Key Vault integrado para JWT Key | Completado |
| 2026-06 | CatalogContextService: token por request en lugar de estado mutable | Completado |
| 2026-06 | Repositorio root creado con submodules (Biblioteca-Frontend + microservicios) | Completado |
| 2026-06 | Documentación consolidada: ARQUITECTURA.md creado, docs actualizadas | Completado |

---

> **BiblioTech** — Proyecto académico de la Universidad de los Llanos  
> Ingeniería de Sistemas | Roadmap v1.0 | Mayo 2026
