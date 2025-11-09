# Helm Charts Collection

[![CI](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/ci.yaml)
[![Integration Tests](https://github.com/bdclark/helm-charts/actions/workflows/integration-test.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/integration-test.yaml)
[![Release Charts](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/release.yaml)

A collection of production-ready Helm charts for various applications, built with industry-standard tooling and ready for Artifact Hub discovery.

## Installation

Add this repository to your Helm client:

```bash
helm repo add your-charts https://bdclark.github.io/helm-charts
helm repo update
```

## Available Charts

| Chart | Description | Version | App Version |
|-------|-------------|---------|-------------|
| [mosquitto](charts/mosquitto/) | Eclipse Mosquitto MQTT broker | 0.3.0 | 2.0.18 |
| [music-assistant](charts/music-assistant/) | Music Assistant media library manager | 0.1.0 | 2.5.8 |

### Quick Start

```bash
# Install any chart from repository
helm install my-release your-charts/<chart-name>

# Install from source
helm install my-release ./charts/<chart-name>/
```

See individual chart READMEs for detailed configuration options.

## Development

This repository uses professional Helm tooling for multi-chart management:

- **Helm lint + helm-unittest + kubeconform** - Static and template validation
- **[Chart Testing (ct)](https://github.com/helm/chart-testing)** - Change detection utilities
- **[Chart Releaser (cr)](https://github.com/helm/chart-releaser)** - Automated releases
- **GitHub Actions** - CI/CD automation
- **[Artifact Hub](https://artifacthub.io/)** - Chart discovery

### Prerequisites

- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [Task](https://taskfile.dev/installation/) (for automation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for testing)
- [helm-unittest plugin](https://github.com/helm-unittest/helm-unittest)
- [kubeconform](https://github.com/yannh/kubeconform#installation)
- [chart-testing](https://github.com/helm/chart-testing#installation) (optional for manual change detection)
- [chart-releaser](https://github.com/helm/chart-releaser#installation)

### Development Quick Start

```bash
# Install development tools
task install-tools

# YAML lint / static analysis
task lint

# Verify a single chart with helm lint + helm-unittest + kubeconform
task verify-chart CHART=<chart-name>

# Verify every chart
task verify-all

# Run integration suite (kind cluster required)
task pytest

# Package for local testing
task package-all
```

### Development Workflow

1. **Create/modify charts** in `charts/` directory
2. **Add/maintain Helm unit tests** in `charts/<chart>/tests/`
3. **Add/maintain integration tests** in `tests/integration/pytest_suite/charts/test_<chart>.py`
4. **Validate locally** with `task verify-chart CHART=<chart-name>` and targeted `task pytest`
5. **Create PR** - triggers the CI workflow (static validation + per-chart verification)
6. **Merge to main** - triggers release workflow and publishes to Artifact Hub

### Testing

#### Static Validation

```bash
# Run yamllint across every chart
task lint

# Run Helm lint, helm-unittest, and kubeconform for one chart
task verify-chart CHART=<chart-name>

# Run the full static suite for every chart
task verify-all
```

#### Chart Testing (ct) utilities

Change detection helpers are still available when you need ct locally:

```bash
task ct-list     # show changed charts
task ct-lint     # run ct lint with debug output
task ct-install  # run ct install (requires a cluster)
```

#### Integration Tests

Chart-specific tests use the pytest + kind harness:

```bash
# Create/update the virtual environment
task pyenv

# Run the full integration suite (spins up its own kind cluster)
task pytest

# Run only one chart's tests
task pytest PYTEST_ARGS=tests/integration/pytest_suite/charts/test_<chart>.py
```

**Available Integration Tests:**

- **mosquitto**: MQTT connectivity, authentication, configuration, persistence
- **music-assistant**: Web interface, streaming ports, application startup, networking modes

#### Pytest Harness

The pytest + kind integration harness lives under `tests/integration/pytest_suite`. It:

- provisions a disposable kind cluster per test session,
- installs charts with Helm via reusable helpers, and
- inspects Kubernetes resources through the official Python client.

Use `task pyenv` to create the local virtual environment and `task pytest` to execute
the suite.

**GitHub CI Integration:**

- The `CI` workflow performs yamllint, helm lint, helm-unittest, and kubeconform checks per changed chart
- Integration tests run in parallel via the dedicated `integration-test` workflow

### Releases

Releases are automated via GitHub Actions:

1. **Merge to main** runs CI + Integration Tests
2. **Successful Integration Tests** trigger the release workflow
3. **Chart Releaser** packages and publishes charts to `gh-pages`
4. **Charts are also pushed to OCI** (`ghcr.io/<owner>/helm-charts`)
5. **Artifact Hub** indexes releases automatically

Manual release testing:

```bash
# Create local packages
task release-local

# Test local repository
helm repo add local file://$(pwd)/.cr-release-packages
helm search repo local/
```

### OCI Registry Support

Charts are published to GitHub Container Registry as OCI artifacts. To install directly:

```bash
helm registry login ghcr.io -u <github-username> -p <token>

# Pull and install a chart release
helm pull oci://ghcr.io/bdclark/helm-charts/mosquitto --version <version>
helm install my-mosquitto oci://ghcr.io/bdclark/helm-charts/mosquitto --version <version>
```

The OCI repository path follows the convention `ghcr.io/<owner>/helm-charts/<chart>`.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the structure
4. Add/update tests for your chart
5. Run `task test-all` to validate
6. Submit a pull request

### Chart Requirements

All charts must include:

- Proper Chart.yaml with Artifact Hub annotations
- Comprehensive unit tests (helm-unittest)
- Integration tests for key functionality
- Security best practices
- Clear documentation with examples
- Version bumps for changes

## License

[MIT License](LICENSE)

## Support

- **Documentation**: See individual chart READMEs
- **Issues**: [GitHub Issues](https://github.com/bdclark/helm-charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bdclark/helm-charts/discussions)
- **Chart Discovery**: [Artifact Hub](https://artifacthub.io/packages/search?repo=your-helm-charts)
