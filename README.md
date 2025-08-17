# Helm Charts Collection

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
| [mosquitto](charts/mosquitto/) | Eclipse Mosquitto MQTT broker | 0.1.0 | 2.0.18 |

### Mosquitto

Eclipse Mosquitto MQTT broker with comprehensive authentication, TLS, and persistence support.

```bash
# Install from repository
helm install mosquitto your-charts/mosquitto

# Install from source
helm install mosquitto ./charts/mosquitto/

# See charts/mosquitto/README.md for detailed configuration
```

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

### Quick Start

```bash
# Install development tools
task install-tools

# Lint all charts
task lint-all

# Test specific chart
task test CHART=mosquitto

# Test all charts (requires cluster)
task test-all

# Package for local testing
task package-all
```

### Repository Structure

```text
helm-charts/
├── charts/                     # Chart packages
│   └── mosquitto/              # Eclipse Mosquitto MQTT broker
├── tests/
│   └── integration/            # Custom integration tests
│       ├── common/             # Shared test framework
│       └── charts/             # Chart-specific tests
├── .github/workflows/          # CI/CD automation
│   ├── lint-test.yaml          # PR testing
│   └── release.yaml            # Release automation
├── ct.yaml                     # Chart Testing configuration
├── cr.yaml                     # Chart Releaser configuration
├── artifacthub-repo.yml        # Artifact Hub metadata
└── Taskfile.yml               # Development automation
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

#### Custom Integration Tests
Chart-specific tests for advanced validation:

```bash
# Run custom tests for specific chart
task test-custom CHART=mosquitto

# Run custom tests for all charts
task test-custom-all
```

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

### Artifact Hub Integration

This repository is configured for [Artifact Hub](https://artifacthub.io/) discovery:

- Repository metadata in `artifacthub-repo.yml`
- Chart annotations in `Chart.yaml`
- Automated security scanning
- Usage analytics and metrics

## License

[MIT License](LICENSE)

## Support

- **Documentation**: See individual chart READMEs
- **Issues**: [GitHub Issues](https://github.com/bdclark/helm-charts/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bdclark/helm-charts/discussions)
- **Chart Discovery**: [Artifact Hub](https://artifacthub.io/packages/search?repo=your-helm-charts)
