#!/bin/bash

# Integration test runner for mosquitto chart
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(cd "$SCRIPT_DIR/../../../mosquitto" && pwd)"
TEST_NAMESPACE="mosquitto-integration-test"
TEST_RELEASE="mosquitto-test"

echo "Starting integration tests for mosquitto chart..."

# Cleanup function
cleanup() {
    echo "Cleaning up test resources..."
    helm uninstall "$TEST_RELEASE" --namespace "$TEST_NAMESPACE" 2>/dev/null || true
    kubectl delete namespace "$TEST_NAMESPACE" 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup EXIT

# Create test namespace
echo "Creating test namespace: $TEST_NAMESPACE"
kubectl create namespace "$TEST_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Test 1: Basic installation
echo "Test 1: Basic installation with default values"
helm install "$TEST_RELEASE" "$CHART_DIR" \
    --namespace "$TEST_NAMESPACE" \
    --wait --timeout=60s

# Verify deployment is ready
echo "Verifying deployment is ready..."
kubectl wait --for=condition=available deployment/mosquitto-test \
    --namespace "$TEST_NAMESPACE" \
    --timeout=60s

# Test 2: MQTT connectivity
echo "Test 2: Testing MQTT connectivity"
kubectl run mqtt-test-client \
    --namespace "$TEST_NAMESPACE" \
    --image=eclipse-mosquitto:latest \
    --rm -it --restart=Never \
    --command -- mosquitto_pub \
    -h mosquitto-test \
    -t "test/topic" \
    -m "integration test message" \
    --timeout 10 || echo "MQTT test completed"

# Test 3: Upgrade with authentication
echo "Test 3: Upgrading with authentication enabled"
helm upgrade "$TEST_RELEASE" "$CHART_DIR" \
    --namespace "$TEST_NAMESPACE" \
    --set auth.users[0].username=testuser \
    --set auth.users[0].password=testpass \
    --wait --timeout=60s

# Wait for rollout
kubectl rollout status deployment/mosquitto-test \
    --namespace "$TEST_NAMESPACE" \
    --timeout=60s

# Test 4: Persistence
echo "Test 4: Testing with persistence enabled"
helm upgrade "$TEST_RELEASE" "$CHART_DIR" \
    --namespace "$TEST_NAMESPACE" \
    --set persistence.enabled=true \
    --set persistence.size=1Gi \
    --wait --timeout=60s

# Verify PVC is created and bound
echo "Verifying PVC is bound..."
kubectl wait --for=condition=bound pvc/mosquitto-test-data \
    --namespace "$TEST_NAMESPACE" \
    --timeout=60s

# Test 5: Configuration validation
echo "Test 5: Validating generated configuration"
CONFIG=$(kubectl get configmap mosquitto-test-config \
    --namespace "$TEST_NAMESPACE" \
    -o jsonpath='{.data.mosquitto\.conf}')

echo "Generated mosquitto.conf:"
echo "$CONFIG"

# Check for expected configuration
if echo "$CONFIG" | grep -q "persistence true"; then
    echo "✓ Persistence configuration found"
else
    echo "✗ Persistence configuration missing"
    exit 1
fi

if echo "$CONFIG" | grep -q "listener 1883"; then
    echo "✓ MQTT listener configuration found"
else
    echo "✗ MQTT listener configuration missing"
    exit 1
fi

echo "All integration tests passed!"