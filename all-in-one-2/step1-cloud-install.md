This all-in-one [Sedna](https://github.com/kubeedge/sedna) scenario installs components on two machines:
- A machine named `cloud`: a Kubernetes v1.21 cluster, KubeEdge v1.8.0 CloudCore installed
- A machine named `edge`: two virutal KubeEdge nodes

It requires you having two machines with below requirements:
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


Then you can run the all-in-on script to install the cloud part components:
  
`curl https://raw.githubusercontent.com/llhuii/sedna/allinone-script/scripts/installation/all-in-one.sh | NUM_EDGE_NODES=0 bash -
`{{execute}}

To verify the Kubernetes cluster has been created, you can run:

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

