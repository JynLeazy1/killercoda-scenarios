#!/bin/bash
echo "Preparando el entorno (aplicaciones de ejemplo en el namespace 'apps')..."
until [ -f /tmp/.setup-done ]; do sleep 2; done
clear
echo "Entorno listo."
kubectl get deploy,svc,ingress -n apps
