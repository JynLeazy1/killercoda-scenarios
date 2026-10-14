#!/bin/bash
echo "Preparing the environment (sample apps in the 'cafe' namespace)..."
until [ -f /tmp/.setup-done ]; do sleep 2; done
export NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "export NODE_IP=$NODE_IP" >> /root/.bashrc
clear
echo "Environment ready. NODE_IP=$NODE_IP"
kubectl get pods -n cafe
