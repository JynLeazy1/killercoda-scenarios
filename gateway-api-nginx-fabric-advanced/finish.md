# Scenario complete!

Across both parts you practiced the Gateway API topics that show up in CKA/CKAD. In this part:

* `RequestHeaderModifier`, `ResponseHeaderModifier`, `URLRewrite` and `RequestRedirect` filters
* TLS termination, `sectionName` and HTTP → HTTPS redirect
* Policy Attachment (`RateLimitPolicy`)
* Troubleshooting with `status.conditions` and `ReferenceGrant`

### Exam cheat sheet

```bash
kubectl explain httproute.spec.rules --recursive | less   # syntax without leaving the terminal
kubectl get gateway,httproute -A
kubectl describe httproute <name> -n <ns>                # Accepted / ResolvedRefs
```

**Next:** the *Gateway API with Envoy Gateway* labs cover migrating from `Ingress`,
`RequestMirror` and Envoy's policies (rate limit, retries, authentication).
