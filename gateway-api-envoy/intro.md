# Gateway API with Envoy Gateway

**Envoy Gateway** is the CNCF project that uses **Envoy Proxy** as the data plane to implement
Gateway API. It is the foundation of many products (and other implementations such as Istio or
Contour also use Envoy).

With the retirement of **ingress-nginx** (end of maintenance in March 2026), migrating `Ingress`
to Gateway API is a common task and an exam topic.

## Architecture

```
          ┌───────────────────────────┐      xDS      ┌───────────────────────┐
 Gateway  │  envoy-gateway            │ ───────────▶  │  Envoy (data plane)   │ ◀── traffic
 HTTPRoute│  (control plane, turns    │               │  1 Deployment+Service │
 Policies │   K8s resources into xDS) │               │  per Gateway          │
          └───────────────────────────┘               └───────────────────────┘
```

## What you will do

1. Install Envoy Gateway and configure the data plane as a `NodePort` with `EnvoyProxy`
2. Create a `Gateway` and an `HTTPRoute`
3. Migrate an existing `Ingress` to `HTTPRoute` (by hand and with `ingress2gateway`)
4. Shadow traffic with `RequestMirror`, then a *traffic split*
5. Apply rate limiting, timeouts and retries with `BackendTrafficPolicy`
6. Protect a route with basic authentication using `SecurityPolicy`
7. Troubleshoot broken configuration with `status` and `egctl`

> While you read this, the apps `web`, `api` and `api-v2` and an `Ingress` named `shop` are being
> deployed into the `apps` namespace.
