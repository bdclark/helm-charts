#!/bin/bash

# Helper functions for integration tests

# Load test configuration from YAML file
load_test_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        echo "Warning: Test config file not found: $config_file"
        return 1
    fi
    
    # Extract values from YAML (simple parsing)
    if command -v yq >/dev/null 2>&1; then
        # Use yq if available for proper YAML parsing
        TEST_TIMEOUT=$(yq eval '.timeout // 300' "$config_file")
        CUSTOM_VALUES=$(yq eval '.customValues // ""' "$config_file")
        SKIP_TESTS=$(yq eval '.skipTests // []' "$config_file")
    else
        # Fallback to grep-based parsing
        TEST_TIMEOUT=$(grep "timeout:" "$config_file" | cut -d: -f2 | tr -d ' ' || echo "300")
        CUSTOM_VALUES=$(grep "customValues:" "$config_file" | cut -d: -f2- | tr -d ' ')
    fi
    
    export TEST_TIMEOUT CUSTOM_VALUES SKIP_TESTS
}

# Check if a test should be skipped
should_skip_test() {
    local test_name="$1"
    
    if [ -z "$SKIP_TESTS" ]; then
        return 1  # Don't skip
    fi
    
    # Simple check if test is in skip list
    echo "$SKIP_TESTS" | grep -q "$test_name"
}

# Wait for pod to be ready with timeout
wait_for_pod_ready() {
    local pod_selector="$1"
    local namespace="$2"
    local timeout="${3:-300}"
    
    echo "Waiting for pod with selector '$pod_selector' to be ready..."
    kubectl wait --for=condition=ready pod \
        --selector="$pod_selector" \
        --namespace="$namespace" \
        --timeout="${timeout}s"
}

# Check if service is responding
check_service_health() {
    local service_name="$1"
    local namespace="$2"
    local port="$3"
    local path="${4:-/}"
    
    echo "Checking health of service $service_name:$port$path"
    
    # Use port-forward to test connectivity
    kubectl port-forward --namespace="$namespace" "service/$service_name" "8080:$port" &
    local pf_pid=$!
    
    # Give port-forward time to establish
    sleep 5
    
    # Test connectivity
    local health_check=false
    if curl -f -s "http://localhost:8080$path" >/dev/null 2>&1; then
        health_check=true
        echo "✓ Service health check passed"
    else
        echo "✗ Service health check failed"
    fi
    
    # Clean up port-forward
    kill $pf_pid 2>/dev/null || true
    
    return $([ "$health_check" = true ] && echo 0 || echo 1)
}

# Run a command inside a pod
exec_in_pod() {
    local pod_selector="$1"
    local namespace="$2"
    local command="$3"
    
    local pod_name
    pod_name=$(kubectl get pods --namespace="$namespace" --selector="$pod_selector" -o jsonpath='{.items[0].metadata.name}')
    
    if [ -z "$pod_name" ]; then
        echo "Error: No pod found with selector '$pod_selector'"
        return 1
    fi
    
    echo "Executing command in pod $pod_name: $command"
    kubectl exec --namespace="$namespace" "$pod_name" -- sh -c "$command"
}

# Validate Kubernetes resources exist
validate_k8s_resources() {
    local namespace="$1"
    local release_name="$2"
    
    echo "Validating Kubernetes resources for release $release_name..."
    
    # Check common resources
    local resources=("deployment" "service" "configmap" "secret" "statefulset" "ingress")
    
    for resource in "${resources[@]}"; do
        if kubectl get "$resource" --namespace="$namespace" 2>/dev/null | grep -q "$release_name"; then
            echo "✓ Found $resource for $release_name"
        fi
    done
}

# Generate test data
generate_test_data() {
    local data_type="$1"
    
    case "$data_type" in
        "random_string")
            openssl rand -hex 16
            ;;
        "timestamp")
            date +%s
            ;;
        "uuid")
            if command -v uuidgen >/dev/null 2>&1; then
                uuidgen | tr '[:upper:]' '[:lower:]'
            else
                # Fallback UUID generation
                python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || echo "test-$(date +%s)"
            fi
            ;;
        *)
            echo "test-data-$(date +%s)"
            ;;
    esac
}