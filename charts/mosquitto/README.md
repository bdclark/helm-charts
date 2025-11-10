# Mosquitto Helm Chart

[![Version: 0.5.2](https://img.shields.io/badge/Version-0.5.2-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 2.0.22](https://img.shields.io/badge/AppVersion-2.0.22-informational?style=flat-square)](Chart.yaml)

Eclipse Mosquitto MQTT broker with authentication and persistence support

## Installing

### From repo

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install mosquitto bdclark/mosquitto
```

### From source

```bash
helm install mosquitto ./charts/mosquitto
```

### Uninstall

```bash
helm uninstall mosquitto
```

## Features

- Plain MQTT, TLS MQTT, and WebSocket MQTT endpoints
- Optional host networking or host ports for bare-metal clusters
- Configurable authentication (inline users or secrets) and ACLs (see [AUTH.md](AUTH.md))
- Optional persistence for DB and offline messages
- Helm tests + unit tests (helm-unittest) for confidence

## Common overrides

### Enable persistence + TLS port

```yaml
persistence:
  enabled: true
  size: 5Gi

service:
  type: LoadBalancer
  ports:
    mqttTls:
      enabled: true
      tls:
        secretName: mosquitto-tls
```

### External secret for users

```yaml
auth:
  secretRef:
    name: mosquitto-auth
    key: passwd
config:
  allowAnonymous: false
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| image.repository | string | `"eclipse-mosquitto"` | Image repository |
| image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| nameOverride | string | `""` | Override the chart name |
| fullnameOverride | string | `""` | Override the full release name |
| podAnnotations | object | `{}` | Pod annotations applied to the broker pod |
| podLabels | object | `{}` | Extra labels applied to the broker pod |
| podSecurityContext | object | `{}` | Pod-level security context |
| securityContext | object | `{}` | Container-level security context |
| resources | object | `{}` | Resource requests and limits |
| service.type | string | `"ClusterIP"` | Service type (ClusterIP/LoadBalancer/NodePort) |
| service.annotations | object | `{}` | Service annotations for load balancer configuration |
| service.loadBalancerIP | string | `""` | Static IP for LoadBalancer services |
| service.loadBalancerSourceRanges | list | `[]` | Allowed source ranges for LoadBalancer |
| service.externalTrafficPolicy | string | `"Cluster"` | Preserve client IP for LoadBalancer/NodePort |
| service.sessionAffinity | string | `"None"` | Session affinity mode |
| service.ports.mqtt.enabled | bool | `true` | Enable plain MQTT port |
| service.ports.mqtt.port | int | `1883` | MQTT port number |
| service.ports.mqtt.targetPort | int | `1883` | Target port in the pod |
| service.ports.mqtt.protocol | string | `"TCP"` | Protocol used by the service |
| service.ports.mqtt.nodePort | string | `""` | NodePort for NodePort service type (leave empty for auto-assignment) |
| service.ports.mqttTls.enabled | bool | `false` | Enable MQTT over TLS port |
| service.ports.mqttTls.port | int | `8883` | MQTT over TLS port number |
| service.ports.mqttTls.targetPort | int | `8883` | Target port in the pod |
| service.ports.mqttTls.protocol | string | `"TCP"` | Protocol used by the service |
| service.ports.mqttTls.nodePort | string | `""` | NodePort for NodePort service type (leave empty for auto-assignment) |
| service.ports.mqttTls.tls.secretName | string | `""` | Secret containing TLS certificates |
| service.ports.mqttTls.tls.caFile | string | `"ca.crt"` | CA certificate key in the secret |
| service.ports.mqttTls.tls.certFile | string | `"tls.crt"` | Server certificate key in the secret |
| service.ports.mqttTls.tls.keyFile | string | `"tls.key"` | Server private key key in the secret |
| service.ports.websocket.enabled | bool | `false` | Enable MQTT over WebSocket port |
| service.ports.websocket.port | int | `9001` | MQTT over WebSocket port number |
| service.ports.websocket.targetPort | int | `9001` | Target port in the pod |
| service.ports.websocket.protocol | string | `"TCP"` | Protocol used by the service |
| service.ports.websocket.nodePort | string | `""` | NodePort for NodePort service type (leave empty for auto-assignment) |
| hostNetwork.enabled | bool | `false` | Enable host networking (pod uses node network namespace) |
| hostNetwork.dnsPolicy | string | `"ClusterFirstWithHostNet"` | DNS policy when using host networking |
| hostPorts.enabled | bool | `false` | Enable hostPort configuration |
| hostPorts.mqtt.port | string | `""` | Host port for plain MQTT (leave empty to disable) |
| hostPorts.mqtt.hostIP | string | `""` | Specific host IP to bind (empty = all interfaces) |
| hostPorts.mqttTls.port | string | `""` | Host port for TLS MQTT |
| hostPorts.mqttTls.hostIP | string | `""` | Specific host IP to bind (empty = all interfaces) |
| hostPorts.websocket.port | string | `""` | Host port for WebSocket MQTT |
| hostPorts.websocket.hostIP | string | `""` | Specific host IP to bind (empty = all interfaces) |
| ingress.enabled | bool | `false` | Enable ingress for WebSocket port |
| ingress.className | string | `""` | Ingress class name |
| ingress.annotations | object | `{}` | Additional ingress annotations |
| ingress.hosts | list | `[{"host":"mosquitto.local","paths":[{"path":"/mqtt","pathType":"Prefix","service":{"name":"websocket"}}]}]` | Ingress rules configuration |
| ingress.tls | list | `[]` | TLS configuration for ingress |
| livenessProbe | object | `{"initialDelaySeconds":30,"periodSeconds":10,"tcpSocket":{"port":"mqtt"}}` | Liveness probe |
| readinessProbe | object | `{"initialDelaySeconds":5,"periodSeconds":5,"tcpSocket":{"port":"mqtt"}}` | Readiness probe |
| config.allowAnonymous | bool | `true` | Allow anonymous connections (auto-disabled when users are defined) |
| config.logLevel | string | `"information"` | Broker log level |
| config.maxConnections | int | `0` | Max concurrent client connections (0 = unlimited) |
| config.extraConfig | string | `""` | Additional configuration appended verbatim |
| auth.users | list | `[]` | Inline users/passwords stored in ConfigMap (development/testing) |
| auth.secretRef.name | string | `""` | Name of secret containing passwd file (takes precedence over users) |
| auth.secretRef.key | string | `"passwd"` | Key in the secret containing passwd file content |
| auth.acls | string | `""` | ACL entries in Mosquitto ACL file format |
| persistence.enabled | bool | `false` | Enable persistent volume for Mosquitto data |
| persistence.storageClass | string | `""` | Storage class for PVC (set to "-" to disable dynamic provisioning) |
| persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes for the PVC |
| persistence.size | string | `"1Gi"` | Requested PVC size |
| persistence.existingClaim | string | `""` | Use an existing PVC instead of creating a new one |
| persistence.annotations | object | `{}` | Annotations for PVC |
| nodeSelector | object | `{}` | Node selector for scheduling |
| tolerations | list | `[]` | Pod tolerations |
| affinity | object | `{}` | Pod affinity / anti-affinity rules |

## Contributing

- Bump `version`/`appVersion` in `Chart.yaml` for any change.
- Keep helm-unittest specs (`charts/mosquitto/tests/`) and integration tests (`tests/integration/pytest_suite/charts/test_mosquitto.py`) up to date.
- Run `task verify-chart CHART=mosquitto` + targeted `task pytest` before opening a PR.

## License

MIT — see [LICENSE](../../LICENSE).
