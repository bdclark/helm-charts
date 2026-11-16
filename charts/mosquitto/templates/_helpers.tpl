{{/*
Expand the name of the chart.
*/}}
{{- define "mosquitto.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mosquitto.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mosquitto.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mosquitto.labels" -}}
helm.sh/chart: {{ include "mosquitto.chart" . }}
{{ include "mosquitto.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mosquitto.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mosquitto.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
The ConfigMap's data: mosquitto.conf, and the passwd and acl files. The
Deployment's checksum/config hashes this, so the broker restarts when its
config changes and not for unrelated values, such as Service annotations.
*/}}
{{- define "mosquitto.configData" -}}
mosquitto.conf: |
  # Auto-generated mosquitto configuration
  {{- if .Values.persistence.enabled }}
  persistence true
  persistence_location /mosquitto/data/
  {{- else }}
  persistence false
  {{- end }}

  {{- if and .Values.config.allowAnonymous (not .Values.auth.secretRef.name) (not .Values.auth.users) }}
  allow_anonymous true
  {{- else }}
  allow_anonymous false
  {{- end }}

  # Logging configuration
  log_dest stdout
  log_type {{ .Values.config.logLevel }}

  {{- if gt (.Values.config.maxConnections | int) 0 }}
  # Connection limits
  max_connections {{ .Values.config.maxConnections }}
  {{- end }}

  {{- if or .Values.auth.secretRef.name .Values.auth.users }}
  password_file /mosquitto/config/passwd
  {{- end }}

  {{- if .Values.auth.acls }}
  acl_file /mosquitto/config/acl
  {{- end }}

  # Listeners based on enabled service ports
  {{- range $name, $config := .Values.service.ports }}
  {{- if $config.enabled }}
  {{- if eq $name "mqtt" }}
  listener {{ $config.targetPort }}
  {{- else if eq $name "mqttTls" }}
  listener {{ $config.targetPort }}
  {{- if $config.tls.secretName }}
  cafile /mosquitto/certs/{{ $config.tls.caFile }}
  certfile /mosquitto/certs/{{ $config.tls.certFile }}
  keyfile /mosquitto/certs/{{ $config.tls.keyFile }}
  {{- end }}
  {{- else if eq $name "websocket" }}
  listener {{ $config.targetPort }}
  protocol websockets
  {{- end }}
  {{- end }}
  {{- end }}

  {{- if .Values.config.extraConfig }}
  # Additional custom configuration
{{ .Values.config.extraConfig | indent 2 }}
  {{- end }}

{{- if and .Values.auth.users (not .Values.auth.secretRef.name) }}
passwd: |
  {{- range .Values.auth.users }}
  {{- if .passwordHash }}
  {{ .username }}:{{ .passwordHash }}
  {{- else if .password }}
  {{ .username }}:{{ .password }}
  {{- end }}
  {{- end }}
{{- end }}

{{- if .Values.auth.acls }}
acl: |
{{ .Values.auth.acls | indent 2 }}
{{- end }}
{{- end }}
