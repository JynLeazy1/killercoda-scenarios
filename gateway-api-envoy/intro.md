# Gateway API con Envoy Gateway

**Envoy Gateway** es el proyecto de la CNCF que usa **Envoy Proxy** como plano de datos para
implementar la Gateway API. Es la base de muchos productos (y de otras implementaciones como
Istio o Contour, que también usan Envoy).

Tras el retiro de **ingress-nginx** (fin de mantenimiento en marzo de 2026), migrar `Ingress` a
Gateway API es una tarea habitual y un tema de examen.

## Arquitectura

```
          ┌───────────────────────────┐      xDS      ┌───────────────────────┐
 Gateway  │  envoy-gateway            │ ───────────▶  │  Envoy (data plane)   │ ◀── tráfico
 HTTPRoute│  (control plane, traduce  │               │  1 Deployment+Service │
 Policies │   recursos K8s a xDS)     │               │  por cada Gateway     │
          └───────────────────────────┘               └───────────────────────┘
```

## Lo que vas a hacer

1. Instalar Envoy Gateway y configurar el data plane como `NodePort` con `EnvoyProxy`
2. Crear un `Gateway` y una `HTTPRoute`
3. Migrar un `Ingress` existente a `HTTPRoute` (manual y con `ingress2gateway`)
4. Hacer *shadow traffic* con `RequestMirror` y luego un *traffic split*
5. Aplicar rate limiting, timeouts y retries con `BackendTrafficPolicy`
6. Proteger una ruta con autenticación básica usando `SecurityPolicy`
7. Diagnosticar configuraciones rotas con `status` y `egctl`

> Mientras lees esto se despliegan las apps `web`, `api` y `api-v2` y un `Ingress` llamado `shop`
> en el namespace `apps`.
