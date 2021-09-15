#!/bin/bash

launch.sh

# Log script activity (https://serverfault.com/a/103569)
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/init-background.log 2>&1
set -x

# Common curl switches (however, use `lynx url --dump` when you can)
echo '-s' >> ~/.curlrc

# Allow pygmentize for source highlighting of source files (YAML, Dockerfile, Java, etc)
# Preload docker image to make ccat hot
docker run whalebrew/pygmentize:2.6.1 &
echo 'function ccat() { docker run -it -v "$(pwd)":/workdir -w /workdir whalebrew/pygmentize:2.6.1 $@; }' >> ~/.bashrc
source ~/.bashrc

# Katacoda Cloud Provider is used when a LoadBalancer service is requested
# by Kubernetes, Katacoda will respond with the IP of the master. This is
# how Istio and other LoadBalancer based services can be deployed.
kubectl delete -f /opt/katacoda-cloud-provider.yaml &

# To remove the taint added of master node
kubectl get node $HOSTNAME -o yaml | grep master

kubectl taint node $HOSTNAME node-role.kubernetes.io/master-

# Install Sedna control components in one command, you can run:
curl https://raw.githubusercontent.com/kubeedge/sedna/main/scripts/installation/install.sh | SEDNA_GM_NODE=$HOSTNAME SEDNA_ACTION=create bash -x /dev/stdin

kubectl -n sedna wait pod --for=condition=ready --selector=sedna

echo "done" >> /opt/.backgroundfinished