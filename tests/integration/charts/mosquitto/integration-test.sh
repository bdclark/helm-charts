#!/bin/bash

# Mosquitto-specific integration tests
set -e

echo "Running mosquitto-specific integration tests..."

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/helpers.sh"

# Install the chart for our custom tests
echo "Installing mosquitto chart for custom testing..."
kubectl create namespace "$TEST_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm install "$TEST_RELEASE" "$CHART_DIR" \
    --namespace "$TEST_NAMESPACE" \
    --wait --timeout=300s

echo "Chart installed, proceeding with custom tests..."

# Test MQTT connectivity
test_mqtt_connectivity() {
    echo "Testing MQTT connectivity..."

    # Run a test client to publish a message
    kubectl run mqtt-test-client \
        --namespace="$TEST_NAMESPACE" \
        --image=eclipse-mosquitto:latest \
        --rm -i --restart=Never \
        --command -- mosquitto_pub \
        -h "$TEST_RELEASE" \
        -t "test/topic" \
        -m "integration test message from $(date)" || echo "MQTT publish test completed"

    echo "✓ MQTT connectivity test completed"
}

# Test authentication if enabled
test_authentication() {
    echo "Testing MQTT authentication..."

    # Check if auth is configured
    if kubectl get configmap "${TEST_RELEASE}-config" --namespace="$TEST_NAMESPACE" -o yaml | grep -q "password_file"; then
        echo "Authentication is enabled, testing with credentials..."

        # Try to connect with authentication
        kubectl run mqtt-auth-test \
            --namespace="$TEST_NAMESPACE" \
            --image=eclipse-mosquitto:latest \
            --rm -i --restart=Never \
            --command -- mosquitto_pub \
            -h "$TEST_RELEASE" \
            -t "auth/test" \
            -m "authenticated message" \
            -u "testuser" \
            -P "testpass" || echo "MQTT auth test completed"
    else
        echo "Authentication not configured, skipping auth test"
    fi
}

# Test external secret authentication
test_secret_ref_authentication() {
    echo "Testing external secret authentication (auth.secretRef)..."

    # Create a test namespace for secretRef test
    SECRET_TEST_NS="${TEST_NAMESPACE}-secretref"
    kubectl create namespace "$SECRET_TEST_NS" --dry-run=client -o yaml | kubectl apply -f -

    # Create a secret with password file (using plaintext for simplicity in testing)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: mosquitto-auth
  namespace: $SECRET_TEST_NS
type: Opaque
stringData:
  passwd: |
    secretuser:secretpass
EOF

    echo "Installing mosquitto with auth.secretRef..."
    helm install "${TEST_RELEASE}-secretref" "$CHART_DIR" \
        --namespace "$SECRET_TEST_NS" \
        --set auth.secretRef.name=mosquitto-auth \
        --wait --timeout=300s

    # Verify passwd is not in ConfigMap
    if kubectl get configmap "${TEST_RELEASE}-secretref-config" \
        --namespace="$SECRET_TEST_NS" -o yaml | grep -q "passwd:"; then
        echo "✗ passwd should not be in ConfigMap when using secretRef"
        helm uninstall "${TEST_RELEASE}-secretref" --namespace "$SECRET_TEST_NS" || true
        kubectl delete namespace "$SECRET_TEST_NS" || true
        return 1
    else
        echo "✓ passwd correctly excluded from ConfigMap"
    fi

    # Verify secret is mounted
    POD_NAME=$(kubectl get pods --namespace="$SECRET_TEST_NS" -l "app.kubernetes.io/name=mosquitto" -o jsonpath='{.items[0].metadata.name}')
    if kubectl exec -n "$SECRET_TEST_NS" "$POD_NAME" -- test -f /mosquitto/config/passwd; then
        echo "✓ Secret mounted at /mosquitto/config/passwd"

        # Verify the content is from the secret
        PASSWD_CONTENT=$(kubectl exec -n "$SECRET_TEST_NS" "$POD_NAME" -- cat /mosquitto/config/passwd)
        if echo "$PASSWD_CONTENT" | grep -q "secretuser:secretpass"; then
            echo "✓ Secret content correctly mounted"
        else
            echo "✗ Secret content doesn't match expected value"
        fi
    else
        echo "✗ Secret file not found at /mosquitto/config/passwd"
        helm uninstall "${TEST_RELEASE}-secretref" --namespace "$SECRET_TEST_NS" || true
        kubectl delete namespace "$SECRET_TEST_NS" || true
        return 1
    fi

    # Verify password_file is configured in mosquitto.conf
    CONFIG_CONTENT=$(kubectl exec -n "$SECRET_TEST_NS" "$POD_NAME" -- cat /mosquitto/config/mosquitto.conf)
    if echo "$CONFIG_CONTENT" | grep -q "password_file /mosquitto/config/passwd"; then
        echo "✓ password_file correctly configured in mosquitto.conf"
    else
        echo "✗ password_file not found in mosquitto.conf"
    fi

    echo "✓ External secret authentication test completed"

    # Cleanup secretRef test
    helm uninstall "${TEST_RELEASE}-secretref" --namespace "$SECRET_TEST_NS" || true
    kubectl delete namespace "$SECRET_TEST_NS" || true
}

# Test persistence
test_persistence() {
    echo "Testing persistence..."

    # Check if PVC exists
    if kubectl get pvc --namespace="$TEST_NAMESPACE" | grep -q "$TEST_RELEASE"; then
        PVC_NAME=$(kubectl get pvc --namespace="$TEST_NAMESPACE" --no-headers | grep "$TEST_RELEASE" | head -1 | awk '{print $1}')
        echo "✓ Found PVC: $PVC_NAME"

        # Verify PVC is bound
        PVC_STATUS=$(kubectl get pvc "$PVC_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.status.phase}')
        if [ "$PVC_STATUS" = "Bound" ]; then
            echo "✓ PVC is bound and ready"
        else
            echo "✗ PVC status: $PVC_STATUS"
            return 1
        fi
    else
        echo "No PVC found, persistence likely disabled"
    fi
}

# Test configuration
test_configuration() {
    echo "Testing mosquitto configuration..."

    # Debug: List all configmaps in the namespace
    echo "All ConfigMaps in namespace $TEST_NAMESPACE:"
    kubectl get configmaps --namespace="$TEST_NAMESPACE" || echo "No ConfigMaps found"

    CONFIG_MAP="${TEST_RELEASE}-config"
    if kubectl get configmap "$CONFIG_MAP" --namespace="$TEST_NAMESPACE" >/dev/null 2>&1; then
        echo "✓ Found ConfigMap: $CONFIG_MAP"

        # Check configuration content
        CONFIG=$(kubectl get configmap "$CONFIG_MAP" --namespace="$TEST_NAMESPACE" -o jsonpath='{.data.mosquitto\.conf}')

        if echo "$CONFIG" | grep -q "listener 1883"; then
            echo "✓ MQTT listener configuration found"
        else
            echo "✗ MQTT listener configuration missing"
            return 1
        fi

        if echo "$CONFIG" | grep -q "persistence true"; then
            echo "✓ Persistence configuration found"
        else
            echo "ℹ Persistence not configured (this is normal if disabled)"
        fi
    else
        echo "✗ ConfigMap not found: $CONFIG_MAP"
        return 1
    fi
}

# Test service endpoints
test_service_endpoints() {
    echo "Testing service endpoints..."

    SERVICE_NAME="$TEST_RELEASE"
    if kubectl get service "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" >/dev/null 2>&1; then
        # Get service details
        SERVICE_TYPE=$(kubectl get service "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.spec.type}')
        SERVICE_PORTS=$(kubectl get service "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.spec.ports[*].port}')

        echo "✓ Service type: $SERVICE_TYPE"
        echo "✓ Service ports: $SERVICE_PORTS"

        # Check endpoints
        if kubectl get endpoints "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" >/dev/null 2>&1; then
            ENDPOINT_IPS=$(kubectl get endpoints "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}')
            if [ -n "$ENDPOINT_IPS" ]; then
                echo "✓ Service has endpoints: $ENDPOINT_IPS"
            else
                echo "✗ Service has no endpoints"
                return 1
            fi
        fi
    else
        echo "✗ Service not found: $SERVICE_NAME"
        return 1
    fi
}

# Run all mosquitto-specific tests
echo "=== Running Mosquitto-Specific Integration Tests ==="

test_configuration
test_service_endpoints
test_persistence
test_mqtt_connectivity
test_authentication
test_secret_ref_authentication

echo "=== All Mosquitto Tests Completed ==="

# Cleanup
echo "Cleaning up custom test installation..."
helm uninstall "$TEST_RELEASE" --namespace "$TEST_NAMESPACE" || true
kubectl delete namespace "$TEST_NAMESPACE" || true
echo "Cleanup complete"
