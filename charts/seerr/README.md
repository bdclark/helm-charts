# Seerr Helm Chart

[![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 3.1.0](https://img.shields.io/badge/AppVersion-3.1.0-informational?style=flat-square)](Chart.yaml)

Request management for media libraries

> [!NOTE]
> This chart is under active development. Breaking changes may occur between minor versions.

## Installing

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install seerr bdclark/seerr -f values.yaml
```

## Environment Variables

Environment variables can be set via `env` (inline values or refs) and `envFrom` (bulk refs).

```yaml
env:
  TZ: America/New_York
  LOG_LEVEL: info

envFrom:
  - secretRef:
      name: seerr-secrets
```

## Persistence

Persistence is enabled by default and mounted at `/app/config`.

```yaml
persistence:
  enabled: true
  size: 1Gi
  # storageClass: ""
  # existingClaim: seerr-config
```

### Additional Volumes

```yaml
volumes:
  - name: media
    persistentVolumeClaim:
      claimName: media-pvc

volumeMounts:
  - name: media
    mountPath: /media
```

## Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: seerr.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: seerr-tls
      hosts:
        - seerr.example.com
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
| image.repository | string | `"ghcr.io/seerr-team/seerr"` | Image repository. |
| image.tag | string | `""` | Image tag (defaults to chart appVersion). |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| securityContext | object | `{}` | Container security context. |
| resources | object | `{}` | Resource requests and limits. |
| ports | list | `[{"containerPort":5055,"name":"http","protocol":"TCP"}]` | Container ports. |
| startupProbe | object | `{}` | Startup probe configuration. |
| livenessProbe | object | `{}` | Liveness probe configuration. |
| readinessProbe | object | `{}` | Readiness probe configuration. |
| env | object | `{}` (see values.yaml comments for examples) | Environment variables. |
| envFrom | list | `[]` | Environment variables from ConfigMaps or Secrets. |
| persistence.enabled | bool | `true` | Enable persistence for config. |
| persistence.mountPath | string | `"/app/config"` | Mount path. |
| persistence.storageClass | string | `""` | Storage class ("-" for default, "" for cluster default). |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes. |
| persistence.size | string | `"1Gi"` | Volume size. |
| persistence.existingClaim | string | `""` | Use existing PVC (disables provisioning). |
| persistence.annotations | object | `{}` | PVC annotations. |
| volumeMounts | list | `[]` | Additional volume mounts. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.port | int | `5055` | Service port. |
| ingress.enabled | bool | `false` | Enable Ingress. |
| ingress.className | string | `""` | Ingress class name. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.hosts | list | `[{"host":"seerr.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress hosts. |
| ingress.tls | list | `[]` | Ingress TLS configuration. |
| initContainers | list | `[]` | Additional init containers. |
| extraContainers | list | `[]` | Additional containers. |
| volumes | list | `[]` | Additional volumes. |
| nodeSelector | object | `{}` | Node selector. |
| tolerations | list | `[]` | Tolerations. |
| affinity | object | `{}` | Affinity rules. |

## License

MIT - see [LICENSE](../../LICENSE).
