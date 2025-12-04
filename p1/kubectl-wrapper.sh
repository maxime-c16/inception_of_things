#!/bin/bash
# Wrapper script for kubectl with K3s cluster access
cd /home/macauchy/inception_of_things/p1
exec kubectl --kubeconfig=k3s.yaml --insecure-skip-tls-verify "$@"
