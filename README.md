# Killercoda scenarios: new Kubernetes certification topics

Interactive [Killercoda](https://killercoda.com) scenarios covering topics recently added to the
CKA / CKAD curricula that weren't covered by existing scenarios.

| Scenario | Topics | Duration |
|---|---|---|
| [`gateway-api-nginx-fabric`](gateway-api-nginx-fabric) | Gateway API with NGINX Gateway Fabric v2.7.2: shared Gateway, `allowedRoutes`, `HTTPRoute`, canary, filters, TLS, `RateLimitPolicy`, `ReferenceGrant` | ~45 min |
| [`gateway-api-envoy`](gateway-api-envoy) | Gateway API with Envoy Gateway v1.9.2: `EnvoyProxy`, Ingress migration (`ingress2gateway`), `RequestMirror`, timeouts, `BackendTrafficPolicy`, `SecurityPolicy`, `egctl` | ~45 min |

## Layout

```
<scenario>/
├── index.json          # metadata, steps and image (kubernetes-kubeadm-1node)
├── intro.md / finish.md
├── setup/
│   ├── background.sh   # deploys the sample apps during the intro
│   └── foreground.sh   # waits until the environment is ready
├── assets/             # manifests copied to /root/assets
└── stepN/
    ├── text.md         # theory + task + collapsible solution
    ├── verify.sh       # "Check" button (exit 0 = passed)
    └── background.sh   # (optional) sets up troubleshooting exercises
```

`structure.json` defines the order of the scenarios in the Killercoda profile.

## Publishing

1. In Killercoda → *Creator* → *Repository*, connect this repository.
2. Add the deploy key and webhook Killercoda gives you to the GitHub repo settings.
3. Every `push` updates the scenarios.

## Updating versions

Versions are pinned in the `text.md` and `background.sh` files:

```bash
grep -rn 'v2.7.2\|v1.9.2\|v1.2.0\|echo-basic' .
```

Tested end to end (every solution command + `verify.sh`) on a `kind` cluster running
Kubernetes 1.34 on 2026-09-29.
