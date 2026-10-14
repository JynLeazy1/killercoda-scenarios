#!/bin/bash
echo "Recreating the end state of Part 1 (Envoy Gateway, Gateway and routes)."
echo "This takes 1-3 minutes..."
until [ -f /tmp/.setup-done ]; do sleep 2; done
clear
echo "Environment ready."
kubectl get gateway,httproute -n apps
