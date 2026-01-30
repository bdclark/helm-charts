{{/*
Gluetun container
*/}}
{{- define "qbittorrent-vpn.qbittorrentInit" -}}
{{- $config := .Values.qbittorrent.config -}}
{{- $bootstrap := $config.bootstrap -}}
- name: qbittorrent-bootstrap
  image: busybox:1.36
  command: ["/bin/sh","-ec"]
  env:
    - name: CONFIG_DIR  # Directory where qBittorrent config file is located
      value: {{ $config.mountPath | quote }}
    - name: CONFIG_FILE  # Full path to qBittorrent config file
      value: {{ printf "%s/%s" $config.mountPath ($config.fileName | default "qBittorrent.conf") | quote }}
    - name: BOOTSTRAP_FILE  # Full path to initial bootstrap config file
      value: "/bootstrap/{{ $bootstrap.existingConfig.key | default "qBittorrent.conf" }}"
    - name: PASSWORD_MODE # How to handle setting the WebUI password ("disabled", "ifMissing", "overwrite")
      value: {{ $bootstrap.webuiPassword.mode | default "disabled" | quote }}
    {{- if not (eq $bootstrap.webuiPassword.mode "disabled") }}
    - name: PASSWORD_PBKDF2 # PBKDF2-hashed password for WebUI
      valueFrom:
        secretKeyRef:
          name: {{ $bootstrap.webuiPassword.existingSecret.name | quote }}
          key: {{ $bootstrap.webuiPassword.existingSecret.key | quote }}
    {{- end }}
  args:
    - |
      set -e
      umask 077
      mkdir -p "${CONFIG_DIR}"

      # Insert or update a key=value in a specified section of an INI file.
      # Handles the section being anywhere in the file, not just at the end.
      # Args: $1=config_file, $2=section, $3=key, $4=value, $5=mode (ifMissing|overwrite)
      update_section_key() {
        local config_file="$1"
        local section="$2"
        local key="$3"
        local value="$4"
        local mode="$5"
        local temp_file="${config_file}.tmp"

        # Escape backslashes and special chars for regex matching
        local escaped_key=$(printf '%s\n' "$key" | sed 's/[[\.*^$/]/\\&/g')

        # Check if key already exists anywhere in the file
        if grep -q "^${escaped_key}=" "$config_file"; then
          if [ "$mode" = "ifMissing" ]; then
            echo "${key} already present; leaving as-is"
            return 0
          fi
          # overwrite mode: replace the existing line
          AWK_KEY="$key" AWK_VALUE="$value" awk '
            BEGIN {
              key = ENVIRON["AWK_KEY"]
              value = ENVIRON["AWK_VALUE"]
            }
            {
              # Escape backslashes in key for regex
              escaped_key = key
              gsub(/\\/, "\\\\", escaped_key)
              regex = "^" escaped_key "="
              if ($0 ~ regex) {
                print key "=" value
              } else {
                print $0
              }
            }
          ' "$config_file" > "$temp_file"

          if [ ! -s "$temp_file" ]; then
            echo "Error: Generated empty config file during key replacement"
            rm -f "$temp_file"
            return 1
          fi

          mv "$temp_file" "$config_file"
          echo "${key} updated in config"
          return 0
        fi

        # Key doesn't exist, need to add it to the specified section
        AWK_SECTION="$section" AWK_KEY="$key" AWK_VALUE="$value" awk '
          BEGIN {
            section = ENVIRON["AWK_SECTION"]
            key = ENVIRON["AWK_KEY"]
            value = ENVIRON["AWK_VALUE"]
            section_header = "\\[" section "\\]"
            in_section = 0
            added = 0
            section_exists = 0
          }
          {
            # Check if we are entering the target section
            if ($0 ~ "^" section_header "$") {
              in_section = 1
              section_exists = 1
              print $0
              next
            }

            # Check if we are entering a different section
            if ($0 ~ /^\[.+\]/ && in_section && !added) {
              # We are leaving target section, add the key before the new section
              print key "=" value
              added = 1
              in_section = 0
            }

            print $0
          }
          END {
            # If we never found the section, add it at the end
            if (!section_exists) {
              print ""
              print "[" section "]"
              print key "=" value
            }
            # If target section was the last section, add the key at the end
            else if (in_section && !added) {
              print key "=" value
            }
          }
        ' "$config_file" > "$temp_file"

        if [ ! -s "$temp_file" ]; then
          echo "Error: Generated empty config file during key insertion"
          rm -f "$temp_file"
          return 1
        fi

        mv "$temp_file" "$config_file"
        echo "${key} added to [${section}] section"
        return 0
      }

      # Bootstrap initial config if needed
      if [ ! -f "${CONFIG_FILE}" ]; then
        if [ ! -f "${BOOTSTRAP_FILE}" ]; then
          echo "Error: Bootstrap file ${BOOTSTRAP_FILE} not found"
          exit 1
        fi
        echo "Seeding initial qBittorrent configuration..."
        cp "${BOOTSTRAP_FILE}" "${CONFIG_FILE}"
        chmod 600 "${CONFIG_FILE}"
      else
        echo "qBittorrent configuration file already exists; not overwriting."
      fi

      # Validate config file is readable
      if [ ! -r "${CONFIG_FILE}" ]; then
        echo "Error: Config file ${CONFIG_FILE} is not readable"
        exit 1
      fi

      ensure_password_provided() {
        if [ -z "${PASSWORD_PBKDF2:-}" ]; then
          echo "Warning: PASSWORD_MODE=${PASSWORD_MODE} but PASSWORD_PBKDF2 is not provided"
          exit 0
        fi
      }

      case "${PASSWORD_MODE}" in
        disabled)
          echo "Password management disabled."
          ;;
        ifMissing)
          ensure_password_provided
          echo "Setting password if missing..."
          update_section_key "$CONFIG_FILE" "Preferences" "WebUI\\Password_PBKDF2" "$PASSWORD_PBKDF2" "ifMissing"
          ;;
        overwrite)
          ensure_password_provided
          echo "Overwriting password..."
          update_section_key "$CONFIG_FILE" "Preferences" "WebUI\\Password_PBKDF2" "$PASSWORD_PBKDF2" "overwrite"
          ;;
        *)
          echo "Error: Unknown PASSWORD_MODE=${PASSWORD_MODE}; expected disabled|ifMissing|overwrite"
          exit 1
          ;;
      esac

      echo "Init script completed successfully"

  volumeMounts:
    - name: config
      mountPath: {{ $config.mountPath | quote }}
    - name: qbittorrent-bootstrap
      mountPath: /bootstrap
{{- end }}

{{- define "qbittorrent-vpn.getBootstrapVolume" -}}
{{- $existing := .Values.qbittorrent.config.bootstrap.existingConfig -}}
{{- if eq $existing.type "configMap" -}}
- name: qbittorrent-bootstrap
  configMap:
    name: {{ $existing.name | quote }}
{{- else if eq $existing.type "secret" -}}
- name: qbittorrent-bootstrap
  secret:
    secretName: {{ $existing.name | quote }}
{{- else -}}
- name: qbittorrent-bootstrap
  configMap:
    name: {{ include "qbittorrent-vpn.fullname" . }}-bootstrap
{{- end -}}
{{- end -}}
