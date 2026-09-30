# Scenario complete!

You practiced the Gateway API topics that show up in CKA/CKAD:

* Installing the CRDs (standard channel) and an implementation (NGINX Gateway Fabric)
* `GatewayClass` → `Gateway` → `HTTPRoute` and the role-oriented model
* `allowedRoutes` with a namespace selector, and `sectionName`
* Path (`Exact`/`PathPrefix`) and header matching, rule precedence
* Traffic splitting with `weight`
* `RequestHeaderModifier`, `ResponseHeaderModifier`, `URLRewrite` and `RequestRedirect` filters
* TLS termination and HTTP → HTTPS redirect
* Policy Attachment (`RateLimitPolicy`)
* Troubleshooting with `status.conditions` and `ReferenceGrant`

### Exam cheat sheet

```bash
kubectl explain httproute.spec.rules --recursive | less   # syntax without leaving the terminal
kubectl get gateway,httproute -A
kubectl describe httproute <name> -n <ns>                # Accepted / ResolvedRefs
```

**Next:** the *Gateway API with Envoy Gateway* scenario covers migrating from `Ingress`,
`RequestMirror` and Envoy's policies (rate limit, retries, authentication).
