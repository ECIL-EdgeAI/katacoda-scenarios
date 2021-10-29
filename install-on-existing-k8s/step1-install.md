For this scenario, Katacoda has just started a fresh Kubernetes cluster for you. 

Verify that it's ready for your use:
```
launch.sh
kubectl version --short && \
kubectl get nodes && \
kubectl get componentstatus && \
kubectl cluster-info
```{{execute}}

It should list a 2-node cluster and the control plane components should be reporting _Healthy_. If it's not healthy, try again in a few moments. If it's still not functioning refresh the browser tab to start a fresh scenario instance before proceeding.

Install Sedna control components in one command, you can run:
  
`curl https://raw.githubusercontent.com/kubeedge/sedna/main/scripts/installation/install.sh | SEDNA_ACTION=create bash -`{{execute}}

Verify Sedna has been started, you can run:
  
`kubectl get deployments,pods,services -n sedna`{{execute}}

Optimally, the Pod status should say _Running_ in about ~15 seconds.

For more details, see [the installation doc](https://github.com/kubeedge/sedna/blob/main/docs/setup/install.md).
