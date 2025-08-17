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

- **Authentication & Authorization** - User management with ACLs
- **TLS Support** - Secure MQTT connections
- **Persistence** - Optional message and data persistence
- **WebSocket Support** - MQTT over WebSockets for web clients
- **Monitoring Ready** - Prometheus metrics (coming soon)

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

| Parameter             | Description                               | Default                |
|-----------------------|-------------------------------------------|------------------------|
| `workload.type`       | Workload type (Deployment or StatefulSet) | `Deployment`           |
| `image.repository`    | Container image repository                | `eclipse-mosquitto`    |
| `image.tag`           | Container image tag                       | `""` (uses appVersion) |
| `image.pullPolicy`    | Image pull policy                         | `IfNotPresent`         |

### Service Configuration

| Parameter                         | Description                  | Default     |
|-----------------------------------|------------------------------|-------------|
| `service.type`                    | Service type                 | `ClusterIP` |
| `service.annotations`             | Service annotations          | `{}`        |
| `service.loadBalancerIP`          | LoadBalancer IP address      | `""`        |
| `service.loadBalancerSourceRanges`| LoadBalancer source ranges   | `[]`        |
| `service.externalTrafficPolicy`   | External traffic policy      | `Cluster`   |
| `service.sessionAffinity`         | Session affinity             | `None`      |
| `service.ports.mqtt.enabled`      | Enable MQTT port (1883)      | `true`      |
| `service.ports.mqtt.nodePort`     | NodePort for MQTT            | `""`        |
| `service.ports.mqttTls.enabled`   | Enable MQTT TLS port (8883)  | `false`     |
| `service.ports.mqttTls.nodePort`  | NodePort for MQTT TLS        | `""`        |
| `service.ports.websocket.enabled` | Enable WebSocket port (9001) | `false`     |
| `service.ports.websocket.nodePort`| NodePort for WebSocket       | `""`        |

### External Exposure Configuration

| Parameter                         | Description                  | Default     |
|-----------------------------------|------------------------------|-------------|
| `hostNetwork.enabled`             | Use host networking          | `false`     |
| `hostNetwork.dnsPolicy`           | DNS policy for host network  | `ClusterFirstWithHostNet` |
| `hostPorts.enabled`               | Enable host port binding     | `false`     |
| `hostPorts.mqtt.port`             | Host port for MQTT           | `""`        |
| `hostPorts.mqtt.hostIP`           | Host IP for MQTT             | `""`        |
| `hostPorts.mqttTls.port`          | Host port for MQTT TLS       | `""`        |
| `hostPorts.mqttTls.hostIP`        | Host IP for MQTT TLS         | `""`        |
| `hostPorts.websocket.port`        | Host port for WebSocket      | `""`        |
| `hostPorts.websocket.hostIP`      | Host IP for WebSocket        | `""`        |

### Authentication Configuration

| Parameter              | Description                    | Default |
|------------------------|--------------------------------|---------|
| `config.allowAnonymous`| Allow anonymous connections   | `true`   |
| `auth.users`           | List of users with passwords  | `[]`     |
| `auth.acls`            | Access control lists          | `[]`     |

### Persistence Configuration

| Parameter                    | Description              | Default |
|------------------------------|--------------------------|---------|
| `persistence.enabled`        | Enable persistence       | `false` |
| `persistence.size`           | PVC size                 | `1Gi`   |
| `persistence.storageClass`   | Storage class            | `""`    |
| `persistence.existingClaim`  | Use existing PVC         | `""`    |

## Examples

### 1. Basic MQTT Broker

```yaml
# values.yaml
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

### 3. Production Setup with TLS and StatefulSet

```yaml
# values.yaml
workload:
  type: statefulset  # Use StatefulSet for stable network identity

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

### 5. External Exposure with LoadBalancer (MetalLB)

```yaml
# values.yaml
service:
  type: LoadBalancer
  annotations:
    metallb.universe.tf/address-pool: "production-public-ips"
    metallb.universe.tf/loadBalancerIPs: "192.168.1.100"
  loadBalancerSourceRanges:
    - "10.0.0.0/8"
    - "192.168.0.0/16"
  externalTrafficPolicy: Local
```

### 6. External Exposure with NodePort

```yaml
# values.yaml
service:
  type: NodePort
  ports:
    mqtt:
      nodePort: 31883
    mqttTls:
      enabled: true
      nodePort: 31884
  externalTrafficPolicy: Local
```

### 7. Host Network for Maximum Performance

```yaml
# values.yaml
hostNetwork:
  enabled: true
  dnsPolicy: ClusterFirstWithHostNet

# Ensure only one replica when using hostNetwork
workload:
  type: deployment

nodeSelector:
  kubernetes.io/hostname: worker-node-1
```

### 8. Host Ports for Selective Exposure

```yaml
# values.yaml
hostPorts:
  enabled: true
  mqtt:
    port: 1883
    hostIP: "192.168.1.10"  # Bind to specific interface
  mqttTls:
    port: 8883
    hostIP: "192.168.1.10"

# Pin to specific node
nodeSelector:
  kubernetes.io/hostname: worker-node-1
```

### 9. Cloud Provider LoadBalancer (AWS/GCP/Azure)

```yaml
# values.yaml - AWS Network Load Balancer
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
  externalTrafficPolicy: Local

---
# values.yaml - Azure LoadBalancer
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: "myResourceGroup"
  loadBalancerSourceRanges:
    - "0.0.0.0/0"

---
# values.yaml - GCP LoadBalancer
service:
  type: LoadBalancer
  annotations:
    cloud.google.com/load-balancer-type: "External"
```

## Authentication

For detailed authentication setup, see [AUTH.md](./AUTH.md).

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

```bash
# Test the installed chart
helm test mosquitto

# Run chart tests (development)
task test-unit
```

## Troubleshooting

```bash
# Check logs
kubectl logs -l app.kubernetes.io/name=mosquitto

# View generated config
kubectl get configmap mosquitto-config -o yaml

# Test connectivity
kubectl run mqtt-test --image=eclipse-mosquitto:latest --rm -it -- mosquitto_pub -h mosquitto -t test -m hello
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

- **Mosquitto Project**: <https://mosquitto.org/>
- **Docker Hub**: <https://hub.docker.com/_/eclipse-mosquitto>
- **GitHub**: <https://github.com/eclipse/mosquitto>
