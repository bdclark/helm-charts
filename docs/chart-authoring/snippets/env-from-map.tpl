{{/*
Rename __CHART_NAME__ before use.
Use when env is naturally modeled as a key/value map.
*/}}
{{- define "__CHART_NAME__.envFromMap" -}}
{{- $env := . | default (dict) -}}
{{- if not (kindIs "map" $env) -}}
{{- fail (printf ".env must be a map, got %s" (kindOf $env)) -}}
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
