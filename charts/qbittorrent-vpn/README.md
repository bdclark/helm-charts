# Qbittorrent-Vpn Helm Chart

[![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square)](Chart.yaml)
[![AppVersion: 5.1.4](https://img.shields.io/badge/AppVersion-5.1.4-informational?style=flat-square)](Chart.yaml)

qBittorrent with Gluetun VPN sidecar

## Installing

### From repo

```bash
helm repo add bdclark https://bdclark.github.io/helm-charts
helm repo update
helm install qbittorrent-vpn bdclark/qbittorrent-vpn
```

### From source

```bash
helm install qbittorrent-vpn ./charts/qbittorrent-vpn
```

### Uninstall

```bash
helm uninstall qbittorrent-vpn
```

## Configuration

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Name override of the chart. |
| fullnameOverride | string | `""` | Full name override of the chart. |
| replicaCount | int | `1` | Number of replicas for the deployment. |
| imagePullSecrets | list | `[]` | Image pull secrets for the deployment. |
| deploymentAnnotations | object | `{}` | Annotations on the Deployment definition. |
| extraDeploymentLabels | object | `{}` | Additional labels on the Deployment definition. |
| podAnnotations | object | `{}` | Annotations on the pod. |
| podLabels | object | `{}` | Additional labels on the pod. |
| podSecurityContext | object | `{}` | Pod security context. |
| qbittorrent.image.repository | string | `"lscr.io/linuxserver/qbittorrent"` | qBittorrent container image repository. |
| qbittorrent.image.tag | string | `""` | Overrides the image tag whose default is the chart appVersion. |
| qbittorrent.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy. |
| qbittorrent.securityContext | object | `{}` | Container security context. |
| qbittorrent.resources | object | `{}` | Resource requests and limits for the container. |
| qbittorrent.ports | list | `[{"containerPort":8080,"name":"http","protocol":"TCP"}]` | Ports to expose from the container. |
| qbittorrent.livenessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Liveness probe configuration for the container. |
| qbittorrent.readinessProbe | object | `{"httpGet":{"path":"/","port":"http"}}` | Readiness probe configuration for the container. |
| qbittorrent.env | object | `{}` | Map of environment variables for the container |
| qbittorrent.envFrom | list | `[]` | Environment variables for the container from ConfigMap or Secret references. |
| qbittorrent.persistence.config.enabled | bool | `true` | Enable persistent volume for qbittorrent config |
| qbittorrent.persistence.config.storageClass | string | `""` | Storage class for config PVC Set to "-" to disable dynamic provisioning and use default storage class Set to "" to use cluster default storage class |
| qbittorrent.persistence.config.accessModes | list | `["ReadWriteOnce"]` | Access modes for the config PVC |
| qbittorrent.persistence.config.size | string | `"2Gi"` | Requested config PVC size |
| qbittorrent.persistence.config.existingClaim | string | `""` | Use an existing PVC instead of creating a new one |
| qbittorrent.persistence.config.annotations | object | `{}` | Annotations for config PVC |
| qbittorrent.persistence.downloads.enabled | bool | `false` | Enable persistent volume for qbittorrent downloads |
| qbittorrent.persistence.downloads.storageClass | string | `""` | Storage class for downloads PVC Set to "-" to disable dynamic provisioning and use default storage class Set to "" to use cluster default storage class |
| qbittorrent.persistence.downloads.accessModes | list | `["ReadWriteOnce"]` | Access modes for the downloads PVC |
| qbittorrent.persistence.downloads.size | string | `"2Gi"` | Requested downloads PVC size |
| qbittorrent.persistence.downloads.existingClaim | string | `""` | Use an existing PVC instead of creating a new one |
| qbittorrent.persistence.downloads.annotations | object | `{}` | Annotations for downloads PVC |
| qbittorrent.volumeMounts | list | `[]` | Additional volumeMounts for the container. |
| gluetun.enabled | bool | `true` | Enable Gluetun VPN sidecar container. |
| gluetun.lifecycleMode | string | `"nativeSidecar"` | Gluetun container lifecycle mode; determines how it is run alongside qbittorrent. Options are "nativeSidecar" (initContainer with restartPolicy Always) or "standard" (normal container). Note: native sidecar support became stable/GA in Kubernetes v1.33 (alpha in v1.28, beta in v1.29). |
| gluetun.lifecycleHooks | object | `{}` | Lifecycle hooks for the gluetun container. |
| gluetun.image.repository | string | `"qmcgaw/gluetun"` | Gluetun container image repository. |
| gluetun.image.tag | string | `"v3.41.0"` | Gluetun image tag. |
| gluetun.image.pullPolicy | string | `"IfNotPresent"` | The image pull policy. |
| gluetun.needsTunDevice | bool | `true` | Whether the Gluetun container needs /dev/net/tun device. |
| gluetun.securityContext | object | `{"capabilities":{"add":["NET_ADMIN"]}}` | Container security context. |
| gluetun.resources | object | `{}` | Resource requests and limits for the container. |
| gluetun.ports | list | `[]` | Ports to expose from the gluetun container. |
| gluetun.livenessProbe | object | `{}` | Liveness probe configuration for the container. |
| gluetun.readinessProbe | object | `{}` | Readiness probe configuration for the container. |
| gluetun.env | object | `{}` | Map of environment variables for the container |
| gluetun.envFrom | list | `[]` | Environment variables for the container from ConfigMap or Secret references. |
| gluetun.persistence.enabled | bool | `false` | Enable persistent volume for gluetun |
| gluetun.persistence.storageClass | string | `""` | Storage class for gluetun PVC Set to "-" to disable dynamic provisioning and use default storage class Set to "" to use cluster default storage class |
| gluetun.persistence.accessModes | list | `["ReadWriteOnce"]` | Access modes for the gluetun PVC |
| gluetun.persistence.size | string | `"200Mi"` | Requested gluetun PVC size |
| gluetun.persistence.existingClaim | string | `""` | Use an existing PVC instead of creating a new one |
| gluetun.persistence.annotations | object | `{}` | Annotations for gluetun PVC |
| gluetun.volumeMounts | list | `[]` | Additional volumeMounts for the gluetun container. |
| service.type | string | `"ClusterIP"` | Kubernetes Service type for the Web UI. |
| service.port | int | `8080` | The port the service will listen on for the Web UI. |
| ingress.enabled | bool | `false` | Expose the service via an Ingress. |
| ingress.className | string | `""` | Ingress  class name. |
| ingress.annotations | object | `{}` | Annotations on the Ingress resource. |
| ingress.hosts | list | `[{"host":"qbittorrent.local","paths":[{"path":"/","pathType":"ImplementationSpecific"}]}]` | Hostnames for the Ingress resource. |
| ingress.tls | list | `[]` | TLS configuration for the Ingress resource. |
| httpRoute.enabled | bool | `false` | Enable creation of HTTPRoute resource. |
| httpRoute.annotations | object | `{}` | Annotations on the HTTPRoute resource. |
| httpRoute.parentRefs | list | `[{"name":"gateway","sectionName":"http"}]` | Parent references to Gateway resources. |
| httpRoute.hostnames | list | `["qbittorrent.local"]` | List of hostnames for the HTTPRoute. |
| httpRoute.rules | list | `[{"matches":[{"path":{"type":"PathPrefix","value":"/headers"}}]}]` | List of rules and filters applied. |
| initContainers | list | `[]` | Additional init containers on the Deployment definition. NOTE: These will run before the gluetun initContainer (if enabled as such). |
| extraContainers | list | `[]` | Additional containers on the Deployment definition. |
| volumes | list | `[]` | Additional volumes on the Deployment definition. |
| nodeSelector | object | `{}` | Node selector for pod assignment. |
| tolerations | list | `[]` | Tolerations for pod assignment. |
| affinity | object | `{}` | Affinity rules for pod assignment. |
