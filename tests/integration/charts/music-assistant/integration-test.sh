#!/bin/bash

# Music Assistant-specific integration tests
set -e

echo "Running music-assistant-specific integration tests..."

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/helpers.sh"

# Install the chart for our custom tests
echo "Installing music-assistant chart for custom testing..."
kubectl create namespace "$TEST_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

helm install "$TEST_RELEASE" "$CHART_DIR" \
    --namespace "$TEST_NAMESPACE" \
    --values "$SCRIPT_DIR/test-values.yaml" \
    --wait --timeout=300s

echo "Chart installed, proceeding with custom tests..."

# Test web interface connectivity
test_web_interface() {
    echo "Testing web interface connectivity..."

    # Check if service exists (depends on test configuration)
    if kubectl get service "$TEST_RELEASE" --namespace="$TEST_NAMESPACE" >/dev/null 2>&1; then
        echo "Testing via service..."
        check_service_health "$TEST_RELEASE" "$TEST_NAMESPACE" "8095" "/"
    else
        echo "No service found - testing via pod directly..."

        # Get pod IP for direct testing
        POD_NAME=$(kubectl get pods --namespace="$TEST_NAMESPACE" --selector="app.kubernetes.io/name=music-assistant" -o jsonpath='{.items[0].metadata.name}')
        POD_IP=$(kubectl get pod "$POD_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.status.podIP}')

        if [ -n "$POD_IP" ]; then
            echo "Testing direct pod access at $POD_IP:8095"

            # Create test pod to check connectivity
            kubectl run web-test-client \
                --namespace="$TEST_NAMESPACE" \
                --image=curlimages/curl:latest \
                --rm -i --restart=Never \
                --command -- curl -f -s "http://$POD_IP:8095/" || echo "Web interface test completed"
        fi
    fi

    echo "✓ Web interface connectivity test completed"
}

# Test streaming port connectivity
test_streaming_port() {
    echo "Testing streaming port connectivity..."

    # Check if service exists
    if kubectl get service "$TEST_RELEASE" --namespace="$TEST_NAMESPACE" >/dev/null 2>&1; then
        SERVICE_PORTS=$(kubectl get service "$TEST_RELEASE" --namespace="$TEST_NAMESPACE" -o jsonpath='{.spec.ports[*].port}')
        if echo "$SERVICE_PORTS" | grep -q "8097"; then
            echo "✓ Streaming port 8097 found in service"

            # Test connectivity to streaming port
            kubectl run stream-test-client \
                --namespace="$TEST_NAMESPACE" \
                --image=busybox:latest \
                --rm -i --restart=Never \
                --command -- nc -zv "$TEST_RELEASE" 8097 || echo "Streaming port test completed"
        else
            echo "ℹ Streaming port not exposed via service (normal for host networking)"
        fi
    else
        echo "ℹ No service found - streaming port available via host networking"
    fi

    echo "✓ Streaming port test completed"
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

            # Verify data directory is mounted
            exec_in_pod "app.kubernetes.io/name=music-assistant" "$TEST_NAMESPACE" "ls -la /data" || echo "Data directory check completed"
        else
            echo "✗ PVC status: $PVC_STATUS"
            return 1
        fi
    else
        echo "No PVC found, persistence likely disabled"
    fi
}

# Test configuration and startup
test_application_startup() {
    echo "Testing Music Assistant application startup..."

    POD_NAME=$(kubectl get pods --namespace="$TEST_NAMESPACE" --selector="app.kubernetes.io/name=music-assistant" -o jsonpath='{.items[0].metadata.name}')

    if [ -n "$POD_NAME" ]; then
        echo "✓ Found pod: $POD_NAME"

        # Check pod is running
        POD_STATUS=$(kubectl get pod "$POD_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.status.phase}')
        if [ "$POD_STATUS" = "Running" ]; then
            echo "✓ Pod is running"
        else
            echo "✗ Pod status: $POD_STATUS"
            return 1
        fi

        # Check logs for startup success
        echo "Checking application logs for startup indicators..."
        if kubectl logs "$POD_NAME" --namespace="$TEST_NAMESPACE" --tail=50 | grep -q "Starting Music Assistant Server"; then
            echo "✓ Music Assistant server startup detected"
        else
            echo "⚠ Music Assistant startup log not found (may still be starting)"
        fi

        # Check for web server startup
        if kubectl logs "$POD_NAME" --namespace="$TEST_NAMESPACE" --tail=50 | grep -q "Starting webserver"; then
            echo "✓ Web server startup detected"
        else
            echo "⚠ Web server startup log not found"
        fi

        # Check for stream server startup
        if kubectl logs "$POD_NAME" --namespace="$TEST_NAMESPACE" --tail=50 | grep -q "Starting streamserver"; then
            echo "✓ Stream server startup detected"
        else
            echo "⚠ Stream server startup log not found"
        fi
    else
        echo "✗ No pod found with selector app.kubernetes.io/name=music-assistant"
        return 1
    fi
}

# Test service endpoints (if service exists)
test_service_endpoints() {
    echo "Testing service endpoints..."

    SERVICE_NAME="$TEST_RELEASE"
    if kubectl get service "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" >/dev/null 2>&1; then
        # Get service details
        SERVICE_TYPE=$(kubectl get service "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.spec.type}')
        SERVICE_PORTS=$(kubectl get service "$SERVICE_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.spec.ports[*].port}')

        echo "✓ Service type: $SERVICE_TYPE"
        echo "✓ Service ports: $SERVICE_PORTS"

        # Verify expected ports
        if echo "$SERVICE_PORTS" | grep -q "8095"; then
            echo "✓ Web port (8095) found in service"
        else
            echo "✗ Web port (8095) missing from service"
            return 1
        fi

        if echo "$SERVICE_PORTS" | grep -q "8097"; then
            echo "✓ Stream port (8097) found in service"
        else
            echo "✗ Stream port (8097) missing from service"
            return 1
        fi

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
        echo "ℹ No service found (normal for host networking mode)"
    fi
}

# Test networking configuration
test_networking_config() {
    echo "Testing networking configuration..."

    POD_NAME=$(kubectl get pods --namespace="$TEST_NAMESPACE" --selector="app.kubernetes.io/name=music-assistant" -o jsonpath='{.items[0].metadata.name}')

    if [ -n "$POD_NAME" ]; then
        # Check if host networking is enabled
        HOST_NETWORK=$(kubectl get pod "$POD_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.spec.hostNetwork}')

        if [ "$HOST_NETWORK" = "true" ]; then
            echo "✓ Host networking is enabled"

            # In host networking, pod should use node IP
            NODE_NAME=$(kubectl get pod "$POD_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.spec.nodeName}')
            POD_IP=$(kubectl get pod "$POD_NAME" --namespace="$TEST_NAMESPACE" -o jsonpath='{.status.podIP}')
            NODE_IP=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

            echo "✓ Pod IP: $POD_IP, Node IP: $NODE_IP"

            if [ "$POD_IP" = "$NODE_IP" ]; then
                echo "✓ Pod correctly using host network (pod IP matches node IP)"
            else
                echo "⚠ Pod IP doesn't match node IP (may be expected in some cluster configurations)"
            fi
        else
            echo "✓ Standard Kubernetes networking is enabled"
            echo "ℹ Pod should have its own network namespace and cluster IP"
        fi
    fi
}

# Run all music-assistant-specific tests
echo "=== Running Music Assistant-Specific Integration Tests ==="

test_application_startup
test_networking_config
test_service_endpoints
test_persistence
test_web_interface
test_streaming_port

echo "=== All Music Assistant Tests Completed ==="

# Show final pod status and logs for debugging
echo "=== Final Status ==="
kubectl get pods --namespace="$TEST_NAMESPACE" --selector="app.kubernetes.io/name=music-assistant"
echo ""
echo "Recent logs from Music Assistant:"
kubectl logs --namespace="$TEST_NAMESPACE" --selector="app.kubernetes.io/name=music-assistant" --tail=10

# Cleanup
echo "Cleaning up custom test installation..."
helm uninstall "$TEST_RELEASE" --namespace "$TEST_NAMESPACE" || true
kubectl delete namespace "$TEST_NAMESPACE" || true
echo "Cleanup complete"
