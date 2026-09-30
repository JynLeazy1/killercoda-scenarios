#!/bin/bash
# Deploy the sample apps while the learner reads the intro.
until kubectl get nodes >/dev/null 2>&1; do sleep 2; done
kubectl apply -f /root/assets/apps.yaml
kubectl wait -n cafe --for=condition=Available deployment --all --timeout=300s
touch /tmp/.setup-done
