#!/bin/bash

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

cat >> ~/.bashrc <<'EOF'
alias k=kubectl
function exec-in-node() {
  local node=${1:-sedna-mini-control-plane}
  node=sedna-mini-${node/sedna-mini-}
  shift 1
  docker exec -it --detach-keys ctrl-@ $node "$@"
}

function enter() {
  exec-in-node ${1:-control-plane} bash
}

EOF

source ~/.bashrc

echo "done" >> /opt/.backgroundfinished
