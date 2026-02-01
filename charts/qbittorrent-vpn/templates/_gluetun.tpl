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
  {{- if or $ctx.ports $ctx.service.enabled }}
  ports:
    {{- with $ctx.ports }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- if $ctx.service.enabled }}
    - name: control
      containerPort: {{ $ctx.service.port }}
      protocol: TCP
    {{- end }}
  {{- end }}
  {{- with $ctx.startupProbe }}
  startupProbe:
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
  {{- if or $ctx.needsTunDevice $ctx.persistence.enabled $ctx.controlServer.enabled $ctx.volumeMounts }}
  volumeMounts:
  {{- if $ctx.needsTunDevice }}
    - name: tun
      mountPath: /dev/net/tun
  {{- end }}
  {{- if $ctx.persistence.enabled }}
    - name: gluetun
      mountPath: /gluetun
  {{- end }}
  {{- if $ctx.controlServer.enabled }}
    - name: gluetun-control-auth
      mountPath: {{ $ctx.controlServer.mountPath }}/{{ $ctx.controlServer.fileName }}
      subPath: {{ $ctx.controlServer.fileName }}
      readOnly: true
  {{- end }}
  {{- with $ctx.volumeMounts }}
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
{{- end }}
