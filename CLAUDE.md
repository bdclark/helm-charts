# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This is a Helm charts repository containing custom Kubernetes deployment charts. The repository follows standard Helm chart structure:

- **Root level**: Contains global configuration files and chart directories
- **Chart directories** (e.g., `mosquitto/`): Each chart is a self-contained directory with:
  - `Chart.yaml`: Chart metadata and version information
  - `values.yaml`: Default configuration values for the chart
  - `templates/`: Kubernetes resource templates using Go templating
  - `templates/_helpers.tpl`: Shared template helpers and functions

## Common Development Commands

### Helm Operations
```bash
# Validate chart syntax and structure
helm lint mosquitto/

# Test template rendering locally
helm template mosquitto mosquitto/

# Package chart for distribution
helm package mosquitto/

# Install chart to Kubernetes cluster
helm install my-mosquitto mosquitto/

# Upgrade existing release
helm upgrade my-mosquitto mosquitto/

# Uninstall release
helm uninstall my-mosquitto
```

### Validation and Testing
```bash
# Spell check (requires cspell installation)
npx cspell "**/*.{yaml,yml,md}"

# Dry-run installation to validate
helm install my-mosquitto mosquitto/ --dry-run --debug

# Validate Kubernetes resources
kubectl apply --dry-run=client -f <(helm template mosquitto mosquitto/)
```

## Chart Architecture

### Template System
Charts use Helm's Go templating engine with these key patterns:

- **Helper templates** (`_helpers.tpl`): Reusable template functions for names, labels, and selectors
- **Value interpolation**: All configuration comes from `values.yaml` using `.Values` syntax
- **Conditional rendering**: Templates use `{{- if }}` blocks for optional features
- **Resource naming**: Consistent naming using helper templates like `mosquitto.fullname`

### Standard Kubernetes Resources
Each chart typically includes:
- **Deployment**: Main application workload
- **Service**: Network access to pods
- **ServiceAccount**: Pod identity and permissions
- **Ingress**: External HTTP/HTTPS access (optional)
- **ConfigMap/Secret**: Configuration and sensitive data (as needed)

### Configuration Patterns
- All charts follow the standard `values.yaml` structure with sections for:
  - Image configuration (`image.repository`, `image.tag`, `image.pullPolicy`)
  - Service configuration (`service.type`, `service.port`)
  - Resource limits and requests
  - Autoscaling configuration
  - Security contexts and pod security
  - Ingress and networking options

## Development Workflow

1. **Modify templates**: Edit files in `templates/` directory
2. **Update values**: Modify `values.yaml` for configuration changes
3. **Validate syntax**: Run `helm lint <chart-name>/`
4. **Test rendering**: Use `helm template <chart-name>/ <chart-name>/`
5. **Test deployment**: Use `--dry-run` flag before actual installation

## Chart Versioning

- **Chart version** (`version` in Chart.yaml): Increment when changing chart structure or templates
- **App version** (`appVersion` in Chart.yaml): Should match the version of the deployed application
- Follow semantic versioning for chart versions