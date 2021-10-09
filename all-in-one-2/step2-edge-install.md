Check Kubernetes environment:
  
`kubectl get node
`{{execute}}

You will see no kubectl command, and then no Kubernetes cluster.


Then you can run the command to get join environments:
  
`curl https://raw.githubusercontent.com/llhuii/sedna/allinone-script/scripts/installation/all-in-one.sh | bash -s join-env
`{{execute}}

Then run on the second machine to simulate two edge nodes:
`curl -O https://raw.githubusercontent.com/llhuii/sedna/allinone-script/scripts/installation/all-in-one.sh
`{{execute HOST2}}

`bash all-in-one.sh join
`{{execute HOST2}}

`kubectl get nodes`{{execute}}
  

You can also enter into the edge nodes:
```
enter edge0
docker ps

# check edgecore logs
# journalctl -u edgecore
```{{execute HOST2}}

And exit the shell by:
```
exit
```{{execute}}

You can check [the all-in-one doc](https://github.com/kubeedge/sedna/blob/main/docs/setup/all-in-one.md) for more advanced options.

