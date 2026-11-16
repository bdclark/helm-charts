#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chart_dir="$(cd "$script_dir/.." && pwd)"

checksum() {
  local digest
  digest="$(helm template test "$chart_dir" --show-only templates/deployment.yaml "$@" |
    awk '$1 == "checksum/config:" { print $2 }')"
  if [[ ! "$digest" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'Expected exactly one SHA-256 config checksum; got: %s\n' "$digest" >&2
    return 1
  fi
  printf '%s\n' "$digest"
}

baseline="$(checksum)"

expect_same() {
  local scenario="$1"
  shift
  local actual
  actual="$(checksum "$@")"
  if [[ "$actual" != "$baseline" ]]; then
    printf '%s unexpectedly changed the config checksum\n' "$scenario" >&2
    return 1
  fi
  printf 'PASS: %s leaves config checksum unchanged\n' "$scenario"
}

expect_changed() {
  local scenario="$1"
  shift
  local actual
  actual="$(checksum "$@")"
  if [[ "$actual" == "$baseline" ]]; then
    printf '%s did not change the config checksum\n' "$scenario" >&2
    return 1
  fi
  printf 'PASS: %s changes config checksum\n' "$scenario"
}

expect_same 'Service annotation' --set-string service.annotations.review=test
expect_same 'Service type' --set-string service.type=LoadBalancer
expect_same 'Service port' --set service.ports.mqtt.port=1884

expect_changed 'Log level' --set-string config.logLevel=all
expect_changed 'WebSocket listener' --set service.ports.websocket.enabled=true
expect_changed 'ACLs' --set-string 'auth.acls=user alice'
expect_changed 'Inline users' --set-string 'auth.users[0].username=alice' --set-string 'auth.users[0].password=secret'
expect_changed 'Extra config' --set-string 'config.extraConfig=allow_zero_length_clientid true'
