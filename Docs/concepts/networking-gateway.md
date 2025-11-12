# Networking & Gateway

The platform exposes services via Gateway API with TLS certificates issued by
cert-manager. For local demo, wildcard domains use `sslip.io`.

## Gateway

- Central Gateway resource terminates TLS
- Hostname-based routing to per-component `HTTPRoute`s

## Certificates

- A `ClusterIssuer` provides a wildcard certificate for `*.127-0-0-1.sslip.io`
- Gateway references the TLS secret

See the [Gateway API diagram](../architecture/visual.md#_8-gateway-api-service-exposure) for the full flow.

