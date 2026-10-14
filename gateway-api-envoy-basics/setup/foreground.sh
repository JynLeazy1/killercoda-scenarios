#!/bin/bash
echo "Preparing the environment (sample apps in the 'apps' namespace)..."
until [ -f /tmp/.setup-done ]; do sleep 2; done
clear
echo "Environment ready."
kubectl get deploy,svc,ingress -n apps
