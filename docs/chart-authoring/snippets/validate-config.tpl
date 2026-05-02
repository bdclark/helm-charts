{{/*
Optional pattern for chart-specific invariants.
Rename __CHART_NAME__ and replace the example logic.
*/}}
{{- define "__CHART_NAME__.validateConfig" -}}
{{- if and .Values.bootstrap.enabled (not .Values.persistence.config.enabled) -}}
{{- fail "bootstrap.enabled requires persistence.config.enabled to be true" -}}
{{- end -}}
{{- end -}}
