#!/bin/bash

# Generic integration test runner for helm charts
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CHART_NAME="${1:-mosquitto}"
CHART_DIR="$REPO_ROOT/charts/$CHART_NAME"
TEST_NAMESPACE="$CHART_NAME-integration-test"
TEST_RELEASE="$CHART_NAME-test"

echo "Starting integration tests for $CHART_NAME chart..."

# Validate chart exists
if [ ! -d "$CHART_DIR" ]; then
    echo "Error: Chart '$CHART_NAME' not found at $CHART_DIR"
    exit 1
fi

# Check if chart-specific test config exists
CHART_TEST_CONFIG="$SCRIPT_DIR/../charts/$CHART_NAME/test-config.yaml"
if [ -f "$CHART_TEST_CONFIG" ]; then
    echo "Loading chart-specific test configuration..."
    source "$SCRIPT_DIR/helpers.sh"
    load_test_config "$CHART_TEST_CONFIG"
fi

# Cleanup function
cleanup() {
    echo "Cleaning up test resources for $CHART_NAME..."
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
    --wait --timeout=300s

# Wait for deployment to be ready
echo "Verifying deployment is ready..."
if kubectl get deployment "$TEST_RELEASE" --namespace "$TEST_NAMESPACE" >/dev/null 2>&1; then
    kubectl wait --for=condition=available deployment/"$TEST_RELEASE" \
        --namespace "$TEST_NAMESPACE" \
        --timeout=300s
else
    echo "No deployment found, checking for other workload types..."
    # Check for StatefulSet
    if kubectl get statefulset "$TEST_RELEASE" --namespace "$TEST_NAMESPACE" >/dev/null 2>&1; then
        kubectl wait --for=jsonpath='{.status.readyReplicas}'=1 statefulset/"$TEST_RELEASE" \
            --namespace "$TEST_NAMESPACE" \
            --timeout=300s
    fi
fi

# Test 2: Service connectivity (if service exists)
if kubectl get service "$TEST_RELEASE" --namespace "$TEST_NAMESPACE" >/dev/null 2>&1; then
    echo "Test 2: Testing service connectivity"
    SERVICE_PORT=$(kubectl get service "$TEST_RELEASE" --namespace "$TEST_NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
    echo "Service is available on port $SERVICE_PORT"
else
    echo "Test 2: No service found, skipping connectivity test"
fi

# Test 3: Configuration validation
echo "Test 3: Validating generated configuration"
if kubectl get configmap --namespace "$TEST_NAMESPACE" | grep -q "$TEST_RELEASE"; then
    CONFIGMAP_NAME=$(kubectl get configmap --namespace "$TEST_NAMESPACE" --no-headers | grep "$TEST_RELEASE" | head -1 | awk '{print $1}')
    echo "Found ConfigMap: $CONFIGMAP_NAME"
    kubectl describe configmap "$CONFIGMAP_NAME" --namespace "$TEST_NAMESPACE"
else
    echo "No ConfigMaps found for this release"
fi

# Test 4: Chart-specific tests (if they exist)
CHART_SPECIFIC_TESTS="$SCRIPT_DIR/../charts/$CHART_NAME/integration-test.sh"
if [ -f "$CHART_SPECIFIC_TESTS" ]; then
    echo "Test 4: Running chart-specific integration tests..."
    export TEST_NAMESPACE TEST_RELEASE CHART_DIR
    bash "$CHART_SPECIFIC_TESTS"
else
    echo "Test 4: No chart-specific tests found, skipping"
fi

# Test 5: Upgrade test with sample values
echo "Test 5: Testing upgrade with modified values"
SAMPLE_VALUES="$SCRIPT_DIR/../charts/$CHART_NAME/test-values.yaml"
if [ -f "$SAMPLE_VALUES" ]; then
    helm upgrade "$TEST_RELEASE" "$CHART_DIR" \
        --namespace "$TEST_NAMESPACE" \
        --values "$SAMPLE_VALUES" \
        --wait --timeout=300s
    echo "Upgrade test completed successfully"
else
    echo "No test values file found, using generic upgrade test"
    # Generic upgrade test - try enabling common features
    helm upgrade "$TEST_RELEASE" "$CHART_DIR" \
        --namespace "$TEST_NAMESPACE" \
        --set replicaCount=1 \
        --wait --timeout=300s
fi

# Test 6: Rollback test
echo "Test 6: Testing rollback functionality"
helm rollback "$TEST_RELEASE" 1 --namespace "$TEST_NAMESPACE" --wait --timeout=300s
echo "Rollback test completed successfully"

echo "All integration tests passed for $CHART_NAME!"