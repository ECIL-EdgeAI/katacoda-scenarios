# Using Lifelong Learning Job in Thermal Comfort Prediction Scenario

This document introduces how to use lifelong learning job in thermal comfort prediction scenario.
Using the lifelong learning job, our application can automatically retrain, evaluate,
and update models based on the data generated at the edge.

##  Thermal Comfort Prediction Experiment

### Prepare Sedna

This experiment shows two nodes. name of the master node is `controlplane`, and name of the worker node is `node01`.
When two nodes show the message `Scenario ready. You have a running Sedna`, this means Sedna has been started.

Verify Sedna has been started, you can run:

`kubectl get deployments,pods,services -n sedna`{{execute}}

Optimally, the Pod status should say _Running_ in about ~15 seconds.

For more details, see [the installation doc](https://github.com/kubeedge/sedna/blob/main/docs/setup/install.md).

### Prepare Lifelong Learning Job

##### Set worker node
In this example, `$WORKER_NODE` is a custom node, you can fill it which you actually run.

```
WORKER_NODE="node01"
```{{execute}}

##### Set job output

```
mkdir /output/
```{{execute HOST2}}

##### Prepare Dataset
In this example, you can use [ASHRAE Global Thermal Comfort Database II](https://datadryad.org/stash/dataset/doi:10.6078/D1F671) to initial lifelong learning job.

We provide a well-processed [datasets](https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/atcii-classifier/dataset.tar.gz), including train (`trainData.csv`) and incremental (`trainData2.csv`) dataset.

```
mkdir /data
wget -P /data/ https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/atcii-classifier/dataset.tar.gz
tar -zxvf /data/dataset.tar.gz -C /data/
```{{execute HOST2}}

##### Create Dataset Resource Object

```
kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: Dataset
metadata:
  name: lifelong-dataset
spec:
  url: "/data/trainData.csv"
  format: "csv"
  nodeName: $WORKER_NODE
EOF
```{{execute}}

##### Create Lifelong Learning Job

```
IMAGE=jimmyyang20/sedna-example-lifelong-learning-atcii-classifier:v0.1.2

kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: LifelongLearningJob
metadata:
  name: atcii-classifier-demo
spec:
  dataset:
    name: "lifelong-dataset"
    trainProb: 0.8
  trainSpec:
    template:
      spec:
        nodeName: $WORKER_NODE
        containers:
          - image: $IMAGE
            name:  train-worker
            imagePullPolicy: IfNotPresent
            args: ["train.py"]  # training script
            env:  # Hyperparameters required for training
              - name: "early_stopping_rounds"
                value: "100"
              - name: "metric_name"
                value: "mlogloss"
    trigger:
      checkPeriodSeconds: 60
      timer:
        start: 01:00
        end: 23:00
      condition:
        operator: ">"
        threshold: 500
        metric: num_of_samples
  evalSpec:
    template:
      spec:
        nodeName: $WORKER_NODE
        containers:
          - image: $IMAGE
            name:  eval-worker
            imagePullPolicy: IfNotPresent
            args: ["eval.py"]
            env:
              - name: "metrics"
                value: "precision_score"
              - name: "metric_param"
                value: "{'average': 'micro'}"
              - name: "model_threshold"  # Threshold for filtering deploy models
                value: "0.5"
  deploySpec:
    template:
      spec:
        nodeName: $WORKER_NODE
        containers:
        - image: $IMAGE
          name:  infer-worker
          imagePullPolicy: IfNotPresent
          args: ["inference.py"]
          env:
          - name: "UT_SAVED_URL"  # unseen tasks save path
            value: "/ut_saved_url"
          - name: "infer_dataset_url"  # simulation of the inference samples 
            value: "/data/testData.csv"
          volumeMounts:
          - name: utdir
            mountPath: /ut_saved_url
          - name: inferdata
            mountPath: /data/
          resources:  # user defined resources
            limits:
              memory: 2Gi
        volumes:   # user defined volumes
          - name: utdir
            hostPath:
              path: /lifelong/unseen_task/
              type: DirectoryOrCreate
          - name: inferdata
            hostPath:
              path:  /data/
              type: Directory
  outputDir: "/output"
EOF
```{{execute}}

### Check Lifelong Learning Job
query the service status
```
kubectl get pods
```{{execute}}

```
kubectl get lifelonglearningjob atcii-classifier-demo -o yaml
```{{execute}}

In the `lifelonglearningjob` resource atcii-classifier-demo, the following trigger is configured:
```
trigger:
  checkPeriodSeconds: 60
  timer:
    start: 01:00
    end: 23:00
  condition:
    operator: ">"
    threshold: 500
    metric: num_of_samples
```

### Unseen Tasks samples Labeling
In a real word, we need to label the hard examples in our unseen tasks which storage in `UT_SAVED_URL`  with annotation tools and then put the examples to `Dataset`'s url.


### Effect Display
In this example, **false** and **failed** detections occur at stage of inference before lifelong learning.
After lifelong learning, the precision of the dataset have been improved by 5.12%.

![img_1.png](https://github.com/kubeedge/sedna/blob/main/examples/lifelong_learning/atcii/image/effect_comparison.png?raw=true) 
