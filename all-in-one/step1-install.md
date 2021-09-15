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
  
`curl https://raw.githubusercontent.com/llhuii/sedna/allinone-script/scripts/installation/minisedna.sh | NUM_EDGE_WORKERS=2 bash -
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

You also can enter into the edge nodes:
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


Check Sedna [examples](https://github.com/kubeedge/sedna/tree/main/examples).

TBD: Add more examples into katacoda courses.

