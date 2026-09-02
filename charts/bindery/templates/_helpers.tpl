{{/*
Expand the name of the chart.
*/}}
{{- define "bindery.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "bindery.fullname" -}}
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
{{- define "bindery.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "bindery.labels" -}}
helm.sh/chart: {{ include "bindery.chart" . }}
{{ include "bindery.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "bindery.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bindery.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Validate SQLite-safe deployment settings.
*/}}
{{- define "bindery.validateConfig" -}}
{{- if gt (int .Values.replicaCount) 1 -}}
{{- fail "replicaCount must be 0 or 1 because Bindery uses SQLite" -}}
{{- end -}}
{{- if ne .Values.strategy.type "Recreate" -}}
{{- fail "strategy.type must be Recreate because Bindery uses SQLite" -}}
{{- end -}}
{{- end -}}

{{/*
Render env entries from a map.
*/}}
{{- define "bindery.envFromMap" -}}
{{- $env := . | default (dict) -}}
{{- if not (kindIs "map" $env) -}}
{{- fail (printf ".env must be a map, got %s" (kindOf $env)) -}}
{{- end -}}
{{- $keys := keys $env | sortAlpha -}}
{{- range $name := $keys -}}
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
