The all-in-one [Sedna](https://github.com/kubeedge/sedna) environment installs:
- A Kubernetes v1.21 cluster
- KubeEdge v1.8 with two edge nodes

It requires you:
- 2 CPUs or more
- 2GB free memory
- 10GB of free disk space
- Internet connection(docker hub, github etc.)
- Linux platform, such as ubuntu/centos
- Docker 17.06+

You can run:
  
`curl https://raw.githubusercontent.com/kubeedge/sedna/main/scripts/installation/all-in-one.sh | NUM_EDGE_NODES=2 bash -
`{{execute}}

To verify the k8s cluster has been created, you can run:

`kubectl get nodes`{{execute}}
  
And check Sedna's control components, you can run:
`kubectl get deployments,pods,services -n sedna`{{execute}}

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

# check edgecore logs
# journalctl -u edgecore
```{{execute}}

And exit the shell by:
```
exit
```{{execute}}


Check [All-In-One doc](https://github.com/kubeedge/sedna/blob/main/docs/setup/all-in-one.md) for more advanced options.

Check [this](https://www.katacoda.com/kubeedge-sedna) for more Sedna scenarios.
