# Helm Charts Collection

[![Lint and Test Charts](https://github.com/bdclark/helm-charts/actions/workflows/lint-test.yaml/badge.svg)](https://github.com/bdclark/helm-charts/actions/workflows/lint-test.yaml)
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

- **[Chart Testing (ct)](https://github.com/helm/chart-testing)** - Linting and testing
- **[Chart Releaser (cr)](https://github.com/helm/chart-releaser)** - Automated releases
- **GitHub Actions** - CI/CD automation
- **[Artifact Hub](https://artifacthub.io/)** - Chart discovery

### Prerequisites

- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [Task](https://taskfile.dev/installation/) (for automation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for testing)
- [chart-testing](https://github.com/helm/chart-testing#installation)
- [chart-releaser](https://github.com/helm/chart-releaser#installation)

### Development Quick Start

```bash
# Install development tools
task install-tools

# Lint all charts
task lint-all

# Test specific chart
task test CHART=<chart-name>

# Test all charts (requires cluster)
task test-all

# Package for local testing
task package-all
```

### Development Workflow

1. **Create/modify charts** in `charts/` directory
2. **Add tests** in `tests/integration/charts/<chart-name>/`
3. **Test locally**: `task test CHART=<chart-name>`
4. **Create PR** - triggers lint and test workflow
5. **Merge to main** - triggers release workflow
6. **Charts published** to GitHub Pages and indexed by Artifact Hub

### Testing

#### Chart Testing (ct)

Professional linting and testing with change detection:

```bash
# List charts that would be tested
task ct-list

# Lint with chart-testing
task ct-lint

# Install test with chart-testing
task ct-install
```

#### Integration Tests

Chart-specific tests for advanced validation:

```bash
# Run integration tests for specific chart
task test-custom CHART=<chart-name>

# Run integration tests for all charts
task test-custom-all
```

**Available Integration Tests:**

- **mosquitto**: MQTT connectivity, authentication, configuration, persistence
- **music-assistant**: Web interface, streaming ports, application startup, networking modes

**GitHub CI Integration:**

- Integration tests run automatically on PRs and pushes to main/develop
- Tests run in parallel using matrix strategy for efficiency
- Separate workflow from lint-test for better visibility and control

### Releases

Releases are automated via GitHub Actions:

1. **Push to main** triggers release workflow
2. **Chart Releaser** packages and releases charts
3. **GitHub Pages** serves the repository
4. **Artifact Hub** indexes releases automatically

Manual release testing:

```bash
# Create local packages
task release-local

# Test local repository
helm repo add local file://$(pwd)/.cr-release-packages
helm search repo local/
```

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
