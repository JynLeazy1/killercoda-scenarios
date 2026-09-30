# ¡Escenario completado!

Practicaste los puntos de Gateway API que aparecen en CKA/CKAD:

* Instalación de CRDs (canal standard) y de una implementación (NGINX Gateway Fabric)
* `GatewayClass` → `Gateway` → `HTTPRoute` y el modelo orientado a roles
* `allowedRoutes` con selector de namespaces y `sectionName`
* Match por path (`Exact`/`PathPrefix`) y headers, precedencia de reglas
* Traffic splitting con `weight`
* Filtros `RequestHeaderModifier`, `ResponseHeaderModifier`, `URLRewrite`, `RequestRedirect`
* Terminación TLS y redirección HTTP → HTTPS
* Policy Attachment (`RateLimitPolicy`)
* Diagnóstico mediante `status.conditions` y `ReferenceGrant`

### Chuleta para el examen

```bash
kubectl explain httproute.spec.rules --recursive | less   # sintaxis sin salir de la terminal
kubectl get gateway,httproute -A
kubectl describe httproute <nombre> -n <ns>              # Accepted / ResolvedRefs
```

**Siguiente paso:** el escenario *Gateway API con Envoy Gateway* cubre la migración desde
`Ingress`, `RequestMirror` y las políticas de Envoy (rate limit, retries, autenticación).
