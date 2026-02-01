# Qbittorrent-Vpn Helm Chart

[![Version: 0.3.1](https://img.shields.io/badge/Version-0.3.1-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 5.1.4](https://img.shields.io/badge/AppVersion-5.1.4-informational?style=flat-square)](Chart.yaml)

qBittorrent with Gluetun VPN sidecar

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install qbittorrent-vpn bdclark/qbittorrent-vpn -f values.yaml
```

## Gluetun Sidecar

[Gluetun](https://github.com/qdm12/gluetun) runs as a sidecar to route all traffic through a VPN tunnel.
By default it runs as a native sidecar (requires Kubernetes 1.29+). Set `gluetun.lifecycleMode: standard`
for older clusters.

Gluetun requires provider-specific configuration via environment variables. See the
[Gluetun wiki](https://github.com/qdm12/gluetun-wiki) for setup details.

### Control Server Authentication

Gluetun's [control server](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/control-server.md)
can be protected with role-based authentication. Enable `gluetun.controlServer` to mount a TOML config file:

```yaml
gluetun:
  env:
    HTTP_CONTROL_SERVER_AUTH_CONFIG: /gluetun/auth/config.toml
  controlServer:
    enabled: true
    config: |
      [[roles]]
      name = "readonly"
      routes = ["GET /v1/publicip/ip"]
      auth = "apikey"
      apikey = "my-secret-key"
```

For production, use an existing Secret instead of inline config:

```yaml
gluetun:
  controlServer:
    enabled: true
    existingSecret:
      name: gluetun-control-auth
      key: config.toml
```

### Control Server Service

To expose the Gluetun control server within the cluster, enable the dedicated service:

```yaml
gluetun:
  service:
    enabled: true
    port: 8000
```

This creates a separate Service for the control server API (default port 8000), allowing other
applications to query VPN status or trigger actions via the
[control server endpoints](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/control-server.md).

## Environment Variables

Both containers support environment variables via `env` (inline values or refs) and `envFrom` (bulk refs).

```yaml
qbittorrent:
  env:
    TZ: America/New_York
    PUID: "1000"
    PGID: "1000"

gluetun:
  env:
    VPN_SERVICE_PROVIDER: protonvpn
    VPN_TYPE: wireguard
    SERVER_COUNTRIES: Netherlands
    WIREGUARD_PRIVATE_KEY:
      valueFrom:
        secretKeyRef:
          name: gluetun-vpn
          key: wireguard-private-key
```

For bulk environment variables from ConfigMaps or Secrets:

```yaml
gluetun:
  envFrom:
    - secretRef:
        name: gluetun-credentials
```

## qBittorrent Config Bootstrapping

The chart can seed a qBittorrent config file on first run when `qbittorrent.config.bootstrap.enabled`
is true (the default). Inline config creates a ConfigMap automatically:

```yaml
qbittorrent:
  config:
    bootstrap:
      enabled: true
      config: |
        [LegalNotice]
        Accepted=true

        [Preferences]
        Downloads\SavePath=/downloads/
        WebUI\Address=*
```

To use an existing ConfigMap or Secret:

```yaml
qbittorrent:
  config:
    bootstrap:
      existingConfig:
        type: secret  # or "configMap"
        name: qbittorrent-config
        key: qBittorrent.conf
```

## WebUI Password

The WebUI password can be injected from a Secret containing a PBKDF2-hashed password.
Generate one externally or extract from an existing qBittorrent config.

```yaml
qbittorrent:
  config:
    bootstrap:
      webuiPassword:
        mode: ifMissing  # or "overwrite"
        existingSecret:
          name: qbittorrent-webui
          key: WebUI_Password_PBKDF2
```

Modes:

- `disabled` - no password management (default)
- `ifMissing` - set only if not already present in config
- `overwrite` - replace password on every container start

## Persistence

Config persistence is enabled by default. Downloads persistence must be explicitly enabled.

```yaml
qbittorrent:
  persistence:
    config:
      enabled: true
      size: 2Gi
    downloads:
      enabled: true
      size: 100Gi
      storageClass: fast-storage
      # existingClaim: my-downloads-pvc
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Override the release name. |
| fullnameOverride | string | `""` | Override the full release name. |
| replicaCount | int | `1` | Number of replicas. |
| strategy | object | `{"type":"Recreate"}` | Deployment update strategy. |
| imagePullSecrets | list | `[]` | Image pull secrets. |
| deploymentAnnotations | object | `{}` | Annotations for the Deployment. |
| extraDeploymentLabels | object | `{}` | Additional labels for the Deployment. |
| podAnnotations | object | `{}` | Annotations for pods. |
| podLabels | object | `{}` | Additional labels for pods. |
| podSecurityContext | object | `{}` | Pod security context. |
| qbittorrent.image.repository | string | `"lscr.io/linuxserver/qbittorrent"` | Image repository. |
| qbittorrent.image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| qbittorrent.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| qbittorrent.securityContext | object | `{}` | Container security context. |
| qbittorrent.resources | object | `{}` | Resource requests and limits. |
| qbittorrent.ports | list | `[{"containerPort":8080,"name":"http","protocol":"TCP"}]` | Container ports. |
| qbittorrent.startupProbe | object | `{}` | Startup probe configuration. |
| qbittorrent.livenessProbe | object | `{}` | Liveness probe configuration. |
| qbittorrent.readinessProbe | object | `{}` | Readiness probe configuration. |
| qbittorrent.env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| qbittorrent.envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| qbittorrent.config.mountPath | string | `"/config/qBittorrent"` | Directory containing the configuration file. |
| qbittorrent.config.fileName | string | `"qBittorrent.conf"` | Configuration file name. |
| qbittorrent.config.bootstrap.enabled | bool | `true` | Create config file if missing. |
| qbittorrent.config.bootstrap.config | string | Sane defaults for containerized deployment. | Initial configuration content (used when existingConfig.type is empty). |
| qbittorrent.config.bootstrap.existingConfig.type | string | `""` | Source type for existing config: "configMap", "secret", or "" (use bootstrap.config). |
| qbittorrent.config.bootstrap.existingConfig.name | string | `""` | Name of the ConfigMap or Secret. |
| qbittorrent.config.bootstrap.existingConfig.key | string | `"qBittorrent.conf"` | Key containing the configuration data. |
| qbittorrent.config.bootstrap.webuiPassword.mode | string | `"disabled"` | Password injection mode: "disabled", "ifMissing", or "overwrite". Requires bootstrap.enabled=true. |
| qbittorrent.config.bootstrap.webuiPassword.existingSecret.name | string | `"qbittorrent-webui"` | Secret name containing the PBKDF2-hashed password. |
| qbittorrent.config.bootstrap.webuiPassword.existingSecret.key | string | `"WebUI_Password_PBKDF2"` | Secret key for the password. |
| qbittorrent.persistence.config.enabled | bool | `true` | Enable config persistence. |
| qbittorrent.persistence.config.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| qbittorrent.persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| qbittorrent.persistence.config.size | string | `"2Gi"` | Volume size. |
| qbittorrent.persistence.config.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| qbittorrent.persistence.config.annotations | object | `{}` | PVC annotations. |
| qbittorrent.persistence.downloads.enabled | bool | `false` | Enable downloads persistence. |
| qbittorrent.persistence.downloads.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| qbittorrent.persistence.downloads.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| qbittorrent.persistence.downloads.size | string | `"2Gi"` | Volume size. |
| qbittorrent.persistence.downloads.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| qbittorrent.persistence.downloads.annotations | object | `{}` | PVC annotations. |
| qbittorrent.volumeMounts | list | `[]` | Additional volume mounts. |
| qbittorrent.service.type | string | `"ClusterIP"` | Service type. |
| qbittorrent.service.port | int | `8080` | Service port. |
| qbittorrent.ingress.enabled | bool | `false` | Enable Ingress. |
| qbittorrent.ingress.className | string | `""` | Ingress class name. |
| qbittorrent.ingress.annotations | object | `{}` | Ingress annotations. |
| qbittorrent.ingress.hosts | list | `[{"host":"qbittorrent.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| qbittorrent.ingress.tls | list | `[]` | Ingress TLS configuration. |
| gluetun.enabled | bool | `true` | Enable VPN sidecar. |
| gluetun.lifecycleMode | string | `"nativeSidecar"` | Lifecycle mode: "nativeSidecar" or "standard". Native sidecars (initContainer with restartPolicy Always) require Kubernetes 1.29+. |
| gluetun.lifecycleHooks | object | `{}` | Container lifecycle hooks. |
| gluetun.image.repository | string | `"qmcgaw/gluetun"` | Image repository. |
| gluetun.image.tag | string | `"v3.41.0"` | Image tag. |
| gluetun.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| gluetun.needsTunDevice | bool | `true` | Mount /dev/net/tun device. |
| gluetun.securityContext | object | `{"capabilities":{"add":["NET_ADMIN"]}}` | Container security context. |
| gluetun.resources | object | `{}` | Resource requests and limits. |
| gluetun.ports | list | `[]` | Container ports. |
| gluetun.startupProbe | object | `{}` | Startup probe configuration. |
| gluetun.livenessProbe | object | `{}` | Liveness probe configuration. |
| gluetun.readinessProbe | object | `{}` | Readiness probe configuration. |
| gluetun.env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| gluetun.envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| gluetun.persistence.enabled | bool | `false` | Enable persistence. |
| gluetun.persistence.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| gluetun.persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| gluetun.persistence.size | string | `"200Mi"` | Volume size. |
| gluetun.persistence.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| gluetun.persistence.annotations | object | `{}` | PVC annotations. |
| gluetun.volumeMounts | list | `[]` | Additional volume mounts. |
| gluetun.controlServer.enabled | bool | `false` | Enable control server authentication config file. |
| gluetun.controlServer.mountPath | string | `"/gluetun/auth"` | Mount path for the auth config directory. |
| gluetun.controlServer.fileName | string | `"config.toml"` | Config file name. |
| gluetun.controlServer.existingSecret.name | string | `""` | Name of an existing Secret containing the TOML config. If empty and config is set, a Secret will be created from the inline config. |
| gluetun.controlServer.existingSecret.key | string | `"config.toml"` | Key within the Secret. |
| gluetun.controlServer.config | string | "" (disabled) | Inline TOML config. Creates a chart-managed Secret when existingSecret.name is empty. Visible in Helm values/history, so not recommended for production. |
| gluetun.service.enabled | bool | `false` | Enable gluetun control server service. |
| gluetun.service.type | string | `"ClusterIP"` | Service type. |
| gluetun.service.port | int | `8000` | Service port. |
| initContainers | list | `[]` | Additional init containers (run before gluetun if native sidecar mode). |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
