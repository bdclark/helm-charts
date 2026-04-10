# Chaptarr Helm Chart

[![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 0.9.333](https://img.shields.io/badge/AppVersion-0.9.333-informational?style=flat-square)](Chart.yaml)

Ebook and audiobook organizer/manager for usenet and torrent users

> [!NOTE]
> This chart is under active development. Breaking changes may occur between minor versions.

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install chaptarr bdclark/chaptarr -f values.yaml
```

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

The `robertlordhood/chaptarr` image supports these common environment variables:

```yaml
env:
  TZ: America/New_York
  PUID: "1000"
  PGID: "1000"
```

### Bulk Environment Variables

For bulk environment variables from ConfigMaps or Secrets:

```yaml
envFrom:
  - secretRef:
      name: chaptarr-credentials
  - configMapRef:
      name: chaptarr-config
```

## Persistence

Two persistent volumes are available: `config` for Chaptarr's database and settings, and `data` for media files.
Both are enabled by default.

```yaml
persistence:
  config:
    enabled: true
    size: 1Gi
    # storageClass: ""
    # existingClaim: chaptarr-config
  data:
    enabled: true
    size: 100Gi
    mountPath: /data
    # storageClass: ""
    # existingClaim: media-library
```

### Using Existing Claims

To use pre-existing PVCs (useful for shared media libraries):

```yaml
persistence:
  config:
    enabled: true
    existingClaim: chaptarr-config
  data:
    enabled: true
    existingClaim: shared-media
```

### Additional Volumes

For more complex storage setups, use `volumes` and `volumeMounts`:

```yaml
volumes:
  - name: books
    nfs:
      server: nas.local
      path: /volume1/books
  - name: downloads
    persistentVolumeClaim:
      claimName: downloads-pvc

volumeMounts:
  - name: books
    mountPath: /books
  - name: downloads
    mountPath: /downloads
```

## Config Bootstrapping

The chart can seed Chaptarr's `config.xml` on first run when `bootstrap.enabled` is true.
This is useful for pre-configuring settings before Chaptarr starts. By default, the config
file is only created if it doesn't already exist, preserving existing configurations.

> [!NOTE]
> Bootstrap requires `persistence.config.enabled` to be true.

Inline config creates a ConfigMap automatically:

```yaml
bootstrap:
  enabled: true
  config: |
    <Config>
      <UrlBase>/chaptarr</UrlBase>
      <AuthenticationMethod>Forms</AuthenticationMethod>
    </Config>
```

To use an existing ConfigMap or Secret:

```yaml
bootstrap:
  enabled: true
  existingConfig:
    type: secret  # or "configMap"
    name: chaptarr-config
    key: config.xml
```

### Enforcing Configuration (GitOps)

For GitOps workflows where the configuration should always match the source of truth,
set `bootstrap.overwrite` to true. This overwrites `config.xml` on every pod startup:

```yaml
bootstrap:
  enabled: true
  overwrite: true
  existingConfig:
    type: secret
    name: chaptarr-config
    key: config.xml
```

> [!WARNING]
> With `overwrite: true`, any changes made through the Chaptarr UI will be lost on pod restart.

## Ingress

Enable ingress to expose Chaptarr externally:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: chaptarr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: chaptarr-tls
      hosts:
        - chaptarr.example.com
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
| commonLabels | object | `{}` | Labels to add to all resources. |
| podSecurityContext | object | `{}` | Pod security context. |
| image.repository | string | `"robertlordhood/chaptarr"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| securityContext | object | `{}` | Container security context. |
| resources | object | `{}` | Resource requests and limits. |
| ports | list | `[{"containerPort":8789,"name":"http","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| bootstrap.enabled | bool | `false` | Create a config.xml file if missing. Requires persistence.config.enabled=true. |
| bootstrap.overwrite | bool | `false` | If true, overwrite config on every startup (useful for GitOps). |
| bootstrap.mountPath | string | `"/config"` | Directory containing the configuration file. |
| bootstrap.config | string | Sane defaults for containerized deployment. | Initial configuration content (used when existingConfig.type is empty). |
| bootstrap.existingConfig.type | string | `""` | Source type for existing config: "configMap", "secret", or "" (use bootstrap.config). |
| bootstrap.existingConfig.name | string | `""` | Name of the ConfigMap or Secret. |
| bootstrap.existingConfig.key | string | `"config.xml"` | Key containing the configuration data. |
| persistence.config.enabled | bool | `true` | Enable persistence for config. |
| persistence.config.mountPath | string | `"/config"` | Mount path. |
| persistence.config.subPath | string | `""` | Subdirectory of the volume to mount (optional). |
| persistence.config.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.config.size | string | `"1Gi"` | Volume size. |
| persistence.config.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.config.annotations | object | `{}` | PVC annotations. |
| persistence.data.enabled | bool | `true` | Enable persistence for data. |
| persistence.data.mountPath | string | `"/data"` | Mount path. |
| persistence.data.subPath | string | `""` | Subdirectory of the volume to mount (optional). |
| persistence.data.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.data.size | string | `"100Gi"` | Volume size. |
| persistence.data.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.data.annotations | object | `{}` | PVC annotations. |
| volumeMounts | list | `[]` | Additional volume mounts. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `8789` | Service port. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"chaptarr.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| initContainers | list | `[]` | Additional init containers. |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
