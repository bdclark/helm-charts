# Sonarr Helm Chart

[![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 4.0.16](https://img.shields.io/badge/AppVersion-4.0.16-informational?style=flat-square)](Chart.yaml)

TV show organizer/manager for usenet and torrent users

> [!NOTE]
> This chart is under active development. Breaking changes may occur between minor versions.

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install sonarr bdclark/sonarr -f values.yaml
```

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

### LinuxServer Variables

This chart uses the [LinuxServer.io](https://docs.linuxserver.io/images/docker-sonarr/) Sonarr image,
which supports common environment variables:

```yaml
env:
  TZ: America/New_York
  PUID: "1000"
  PGID: "1000"
```

### Sonarr Configuration Overrides

Sonarr supports environment variables to override entries in `config.xml`. Variables follow the pattern
`SONARR__<NAMESPACE>__<SETTING>`. See the [Servarr Wiki](https://wiki.servarr.com/sonarr/environment-variables)
for details.

```yaml
env:
  # Server settings
  SONARR__SERVER__PORT: "8989"
  SONARR__SERVER__URLBASE: /sonarr
  # Logging
  SONARR__LOG__LEVEL: info
  # Authentication
  SONARR__AUTH__METHOD: Forms
  SONARR__AUTH__REQUIRED: Enabled
  # PostgreSQL (optional - replaces SQLite)
  SONARR__POSTGRES__HOST: postgres
  SONARR__POSTGRES__PORT: "5432"
  SONARR__POSTGRES__USER: sonarr
  SONARR__POSTGRES__MAINDB: sonarr-main
  SONARR__POSTGRES__LOGDB: sonarr-log
  SONARR__POSTGRES__PASSWORD:
    valueFrom:
      secretKeyRef:
        name: sonarr-postgres
        key: password
```

### Bulk Environment Variables

For bulk environment variables from ConfigMaps or Secrets:

```yaml
envFrom:
  - secretRef:
      name: sonarr-credentials
  - configMapRef:
      name: sonarr-config
```

## Persistence

Two persistent volumes are available: `config` for Sonarr's database and settings, and `data` for media files.
Both are enabled by default.

```yaml
persistence:
  config:
    enabled: true
    size: 1Gi
    # storageClass: ""
    # existingClaim: sonarr-config
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
    existingClaim: sonarr-config
  data:
    enabled: true
    existingClaim: shared-media
```

### Additional Volumes

For more complex storage setups, use `volumes` and `volumeMounts`:

```yaml
volumes:
  - name: tv
    nfs:
      server: nas.local
      path: /volume1/tv
  - name: downloads
    persistentVolumeClaim:
      claimName: downloads-pvc

volumeMounts:
  - name: tv
    mountPath: /tv
  - name: downloads
    mountPath: /downloads
```

## Config Bootstrapping

The chart can seed Sonarr's `config.xml` on first run when `bootstrap.enabled` is true.
This is useful for pre-configuring settings before Sonarr starts. The config file is only
created if it doesn't already exist, so existing configurations are preserved.

> [!NOTE]
> Bootstrap requires `persistence.config.enabled` to be true.

Inline config creates a ConfigMap automatically:

```yaml
bootstrap:
  enabled: true
  config: |
    <Config>
      <UrlBase>/sonarr</UrlBase>
      <AuthenticationMethod>Forms</AuthenticationMethod>
    </Config>
```

To use an existing ConfigMap or Secret:

```yaml
bootstrap:
  enabled: true
  existingConfig:
    type: secret  # or "configMap"
    name: sonarr-config
    key: config.xml
```

## Ingress

Enable ingress to expose Sonarr externally:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: sonarr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: sonarr-tls
      hosts:
        - sonarr.example.com
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
| image.repository | string | `"lscr.io/linuxserver/sonarr"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| securityContext | object | `{}` | Container security context. |
| resources | object | `{}` | Resource requests and limits. |
| ports | list | `[{"containerPort":8989,"name":"http","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| bootstrap.enabled | bool | `false` | Create a config.xml file if missing. Requires persistence.config.enabled=true. |
| bootstrap.mountPath | string | `"/config"` | Directory containing the configuration file. |
| bootstrap.config | string | Sane defaults for containerized deployment. | Initial configuration content (used when existingConfig.type is empty). |
| bootstrap.existingConfig.type | string | `""` | Source type for existing config: "configMap", "secret", or "" (use bootstrap.config). |
| bootstrap.existingConfig.name | string | `""` | Name of the ConfigMap or Secret. |
| bootstrap.existingConfig.key | string | `"config.xml"` | Key containing the configuration data. |
| persistence.config.enabled | bool | `true` | Enable persistence for config. |
| persistence.config.mountPath | string | `"/config"` | Mount path. |
| persistence.config.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.config.size | string | `"1Gi"` | Volume size. |
| persistence.config.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.config.annotations | object | `{}` | PVC annotations. |
| persistence.data.enabled | bool | `true` | Enable persistence for data. |
| persistence.data.mountPath | string | `"/data"` | Mount path. |
| persistence.data.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.data.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.data.size | string | `"100Gi"` | Volume size. |
| persistence.data.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.data.annotations | object | `{}` | PVC annotations. |
| volumeMounts | list | `[]` | Additional volume mounts. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `8989` | Service port. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"sonarr.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| initContainers | list | `[]` | Additional init containers. |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
