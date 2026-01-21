# Mealie Helm Chart

[![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 3.9.2](https://img.shields.io/badge/AppVersion-3.9.2-informational?style=flat-square)](Chart.yaml)

Mealie recipe manager and meal planner

## Installing

### From repo

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install mealie bdclark/mealie
```

### From source

```bash
helm install mealie ./charts/mealie
```

### Uninstall

```bash
helm uninstall mealie
```

## Database Configuration

Mealie supports two database engine: SQLite (default) and PostgreSQL.

### SQLite (default)

**Requirements:**

- `database.engine: sqlite`
- `persistence.enabled: true` (SQLite needs persistent storage)
- `replicaCount: 1` (SQLite does not support multiple replicas)

This is the default configuration. No additional setup is required.

### PostgreSQL

**Requirements:**

- A running PostgreSQL instance
- `database.engine: postgres`
- Configure database connection settings under `database.postgres`

#### Option 1: Full connection URL

Using a complete PostgreSQL connection string:

```yaml
database:
  engine: postgres
  postgres:
    urlOverride:
      value: "postgresql://mealie:password@postgres.example.com:5432/mealie"
```

Using a secret reference for the connection string:

```yaml
database:
  engine: postgres
  postgres:
    urlOverride:
      existingSecret:
        name: "mealie-db-secret"
        key: "connection-url"
```

#### Option 2: Individual connection parameters

Specify each connection parameter separately (any combination of `value` and
`existingSecret` can be used):

```yaml
database:
  engine: postgres
  postgres:
    server:
      value: "postgres.example.com"
    port:
      value: 5432
    db:
      value: "mealie"
    user:
      existingSecret:
        name: "mealie-db-secret"
        key: "username"
    password:
      existingSecret:
        name: "mealie-db-secret"
        key: "password"
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of replicas for the mealie deployment SQLite requires a single instance |
| image.repository | string | `"ghcr.io/mealie-recipes/mealie"` | Image repository |
| image.tag | string | `"v3.9.2"` | Image tag |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| nameOverride | string | `""` | Override the chart name |
| fullnameOverride | string | `""` | Override the full release name |
| podAnnotations | object | `{}` | Pod annotations applied to the mealie pod |
| podLabels | object | `{}` | Pod labels applied to the mealie pod |
| podSecurityContext | object | `{}` | Pod-level security context |
| securityContext | object | `{}` | Container-level security context |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP/LoadBalancer/NodePort) |
| service.port | int | `9000` | Service port |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.className | string | `""` | Ingress class name |
| ingress.annotations | object | `{}` | Additional ingress annotations |
| ingress.hosts | list | `[{"host":"mealie.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Ingress rules configuration |
| ingress.tls | list | `[]` | TLS configuration for ingress |
| resources | object | `{}` | Resource requests and limits |
| persistence.enabled | bool | `true` | Enable persistence |
| persistence.storageClass | string | `""` | Storage class for PVC Set to "-" to disable dynamic provisioning and use default storage class Set to "" to use cluster default storage class |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes for the PVC |
| persistence.size | string | `"1Gi"` | Requested PVC size |
| persistence.existingClaim | string | `""` | Use an existing PVC instead of creating a new one If defined, PVC must be created manually before volume will be bound |
| persistence.annotations | object | `{}` | Annotations for PVC |
| database.engine | string | `"sqlite"` | Database engine to use (sqlite/postgres) |
| database.postgres.urlOverride.value | string | `""` | PostgreSQL connection URL |
| database.postgres.urlOverride.existingSecret.name | string | `""` | Secret reference for connection URL |
| database.postgres.urlOverride.existingSecret.key | string | `""` | Key in the secret for connection URL |
| database.postgres.server.value | string | `""` | PostgreSQL server/host address |
| database.postgres.server.existingSecret.name | string | `""` | Secret reference for server/host |
| database.postgres.server.existingSecret.key | string | `""` | Key in the secret for server/host |
| database.postgres.port.value | int | `5432` | PostgreSQL server/host port |
| database.postgres.port.existingSecret.name | string | `""` | Secret reference for port |
| database.postgres.port.existingSecret.key | string | `""` | Key in the secret for port |
| database.postgres.db.value | string | `"mealie"` | PostgreSQL database name |
| database.postgres.db.existingSecret.name | string | `""` | Secret reference for database name |
| database.postgres.db.existingSecret.key | string | `""` | Key in the secret for database name |
| database.postgres.user.value | string | `""` | PostgreSQL username |
| database.postgres.user.existingSecret.name | string | `""` | Secret reference for username |
| database.postgres.user.existingSecret.key | string | `""` | Key in the secret for username |
| database.postgres.password.value | string | `""` | PostgreSQL password |
| database.postgres.password.existingSecret.name | string | `""` | Secret reference for password |
| database.postgres.password.existingSecret.key | string | `""` | Key in the secret for password |
| extraEnv | list | `[]` | Extra environment variables for the container |
| extraEnvFrom | list | `[]` | Extra environment variable sources (ConfigMap/Secret refs) |
| livenessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Liveness probe configuration |
| readinessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Readiness probe configuration |
| startupProbe | object | `{}` | Startup probe configuration |
| volumeMounts | list | `[]` | Extra volume mounts for the container |
| nodeSelector | object | `{}` | Node selector for scheduling |
| tolerations | list | `[]` | Pod tolerations |
| affinity | object | `{}` | Pod affinity/anti-affinity |

## Contributing

- Bump `version`/`appVersion` in `Chart.yaml` for any change.
- Keep unit tests (`charts/mealie/tests/`) up to date.
- Run `task verify-chart CHART=mealie` before opening a PR.

## License

MIT — see [LICENSE](../../LICENSE).
