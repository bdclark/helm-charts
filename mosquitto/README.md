# Mosquitto Helm Chart

Eclipse Mosquitto MQTT broker for Kubernetes with comprehensive authentication, TLS support, and persistence.

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![AppVersion: 2.0.18](https://img.shields.io/badge/AppVersion-2.0.18-informational?style=flat-square)

## TL;DR

```bash
# Basic installation
helm install mosquitto ./mosquitto

# With authentication
helm install mosquitto ./mosquitto \
  --set auth.users[0].username=admin \
  --set auth.users[0].password=secretpassword

# Production setup with persistence and TLS
helm install mosquitto ./mosquitto \
  --set persistence.enabled=true \
  --set service.ports.mqttTls.enabled=true \
  --set service.ports.mqttTls.tls.secretName=mosquitto-tls
```

## Introduction

This chart deploys Eclipse Mosquitto MQTT broker on Kubernetes with:

- 🔐 **Authentication & Authorization** - User management with ACLs
- 🔒 **TLS Support** - Secure MQTT connections
- 💾 **Persistence** - Optional message and data persistence
- 🌐 **WebSocket Support** - MQTT over WebSockets for web clients
- 📊 **Monitoring Ready** - Prometheus metrics (coming soon)
- 🧪 **Production Tested** - Comprehensive test suite

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support (for persistence)

## Installing the Chart

```bash
# Install with release name "mosquitto"
helm install mosquitto ./mosquitto

# Install in a specific namespace
helm install mosquitto ./mosquitto --namespace mqtt --create-namespace

# Install with custom values
helm install mosquitto ./mosquitto -f my-values.yaml
```

## Uninstalling the Chart

```bash
helm uninstall mosquitto
```

## Configuration

### Basic Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Container image repository | `eclipse-mosquitto` |
| `image.tag` | Container image tag | `""` (uses appVersion) |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.ports.mqtt.enabled` | Enable MQTT port (1883) | `true` |
| `service.ports.mqttTls.enabled` | Enable MQTT TLS port (8883) | `false` |
| `service.ports.websocket.enabled` | Enable WebSocket port (9001) | `false` |

### Authentication

| Parameter | Description | Default |
|-----------|-------------|---------|
| `config.allowAnonymous` | Allow anonymous connections | `true` |
| `auth.users` | List of users with passwords | `[]` |
| `auth.acls` | Access control lists | `[]` |

### Persistence

| Parameter | Description | Default |
|-----------|-------------|---------|
| `persistence.enabled` | Enable persistence | `false` |
| `persistence.size` | PVC size | `1Gi` |
| `persistence.storageClass` | Storage class | `""` |
| `persistence.existingClaim` | Use existing PVC | `""` |

## Examples

### 1. Basic MQTT Broker
```yaml
# values.yaml
replicaCount: 1
service:
  type: LoadBalancer
```

### 2. Authenticated Broker
```yaml
# values.yaml
config:
  allowAnonymous: false

auth:
  users:
    - username: admin
      password: admin123
    - username: sensor1
      passwordHash: "$6$salt$hash..."
  
  acls:
    - user: admin
      topic: "#"
      access: readwrite
    - user: sensor1
      topic: "sensors/sensor1/#"
      access: write
```

### 3. Production Setup with TLS
```yaml
# values.yaml
service:
  type: LoadBalancer
  ports:
    mqtt:
      enabled: true
    mqttTls:
      enabled: true
      tls:
        secretName: mosquitto-tls-secret

persistence:
  enabled: true
  size: 10Gi
  storageClass: fast-ssd

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### 4. WebSocket for Web Clients
```yaml
# values.yaml
service:
  ports:
    websocket:
      enabled: true

ingress:
  enabled: true
  hosts:
    - host: mqtt.example.com
      paths:
        - path: /mqtt
          pathType: Prefix
          service:
            name: websocket
```

## Authentication Guide

See [AUTH.md](./AUTH.md) for comprehensive authentication and authorization setup.

### Quick Authentication Setup

1. **Generate password hash**:
   ```bash
   ./scripts/generate-password.sh admin mypassword123
   ```

2. **Create values file**:
   ```yaml
   auth:
     users:
       - username: admin
         passwordHash: "$6$generated$hash..."
   ```

3. **Install with authentication**:
   ```bash
   helm install mosquitto ./mosquitto -f auth-values.yaml
   ```

## TLS Configuration

1. **Create TLS secret**:
   ```bash
   kubectl create secret generic mosquitto-tls \
     --from-file=ca.crt=ca.crt \
     --from-file=tls.crt=server.crt \
     --from-file=tls.key=server.key
   ```

2. **Enable TLS in values**:
   ```yaml
   service:
     ports:
       mqttTls:
         enabled: true
         tls:
           secretName: mosquitto-tls
   ```

## Testing

The chart includes comprehensive tests:

```bash
# Install testing tools
task install-tools

# Run unit tests
task test-unit

# Run integration tests (requires cluster)
task test-integration

# Test the installed chart
helm test mosquitto
```

## Monitoring

*Coming Soon*: Prometheus metrics and Grafana dashboards.

## Troubleshooting

### Common Issues

1. **Authentication failures**
   ```bash
   kubectl logs -l app.kubernetes.io/name=mosquitto
   ```

2. **TLS issues**
   ```bash
   kubectl describe secret mosquitto-tls
   ```

3. **Persistence issues**
   ```bash
   kubectl get pvc
   kubectl describe pvc mosquitto-data
   ```

### Debug Commands

```bash
# View generated config
kubectl get configmap mosquitto-config -o yaml

# Test connectivity
kubectl run mqtt-test --image=eclipse-mosquitto:latest --rm -it -- mosquitto_pub -h mosquitto -t test -m hello

# Port forward for local testing
kubectl port-forward svc/mosquitto 1883:1883
```

## Values Reference

For complete values documentation, see the inline comments in [values.yaml](./values.yaml).

## Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Run the test suite: `task test`
5. Submit a pull request

## License

This chart is licensed under the MIT License.

## Links

- **Mosquitto Project**: https://mosquitto.org/
- **Docker Hub**: https://hub.docker.com/_/eclipse-mosquitto
- **GitHub**: https://github.com/eclipse/mosquitto