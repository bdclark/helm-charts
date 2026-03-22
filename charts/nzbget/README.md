# Nzbget Helm Chart

[![Version: 0.1.4](https://img.shields.io/badge/Version-0.1.4-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 26.0.20260320](https://img.shields.io/badge/AppVersion-26.0.20260320-informational?style=flat-square)](Chart.yaml)

Usenet downloader

> [!NOTE]
> This chart is under active development. Breaking changes may occur between minor versions.

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install nzbget bdclark/nzbget -f values.yaml
```

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

### LinuxServer Variables

This chart uses the [LinuxServer.io](https://docs.linuxserver.io/images/docker-nzbget/) NZBGet image,
which supports common environment variables:

```yaml
env:
  TZ: America/New_York
  PUID: "1000"
  PGID: "1000"
```

### NZBGet Configuration

NZBGet stores its configuration in `/config/nzbget.conf`. Unlike some applications, NZBGet does not
support environment variable overrides for its config file. Configuration changes should be made
through the web UI or by bootstrapping an initial config file.

### Bulk Environment Variables

For bulk environment variables from ConfigMaps or Secrets:

```yaml
envFrom:
  - secretRef:
      name: nzbget-credentials
  - configMapRef:
      name: nzbget-config
```

## Persistence

Two persistent volumes are available: `config` for NZBGet's configuration and queue data, and `data`
for downloads. Both are enabled by default.

```yaml
persistence:
  config:
    enabled: true
    size: 1Gi
    # storageClass: ""
    # existingClaim: nzbget-config
  data:
    enabled: true
    size: 100Gi
    mountPath: /data
    # storageClass: ""
    # existingClaim: downloads
```

### Using Existing Claims

To use pre-existing PVCs (useful for shared download directories):

```yaml
persistence:
  config:
    enabled: true
    existingClaim: nzbget-config
  data:
    enabled: true
    existingClaim: shared-downloads
```

### Additional Volumes

For more complex storage setups, use `volumes` and `volumeMounts`:

```yaml
volumes:
  - name: completed
    nfs:
      server: nas.local
      path: /volume1/downloads/completed
  - name: intermediate
    persistentVolumeClaim:
      claimName: intermediate-pvc

volumeMounts:
  - name: completed
    mountPath: /completed
  - name: intermediate
    mountPath: /intermediate
```

## Config Bootstrapping

The chart can seed NZBGet's `nzbget.conf` on first run when `bootstrap.enabled` is true.
This is useful for pre-configuring settings before NZBGet starts. By default, the config
file is only created if it doesn't already exist, preserving existing configurations.

> [!NOTE]
> Bootstrap requires `persistence.config.enabled` to be true.

> [!TIP]
> If `bootstrap.config` is empty (the default), NZBGet will create its own default
> configuration on first startup. This is typically sufficient for most deployments.

Set `bootstrap.overwrite: true` to enforce the config on every startup. This is useful
for GitOps workflows where the config is managed externally:

```yaml
bootstrap:
  enabled: true
  overwrite: true  # Always apply config, even if file exists
  existingConfig:
    type: configMap
    name: nzbget-managed-config
    key: nzbget.conf
```

Inline config creates a ConfigMap automatically:

```yaml
bootstrap:
  enabled: true
  config: |
    MainDir=/data
    DestDir=${MainDir}/completed
    InterDir=${MainDir}/intermediate
    NzbDir=${MainDir}/nzb
    QueueDir=${MainDir}/queue
    TempDir=${MainDir}/tmp
    WebDir=${AppDir}/webui
    ConfigTemplate=${AppDir}/webui/nzbget.conf.template
    ControlIP=0.0.0.0
    ControlPort=6789
    ControlUsername=nzbget
    ControlPassword=tegbzn6789
```

To use an existing ConfigMap or Secret:

```yaml
bootstrap:
  enabled: true
  existingConfig:
    type: secret  # or "configMap"
    name: nzbget-config
    key: nzbget.conf
```

## Ingress

Enable ingress to expose NZBGet externally:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: nzbget.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: nzbget-tls
      hosts:
        - nzbget.example.com
```

## Default Credentials

The default NZBGet credentials are:
- **Username:** `nzbget`
- **Password:** `tegbzn6789`

> [!WARNING]
> Change the default credentials immediately after installation, especially if exposing
> NZBGet via ingress.

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
| image.repository | string | `"linuxserver/nzbget"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| securityContext | object | `{}` | Container security context. |
| resources | object | `{}` | Resource requests and limits. |
| ports | list | `[{"containerPort":6789,"name":"http","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| bootstrap.enabled | bool | `false` | Create a nzbget.conf file if missing. Requires persistence.config.enabled=true. |
| bootstrap.overwrite | bool | `false` | Overwrite config on every startup (useful for GitOps-managed configs). |
| bootstrap.mountPath | string | `"/config"` | Directory containing the configuration file. |
| bootstrap.config | string | Empty (nzbget creates default config on first run). | Initial configuration content (used when existingConfig.type is empty). |
| bootstrap.existingConfig.type | string | `""` | Source type for existing config: "configMap", "secret", or "" (use bootstrap.config). |
| bootstrap.existingConfig.name | string | `""` | Name of the ConfigMap or Secret. |
| bootstrap.existingConfig.key | string | `"nzbget.conf"` | Key containing the configuration data. |
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
| service.port | int | `6789` | Service port. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"nzbget.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| initContainers | list | `[]` | Additional init containers. |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
