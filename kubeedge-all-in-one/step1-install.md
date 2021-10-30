The all-in-one [Kubeedge](https://github.com/kubeedge/kubeedge) environment installs:
- A Kubernetes v1.21 cluster
- KubeEdge v1.8 with two edge nodes

It requires you:
- 2 CPUs or more
- 2GB free memory
- 10GB of free disk space
- Internet connection(docker hub, github etc.)
- Linux platform, such as ubuntu/centos
- Docker 17.06+

Check current OS release environment:
  
`lsb_release -a
`{{execute}}

Check Kubernetes environment:
  
`kubectl get node
`{{execute}}

You will see no kubectl command, and then no Kubernetes cluster.


Then you can run the all-in-on script:
  
```
curl https://raw.githubusercontent.com/kubeedge/sedna/main/scripts/installation/all-in-one.sh |
# comment sedna installation for kubeedge POC
NUM_EDGE_NODES=2 NO_INSTALL_SEDNA=y bash -
```{{execute}}

To verify the Kubernetes cluster has been created, you can run:

`kubectl get nodes`{{execute}}
  

You can enter k8s master node to debug it:
```
enter
docker ps
```{{execute}}

And exit the master shell by:
```
exit
```{{execute}}

You can also enter into the edge nodes:
```
enter edge0
docker ps

# see the edgecore status
systemctl status edgecore

# uncomment and check edgecore logs
# journalctl -u edgecore
```{{execute}}

And exit the shell by:
```
exit
```{{execute}}

You can check [the all-in-one doc](https://github.com/kubeedge/sedna/blob/main/docs/setup/all-in-one.md) for more advanced options.

