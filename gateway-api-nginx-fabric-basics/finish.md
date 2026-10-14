# Part 1 complete!

You practiced the Gateway API fundamentals that show up in CKA/CKAD:

* Installing the CRDs (standard channel) and an implementation (NGINX Gateway Fabric)
* `GatewayClass` → `Gateway` → `HTTPRoute` and the role-oriented model
* `allowedRoutes` with a namespace selector
* Path (`Exact`/`PathPrefix`) and header matching, rule precedence
* Traffic splitting with `weight`

### Exam cheat sheet

```bash
kubectl explain httproute.spec.rules --recursive | less   # syntax without leaving the terminal
kubectl get gateway,httproute -A
kubectl describe httproute <name> -n <ns>                # Accepted / ResolvedRefs
```

**Next:** *Gateway API with NGINX Gateway Fabric - Part 2: Advanced* starts from exactly this
state (Gateway `cafe-gw` and routes `coffee` and `tea`) and covers filters, TLS, HTTP → HTTPS
redirect, `RateLimitPolicy` and troubleshooting with `ReferenceGrant`.
