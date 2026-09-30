# Canary: pesos y match por header

Queremos lanzar `coffee-v2` de forma progresiva:

* Quien envíe el header `x-version: v2` siempre llega a **v2** (pruebas internas).
* El resto del tráfico se reparte **80 % v1 / 20 % v2**.

### Tarea

Modifica la ruta `coffee` para implementar ese comportamiento.

<details>
<summary>Solución</summary>

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: coffee
  namespace: cafe
spec:
  parentRefs:
  - name: cafe-gw
    namespace: infra
  hostnames:
  - cafe.example
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /coffee
      headers:
      - name: x-version
        value: v2
    backendRefs:
    - name: coffee-v2
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /coffee
    backendRefs:
    - name: coffee-v1
      port: 80
      weight: 80
    - name: coffee-v2
      port: 80
      weight: 20
YAML
```{{exec}}

</details>

### Prueba el reparto

```bash
for i in $(seq 1 50); do
  curl -s -H "Host: cafe.example" http://$NODE_IP:30080/coffee | grep -oE 'coffee-v[12]' | head -1
done | sort | uniq -c
```{{exec}}

Y el match por header:

```bash
for i in $(seq 1 5); do
  curl -s -H "Host: cafe.example" -H "x-version: v2" http://$NODE_IP:30080/coffee | grep -oE 'coffee-v[12]' | head -1
done
```{{exec}}

> **Precedencia:** cuando varias reglas coinciden, gana la más específica (path exacto antes que
> prefijo, prefijo más largo, más headers, más query params...). Por eso la regla con header
> gana aunque ambas usen `/coffee`. Un `weight: 0` desactiva un backend sin borrarlo.
