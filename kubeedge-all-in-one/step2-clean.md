To clean all-in-one KubeEdge, you can run:
```
curl https://raw.githubusercontent.com/kubeedge/sedna/main/scripts/installation/all-in-one.sh | bash /dev/stdin clean
```{{execute}}

To verify it has been uninstalled successfully, you can run:
`kubectl get nodes`{{execute}}

It would report like this:
```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

