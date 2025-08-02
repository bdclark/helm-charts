# Mosquitto Authentication Guide

This guide explains how to configure authentication and authorization for the Mosquitto MQTT broker using this Helm chart.

## Quick Start

### Basic Authentication (Development)

For development environments, you can use plaintext passwords:

```yaml
auth:
  users:
    - username: admin
      password: admin123
    - username: sensor1
      password: sensor123
```

### Secure Authentication (Production)

For production environments, use password hashes:

```yaml
auth:
  users:
    - username: admin
      passwordHash: "$6$salt$hash..."
    - username: sensor1
      passwordHash: "$6$salt$hash..."
```

## Generating Password Hashes

### Using the Helper Script

The chart includes a helper script to generate secure password hashes:

```bash
# Basic usage
./scripts/generate-password.sh admin mypassword123

# Output in values.yaml format
./scripts/generate-password.sh --format admin mypassword123

# Copy to clipboard (macOS/Linux)
./scripts/generate-password.sh --copy admin mypassword123
```

### Manual Generation

If you have `mosquitto_passwd` installed locally:

```bash
# Create password file
mosquitto_passwd -c passwd admin
# Enter password when prompted

# View the hash
cat passwd
# Output: admin:$6$salt$hash...
```

Using Docker:

```bash
# Generate hash using Docker
docker run --rm -it eclipse-mosquitto:latest mosquitto_passwd -c /dev/stdout admin
# Enter password when prompted
```

## Access Control Lists (ACLs)

Control what topics users can access:

### User-based ACLs

```yaml
auth:
  acls:
    - user: admin
      topic: "#"                    # All topics
      access: readwrite
    - user: sensor1
      topic: "sensors/sensor1/#"    # Only sensor1's topics
      access: write
    - user: monitor
      topic: "sensors/+/data"       # Read sensor data
      access: read
```

### Pattern-based ACLs

Use patterns for dynamic topic access:

```yaml
auth:
  acls:
    - pattern: "readwrite %u/#"     # Users can read/write to their own namespace
    - pattern: "read public/#"      # Everyone can read public topics
```

### Access Types

- `read` - Subscribe and receive messages
- `write` - Publish messages
- `readwrite` - Both read and write access

## Topic Patterns

### Wildcards
- `+` - Single level wildcard (`sensors/+/temp` matches `sensors/device1/temp`)
- `#` - Multi-level wildcard (`sensors/#` matches `sensors/device1/temp/current`)

### Variables
- `%u` - Replaced with username
- `%c` - Replaced with client ID

## Complete Example

```yaml
# values.yaml
config:
  allowAnonymous: false  # Disable anonymous access

auth:
  users:
    - username: admin
      passwordHash: "$6$salt$adminaccess..."
    - username: device1
      passwordHash: "$6$salt$device1pass..."
    - username: monitor
      passwordHash: "$6$salt$monitorpass..."

  acls:
    # Admin has full access
    - user: admin
      topic: "#"
      access: readwrite

    # Devices can only publish to their own topics
    - user: device1
      topic: "devices/device1/#"
      access: write

    # Monitor can read all device data
    - user: monitor
      topic: "devices/+/data"
      access: read

    # Pattern-based: users can read their own status
    - pattern: "read devices/%u/status"
```

## Security Best Practices

### Password Management
1. **Never use plaintext passwords in production**
2. **Use strong, unique passwords for each user**
3. **Rotate passwords regularly**
4. **Consider using certificate-based authentication for devices**

### ACL Design
1. **Follow principle of least privilege**
2. **Use specific topic patterns instead of wildcards when possible**
3. **Separate device and user namespaces**
4. **Monitor access patterns and adjust ACLs accordingly**

### Topic Naming Conventions

```text
devices/<device-id>/data          # Device telemetry
devices/<device-id>/config        # Device configuration
devices/<device-id>/status        # Device status
users/<username>/private          # User private topics
public/announcements              # Public broadcast topics
```

## Testing Authentication

### Using mosquitto_pub/sub

Test authentication with command line tools:

```bash
# Test successful authentication
mosquitto_pub -h <broker-host> -p 1883 -u admin -P admin123 -t "test/topic" -m "hello"

# Test ACL permissions
mosquitto_sub -h <broker-host> -p 1883 -u monitor -P monitor123 -t "devices/+/data"

# Test failed authentication (should fail)
mosquitto_pub -h <broker-host> -p 1883 -u admin -P wrongpass -t "test/topic" -m "hello"
```

### Using kubectl

Test from within the cluster:

```bash
# Port forward to broker
kubectl port-forward svc/mosquitto 1883:1883

# Test in another terminal
mosquitto_pub -h localhost -p 1883 -u admin -P admin123 -t "test/topic" -m "hello"
```

## Troubleshooting

### Common Issues

1. **Authentication failures**
   - Check username/password spelling
   - Verify password hash is correctly escaped in YAML
   - Check mosquitto logs: `kubectl logs deployment/mosquitto`

2. **ACL denials**
   - Verify topic patterns match your publish/subscribe topics
   - Check access type (read/write/readwrite)
   - Remember wildcards in ACLs don't match topics starting with `$`

3. **Configuration not applied**
   - Restart the deployment: `kubectl rollout restart deployment/mosquitto`
   - Check configmap: `kubectl get configmap mosquitto-config -o yaml`

### Debugging Commands

```bash
# View generated mosquitto.conf
kubectl get configmap mosquitto-config -o jsonpath='{.data.mosquitto\.conf}'

# View password file
kubectl get configmap mosquitto-config -o jsonpath='{.data.passwd}'

# View ACL file
kubectl get configmap mosquitto-config -o jsonpath='{.data.acl}'

# Check mosquitto logs
kubectl logs -f deployment/mosquitto
```

## Migration from Anonymous

To migrate from anonymous access to authenticated access:

1. **Add users** to values.yaml
2. **Keep** `allowAnonymous: true` initially
3. **Test** that authenticated users work
4. **Set** `allowAnonymous: false`
5. **Verify** all clients can authenticate

This ensures a smooth transition without breaking existing connections.
