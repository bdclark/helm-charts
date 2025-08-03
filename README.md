# Helm Charts Collection

A collection of production-ready Helm charts for various applications.

## Available Charts

### Mosquitto

Eclipse Mosquitto MQTT broker with comprehensive authentication, TLS, and persistence support.

- **Chart Version**: 0.1.0
- **App Version**: 2.0.18
- **Repository**: [mosquitto/](./mosquitto/)

#### Quick Start

```bash
# Install from source
helm install mosquitto ./mosquitto/

# See mosquitto/README.md for detailed configuration examples
```

## Development

### Prerequisites

- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [Task](https://taskfile.dev/installation/) (for automation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for testing)

### Testing

```bash
# Install testing tools
task install-tools

# Run all tests
task test

# Quick unit tests only
task test-quick

# Install locally for testing
task install-local
```

### Chart Structure

```text
charts/
├── mosquitto/              # Eclipse Mosquitto MQTT broker
│   ├── Chart.yaml          # Chart metadata
│   ├── values.yaml         # Default configuration
│   ├── AUTH.md            # Authentication guide
│   ├── scripts/           # Helper scripts
│   │   └── generate-password.sh
│   ├── templates/         # Kubernetes manifests
│   └── tests/            # Chart tests
├── tests/                 # Shared testing infrastructure
├── Taskfile.yml          # Development automation
└── .github/              # CI/CD workflows
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `task test`
5. Submit a pull request

All charts should include:

- Comprehensive unit tests
- Integration tests
- Security best practices
- Clear documentation
- Authentication support where applicable

## License

[MIT License](LICENSE)

## Support

- 📖 **Documentation**: See individual chart READMEs
- 🐛 **Issues**: [GitHub Issues](https://github.com/username/helm-charts/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/username/helm-charts/discussions)