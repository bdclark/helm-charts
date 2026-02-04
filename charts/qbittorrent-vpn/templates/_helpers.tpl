{{/*
Expand the name of the chart.
*/}}
{{- define "qbittorrent-vpn.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "qbittorrent-vpn.fullname" -}}
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
{{- define "qbittorrent-vpn.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "qbittorrent-vpn.labels" -}}
helm.sh/chart: {{ include "qbittorrent-vpn.chart" . }}
{{ include "qbittorrent-vpn.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "qbittorrent-vpn.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qbittorrent-vpn.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Render env entries from a map
*/}}
{{- define "qbittorrent-vpn.envFromMap" -}}
{{- $env := . | default (dict) -}}
{{- if not (kindIs "map" $env) -}}
{{- fail (printf "qbittorrent.env must be a map, got %s" (kindOf $env)) -}}
{{- end -}}
{{- $keys := keys $env | sortAlpha -}}
{{- range $i, $name := $keys -}}
{{- $val := get $env $name }}
- name: {{ $name | quote }}
{{- if kindIs "map" $val }}
{{- if hasKey $val "valueFrom" }}
  valueFrom:
{{ toYaml (get $val "valueFrom") | indent 4 }}
{{- else if hasKey $val "value" }}
  value: {{ (get $val "value") | toString | quote }}
{{- else }}
{{- fail (printf "env.%s is a map but missing 'valueFrom' or 'value'" $name) }}
{{- end }}
{{- else }}
  value: {{ $val | toString | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Validate configuration
*/}}
{{- define "qbittorrent-vpn.validateConfig" -}}
{{- if and .Values.qbittorrent.config.bootstrap.enabled (not .Values.qbittorrent.persistence.config.enabled) -}}
{{- fail "qbittorrent.config.bootstrap.enabled requires qbittorrent.persistence.config.enabled to be true" -}}
{{- end -}}
{{- end -}}

{{/*
Create PVC name
*/}}
{{- define "qbittorrent-vpn.pvcName" -}}
{{- $root := .root -}}
{{- $ctx := .ctx -}}
{{- $suffix := .suffix | default "" -}}
{{- if $ctx.existingClaim }}
{{- $ctx.existingClaim -}}
{{- else }}
{{- printf "%s-%s" (include "qbittorrent-vpn.fullname" $root) $suffix | trimSuffix "-" -}}
{{- end }}
{{- end }}
