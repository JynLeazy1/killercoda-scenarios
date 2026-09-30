# ¡Escenario completado!

Practicaste:

* Instalación de Envoy Gateway y `parametersRef` → `EnvoyProxy`
* `Gateway` y `HTTPRoute` con Envoy como data plane
* Migración de `Ingress` a `HTTPRoute` (manual y con `ingress2gateway`)
* `RequestMirror` (shadow traffic) y traffic splitting con `weight`
* `timeouts` estándar de `HTTPRoute`
* `BackendTrafficPolicy`: retries y rate limiting local
* `SecurityPolicy`: Basic Auth
* Diagnóstico con `status`, `egctl x status` y `egctl config envoy-proxy`

### NGINX Gateway Fabric vs Envoy Gateway

| | NGINX Gateway Fabric | Envoy Gateway |
|---|---|---|
| Data plane | NGINX | Envoy |
| Dónde crea el data plane | Namespace del `Gateway` | `envoy-gateway-system` |
| Parámetros de la clase | `NginxProxy` | `EnvoyProxy` |
| Rate limiting | `RateLimitPolicy` | `BackendTrafficPolicy.rateLimit` |
| Autenticación | `AuthenticationFilter` | `SecurityPolicy` |
| CLI de diagnóstico | — (`kubectl`, logs) | `egctl` |

Lo **portable** entre ambos: `GatewayClass`, `Gateway`, `HTTPRoute`, `ReferenceGrant`, filtros
estándar, `weight` y `timeouts`. Lo **no portable**: las políticas de cada implementación.
