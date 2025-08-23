# Music Assistant Helm Chart

Music Assistant is a free, open-source media library manager that connects streaming services with various connected speakers and players on your network.

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)
![AppVersion: 2.5.8](https://img.shields.io/badge/AppVersion-2.5.8-informational?style=flat-square)

## TL;DR

```bash
# Basic installation with host networking (recommended)
helm install music-assistant ./music-assistant

# Standard Kubernetes networking
helm install music-assistant ./music-assistant \
  --set hostNetwork=false

# With persistence and ingress
helm install music-assistant ./music-assistant \
  --set hostNetwork=false \
  --set persistence.enabled=true \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=music-assistant.local
```

## Introduction

This chart deploys Music Assistant on Kubernetes with support for:

- **Flexible Networking** - Host networking (default) or standard Kubernetes networking
- **Device Discovery** - UPnP/D-LNA, Chrome-cast, AirPlay device discovery
- **Data Persistence** - Optional persistent storage for configuration and database
- **Multi-CNI Support** - Works with Multi-CNI for VLAN access
- **Web Interface** - HTTP access via service or ingress

## Prerequisites

- Kubernetes 1.21+
- Helm 3.8+
- PV provisioner support (for persistence)

## Installing the Chart

```bash
# Install with release name "music-assistant"
helm install music-assistant ./music-assistant

# Install in a specific namespace
helm install music-assistant ./music-assistant --namespace media --create-namespace

# Install with custom values
helm install music-assistant ./music-assistant -f my-values.yaml
```

## Uninstalling the Chart

```bash
helm uninstall music-assistant
```

## Configuration

### Basic Configuration

| Parameter             | Description                         | Default                              |
|-----------------------|-------------------------------------|--------------------------------------|
| `image.repository`    | Container image repository          | `ghcr.io/music-assistant/server`     |
| `image.tag`           | Container image tag                 | `""` (uses appVersion)               |
| `image.pullPolicy`    | Image pull policy                   | `IfNotPresent`                       |

### Networking Configuration

| Parameter              | Description                                    | Default        |
|------------------------|------------------------------------------------|----------------|
| `hostNetwork`          | Enable host networking mode                    | `true`         |
| `dnsPolicy`            | DNS policy when using host networking          | `ClusterFirst` |
| `service.enabled`      | Create service                                 | `false`        |
| `service.type`         | Service type                                   | `ClusterIP`    |
| `service.webPort`      | Web interface port                             | `8095`         |
| `service.streamPort`   | Audio streaming port                           | `8097`         |

### Ingress Configuration

| Parameter           | Description               | Default |
|---------------------|---------------------------|---------|
| `ingress.enabled`   | Enable ingress            | `false` |
| `ingress.className` | Ingress class name        | `""`    |
| `ingress.hosts`     | Ingress hostnames         | `[]`    |
| `ingress.tls`       | Ingress TLS configuration | `[]`    |

### Persistence Configuration

| Parameter                   | Description       | Default |
|-----------------------------|-------------------|---------|
| `persistence.enabled`       | Enable persistence| `true`  |
| `persistence.size`          | PVC size          | `2Gi`   |
| `persistence.storageClass`  | Storage class     | `""`    |
| `persistence.existingClaim` | Use existing PVC  | `""`    |

### Security Configuration

| Parameter                              | Description                     | Default |
|----------------------------------------|---------------------------------|---------|
| `securityContext.runAsNonRoot`         | Run as non-root user            | `false` |
| `securityContext.runAsUser`            | User ID to run container as     | `0`     |
| `securityContext.capabilities.enabled` | Enable additional capabilities  | `false` |

## Examples

### Basic Installation with Host Networking

```yaml
# values.yaml
hostNetwork: true
persistence:
  enabled: true
  size: 5Gi
```

This is the recommended configuration for maximum device discovery compatibility.

### Standard Kubernetes Networking with Ingress

```yaml
# values.yaml
hostNetwork: false
service:
  type: ClusterIP
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: music-assistant.local
      paths:
        - path: /
          pathType: Prefix
persistence:
  enabled: true
  size: 5Gi
```

### Advanced Networking with Multi-CNI

```yaml
# values.yaml
hostNetwork: true
service:
  enabled: false  # Disable service when using direct network access
podAnnotations:
  k8s.v1.cni.cncf.io/networks: "mac-vlan-vlan100"
persistence:
  enabled: true
  size: 10Gi
```

### Media Storage Configuration

```yaml
# values.yaml
additionalVolumes:
  - name: media-nfs
    nfs:
      server: nas.example.com
      path: /volume1/media
  - name: media-local
    hostPath:
      path: /mnt/media
      type: Directory

additionalMounts:
  - name: media-nfs
    mountPath: /media/nfs
    readOnly: true
  - name: media-local
    mountPath: /media/local
    readOnly: true
```

### Production Configuration

```yaml
# values.yaml
hostNetwork: true
persistence:
  enabled: true
  size: 20Gi
  storageClass: "fast-ssd"
  annotations:
    backup.volume.io/backup-volumes: data

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 256Mi

nodeSelector:
  kubernetes.io/arch: amd64

env:
  - name: TZ
    value: "America/New_York"
```

## Networking Modes

### Host Networking (Default)

Host networking provides the best device discovery experience:

```yaml
hostNetwork: true  # Default
service:
  enabled: false   # Default: disabled for host networking
```

**Pros:**

- Maximum device discovery compatibility
- Direct access to network interfaces
- Works with UPnP/D-LNA, Chrome-cast, AirPlay

**Cons:**

- Pod uses host's network namespace
- Port conflicts possible with other host services

### Standard Kubernetes Networking

Standard networking with service exposure:

```yaml
hostNetwork: false
service:
  enabled: true    # Set to true for standard networking
  type: ClusterIP  # or NodePort/LoadBalancer
```

**Pros:**

- Proper Kubernetes networking isolation
- Service discovery and load balancing
- Network policies support

**Cons:**

- May limit device discovery capabilities
- Requires proper service configuration

### Multi-CNI Support

For advanced networking with VLAN access:

```yaml
hostNetwork: true
service:
  enabled: false   # Disable when using direct network access
podAnnotations:
  k8s.v1.cni.cncf.io/networks: "vlan-config"
```

## Storage

### Data Persistence

Music Assistant requires persistent storage for:

- Configuration files
- Database (SQLite)
- Cache and temporary files

```yaml
persistence:
  enabled: true
  size: 2Gi          # Minimum recommended
  storageClass: ""   # Use default storage class
```

### Media Access

For local media files, use additional volumes:

```yaml
additionalVolumes:
  - name: music
    hostPath:
      path: /mnt/music
      type: Directory

additionalMounts:
  - name: music
    mountPath: /media/music
    readOnly: true
```

## Health Checks

The chart includes health checks on the web interface:

- **Liveness Probe**: Checks if Music Assistant is running
- **Readiness Probe**: Checks if the service is ready for connections
- **Startup Probe**: Allows time for initial startup

## Security

### Capabilities

For advanced features like SMB/network shares:

```yaml
securityContext:
  capabilities:
    enabled: true
    add:
      - DAC_READ_SEARCH  # For SMB/network share access
      - SYS_ADMIN        # For mounting network shares
```

**Note**: Additional capabilities are disabled by default for better security.

### Non-root Support

When using custom images that support non-root:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 568
  runAsGroup: 568
```

## Troubleshooting

### Device Discovery Issues

1. **Check networking mode**:

   ```bash
   # Verify host networking is enabled
   kubectl get pods -o wide
   ```

2. **Network policies**: Ensure no network policies block device discovery

3. **Firewall rules**: Check cluster/node firewall rules for UPnP/mDNS

### Connection Issues

1. **Service configuration**:

   ```bash
   # Check service status
   kubectl get svc music-assistant

   # Port forward for testing
   kubectl port-forward svc/music-assistant 8095:8095
   ```

2. **Pod logs**:

   ```bash
   kubectl logs -l app.kubernetes.io/name=music-assistant
   ```

### Storage Issues

1. **PVC status**:

   ```bash
   # Check PVC binding
   kubectl get pvc music-assistant-data
   ```

2. **Permissions**: Verify storage permissions if using hostPath or NFS

## Home Assistant Integration

Music Assistant integrates seamlessly with Home Assistant:

1. **Automatic Discovery**: With host networking, Music Assistant should be automatically discovered
2. **Manual Configuration**: For standard networking, configure Home Assistant to connect to your service endpoint
3. **Network Access**: Ensure Home Assistant can reach Music Assistant's network segment

## Values Reference

For complete values documentation, see the inline comments in [values.yaml](./values.yaml).

## Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Run the test suite: `helm unittest charts/music-assistant/`
5. Submit a pull request

## License

This chart is licensed under the MIT License.

## Links

- **Music Assistant**: <https://music-assistant.io/>
- **Docker Hub**: <https://github.com/music-assistant/server/pkgs/container/server>
- **GitHub**: <https://github.com/music-assistant/server>
- **Documentation**: <https://music-assistant.io/documentation/>
