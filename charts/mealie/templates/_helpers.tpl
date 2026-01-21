{{/*
Expand the name of the chart.
*/}}
{{- define "mealie.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mealie.fullname" -}}
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
{{- define "mealie.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mealie.labels" -}}
helm.sh/chart: {{ include "mealie.chart" . }}
{{ include "mealie.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mealie.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mealie.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Validate replicaCount vs database engine
*/}}
{{- define "mealie.validate.replicas" -}}
{{- $engine := .Values.database.engine | default "sqlite" -}}
{{- $replicas := int (.Values.replicaCount | default 1) -}}

{{- if and (eq $engine "sqlite") (gt $replicas 1) -}}
{{- fail "SQLite cannot be used with multiple replicas. Please use Postgres or set replicaCount to 1." -}}
{{- end -}}
{{- end }}

{{/*
SQLite must have persistence enabled
*/}}
{{- define "mealie.validate.sqlite.persistence" -}}
{{- if eq .Values.database.engine "sqlite" -}}
  {{- if not .Values.persistence.enabled -}}
    {{- fail "SQLite requires persistence to be enabled. Please enable persistence or use Postgres as the database engine." -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
Return a value or a valueFrom.secretKeyRef block.
*/}}
{{- define "mealie.env.valueOrSecret" -}}
{{- $name := .name -}}
{{- $value := default "" .value -}}
{{- $secretName := default "" .secretName -}}
{{- $secretKey := default "" .secretKey -}}
{{- if or (and $secretName $secretKey) (ne (printf "%v" $value) "") }}
- name: {{ $name }}
  {{- if and $secretName $secretKey }}
  valueFrom:
    secretKeyRef:
      name: {{ $secretName | quote }}
      key: {{ $secretKey | quote }}
  {{- else }}
  value: {{ printf "%v" $value | quote }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render Postgres env vars for Mealie.
*/}}
{{- define "mealie.env.postgres" -}}
{{- $pg := .Values.database.postgres -}}
{{- $urlValue := default "" $pg.urlOverride.value -}}
{{- $urlSecretName := default "" $pg.urlOverride.existingSecret.name -}}
{{- $urlSecretKey := default "" $pg.urlOverride.existingSecret.key -}}
{{- if or $urlValue (and $urlSecretName $urlSecretKey) -}}
{{- include "mealie.env.valueOrSecret" (dict
  "name"       "POSTGRES_URL_OVERRIDE"
  "value"      $urlValue
  "secretName" $urlSecretName
  "secretKey"  $urlSecretKey
) }}
{{- else -}}
{{- include "mealie.env.valueOrSecret" (dict
  "name"       "POSTGRES_SERVER"
  "value"      $pg.server.value
  "secretName" $pg.server.existingSecret.name
  "secretKey"  $pg.server.existingSecret.key
) -}}
{{- include "mealie.env.valueOrSecret" (dict
  "name"       "POSTGRES_PORT"
  "value"      $pg.port.value
  "secretName" $pg.port.existingSecret.name
  "secretKey"  $pg.port.existingSecret.key
) }}
{{- include "mealie.env.valueOrSecret" (dict
  "name"       "POSTGRES_DB"
  "value"      $pg.db.value
  "secretName" $pg.db.existingSecret.name
  "secretKey"  $pg.db.existingSecret.key
) }}
{{- include "mealie.env.valueOrSecret" (dict
  "name"       "POSTGRES_USER"
  "value"      $pg.user.value
  "secretName" $pg.user.existingSecret.name
  "secretKey"  $pg.user.existingSecret.key
) }}
{{- include "mealie.env.valueOrSecret" (dict
  "name"       "POSTGRES_PASSWORD"
  "value"      $pg.password.value
  "secretName" $pg.password.existingSecret.name
  "secretKey"  $pg.password.existingSecret.key
) }}
{{- end -}}
{{- end }}

{{/*
Fail fast on invalid DB config
*/}}
{{- define "mealie.validate.database" -}}
{{- if eq .Values.database.engine "postgres" -}}
  {{- $pg := .Values.database.postgres -}}

  {{- $hasUrl := or
      $pg.urlOverride.value
      (and $pg.urlOverride.existingSecret.name $pg.urlOverride.existingSecret.key)
  -}}

  {{- if not $hasUrl -}}
    {{- if not (or $pg.server.value (and $pg.server.existingSecret.name $pg.server.existingSecret.key)) -}}
      {{- fail "postgres requires server if not using urlOverride" -}}
    {{- end -}}
    {{- if not (or $pg.user.value (and $pg.user.existingSecret.name $pg.user.existingSecret.key)) -}}
      {{- fail "postgres requires user if not using urlOverride" -}}
    {{- end -}}
    {{- if not (or $pg.password.value (and $pg.password.existingSecret.name $pg.password.existingSecret.key)) -}}
      {{- fail "postgres requires password if not using urlOverride" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}
