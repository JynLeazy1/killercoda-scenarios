#!/bin/bash
echo "Preparando el entorno (aplicaciones de ejemplo en el namespace 'cafe')..."
until [ -f /tmp/.setup-done ]; do sleep 2; done
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "export NODE_IP=$NODE_IP" >> /root/.bashrc
clear
echo "Entorno listo. NODE_IP=$NODE_IP"
kubectl get pods -n cafe
