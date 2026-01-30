{{/*
Gluetun container
*/}}
{{- define "qbittorrent-vpn.gluetunContainer" -}}
{{- $ctx := . -}}
- name: gluetun
  image: "{{ $ctx.image.repository }}:{{ $ctx.image.tag }}"
  imagePullPolicy: {{ $ctx.image.pullPolicy }}
  restartPolicy: Always
  {{- with $ctx.lifecycleHooks }}
  lifecycle:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ctx.securityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ctx.env }}
  env:
    {{- include "qbittorrent-vpn.envFromMap" . | trim | nindent 4 }}
  {{- end }}
  {{- with $ctx.envFrom }}
  envFrom:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ctx.ports }}
  ports:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ctx.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ctx.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $ctx.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if or $ctx.needsTunDevice $ctx.persistence.enabled $ctx.volumeMounts }}
  volumeMounts:
  {{- if $ctx.needsTunDevice }}
    - name: tun
      mountPath: /dev/net/tun
  {{- end }}
  {{- if $ctx.persistence.enabled }}
    - name: gluetun
      mountPath: /gluetun
  {{- end }}
  {{- with $ctx.volumeMounts }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end }}
