# Authentication Guide

Quick reference for configuring authentication and authorization in the Mosquitto Helm chart.

## Quick Setup

### 1. Generate Password Hash

```bash
# Using the helper script
./scripts/generate-password.sh admin mypassword123

# Manual with Docker
docker run --rm -it eclipse-mosquitto:latest mosquitto_passwd -c /dev/stdout admin
```

### 2. Configure Users

```yaml
# values.yaml
config:
  allowAnonymous: false

auth:
  users:
    - username: admin
      passwordHash: "$6$salt$hash..."
    - username: sensor1
      password: sensor123  # Only for development
```

### 3. Configure Access Control

```yaml
# values.yaml
auth:
  acls:
    # Admin full access
    - user: admin
      topic: "#"
      access: readwrite

    # Device-specific access
    - user: sensor1
      topic: "sensors/sensor1/#"
      access: write

    # Pattern-based access
    - pattern: "read devices/%u/status"  # %u = username
```

## Access Control Reference

### Access Types

- `read` - Subscribe only
- `write` - Publish only
- `readwrite` - Both publish and subscribe

### Topic Patterns

- `+` - Single level wildcard (`sensors/+/temp`)
- `#` - Multi-level wildcard (`sensors/#`)
- `%u` - Username substitution
- `%c` - Client ID substitution

## Testing Authentication

```bash
# Test with authentication
mosquitto_pub -h <host> -u admin -P password -t "test" -m "hello"

# Test ACL permissions
mosquitto_sub -h <host> -u sensor1 -P password -t "sensors/sensor1/#"
```

## Troubleshooting

```bash
# Check generated config
kubectl get configmap mosquitto-config -o jsonpath='{.data.mosquitto\.conf}'

# View password file
kubectl get configmap mosquitto-config -o jsonpath='{.data.passwd}'

# Check logs
kubectl logs -f deployment/mosquitto
```

## Security Best Practices

1. **Use password hashes in production** (not plaintext)
2. **Follow principle of least privilege** for ACLs
3. **Use topic namespaces** (e.g., `devices/<device-id>/`)
4. **Disable anonymous access** in production
5. **Consider TLS for sensitive data**

For complete configuration examples, see the main [README.md](./README.md).
