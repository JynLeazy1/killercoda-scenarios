#!/bin/bash
echo "Recreating the end state of Part 1 (NGINX Gateway Fabric, Gateway and routes)."
echo "This takes 1-3 minutes..."
until [ -f /tmp/.setup-done ]; do sleep 2; done
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "export NODE_IP=$NODE_IP" >> /root/.bashrc
clear
echo "Environment ready. NODE_IP=$NODE_IP"
kubectl get gateway -n infra
kubectl get httproute -n cafe
