#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="devops-challenge"
RELEASE="hello-candidate"
CONTAINER_NAME="hello-candidate"
SERVICE_NAME="${RELEASE}-${RELEASE}"

echo "==> Checking pod UID (should not be root)"
POD_NAME="$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/instance="${RELEASE}" -o jsonpath='{.items[0].metadata.name}')"
kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- id

echo "==> Checking container listening ports"
if kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- sh -c "command -v ss >/dev/null 2>&1"; then
  kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- ss -tulnp
elif kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- sh -c "command -v netstat >/dev/null 2>&1"; then
  kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- netstat -tulnp
else
  echo "ss/netstat not available, inspecting /proc/net/tcp"
  kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- python - <<'PY'
import pathlib

def show_listeners(path):
    try:
        with open(path) as fh:
            next(fh)
            found = False
            for line in fh:
                local = line.split()[1]
                _, port_hex = local.split(':')
                port = int(port_hex, 16)
                if port == 80:
                    print(f"Listener on port 80 found via {path}: {line.strip()}")
                    found = True
            if not found:
                print(f"No port 80 listener found in {path}")
    except FileNotFoundError:
        pass

show_listeners("/proc/net/tcp")
show_listeners("/proc/net/tcp6")
PY
fi

echo "==> Port-forwarding service ${SERVICE_NAME} to localhost:8080"
kubectl port-forward -n "${NAMESPACE}" svc/"${SERVICE_NAME}" 8080:80 >/tmp/port-forward.log 2>&1 &
PF_PID=$!
sleep 3

cleanup() {
  kill "${PF_PID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Curling service and validating response"
RESPONSE="$(curl -s http://127.0.0.1:8080/ || true)"
echo "Response: ${RESPONSE}"

if command -v jq >/dev/null 2>&1; then
  echo "${RESPONSE}" | jq '.message' >/dev/null
  echo "${RESPONSE}" | jq '.version' >/dev/null
else
  echo "jq not found locally; validating via POSIX tools"
  MESSAGE=$(echo "${RESPONSE}" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
  VERSION=$(echo "${RESPONSE}" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
  if [ "${MESSAGE}" != "Hello, Candidate" ] || [ "${VERSION}" != "1.0.0" ]; then
    echo "Unexpected JSON payload"
    exit 1
  fi
  echo "JSON payload validated via shell utilities"
fi

echo "System check complete."

