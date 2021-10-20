# Using Incremental Learning Job in Helmet Detection Scenario

This document introduces how to use incremental learning job in helmet detection scenario.
Using the incremental learning job, our application can automatically retrains, evaluates,
and updates models based on the data generated at the edge.

## Helmet Detection Experiment

### Prepare Sedna

This experiment shows two nodes. name of the master node is `controlplane`, and name of the worker node is `node01`.
When two nodes show the message `Scenario ready. You have a running Sedna`, this means Sedna has been started.

Verify Sedna has been started, you can run:

`kubectl get deployments,pods,services -n sedna`{{execute}}

Optimally, the Pod status should say _Running_ in about ~15 seconds.

For more details, see [the installation doc](https://github.com/kubeedge/sedna/blob/main/docs/setup/install.md).

### Prepare Incremental Learning Job
In this example, we simulate a inference worker for helmet detection, the worker will upload hard examples to `HE_SAVED_URL`, while
it inferences data from local video. We need to make following preparations:

##### Set worker node
In this example, `$WORKER_NODE` is a custom node, you can fill it which you actually run.

```
WORKER_NODE="node01"
```{{execute}}

##### Set job output

```
mkdir /output/
```{{execute HOST2}}

##### Prepare Model 
In this example, we need to prepare base model and deploy model in advance.

```
cd /
wget https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection/models.tar.gz
tar -zxvf models.tar.gz
```{{execute HOST2}}

##### Prepare video data for the inference worker
```
mkdir -p /incremental_learning/video/
wget -P /incremental_learning/video/ https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection/video.tar.gz
tar -zxvf /incremental_learning/video/video.tar.gz -C /incremental_learning/video/
```{{execute HOST2}}

##### Prepare helmet detection data with labels for the train/eval worker

```
mkdir -p /data/helmet_detection
wget  -P /data/helmet_detection https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection/dataset.tar.gz
tar -zxvf /data/helmet_detection/dataset.tar.gz -C /data/helmet_detection/
```{{execute HOST2}}

##### Create Dataset Resource Object

```
kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: Dataset
metadata:
  name: incremental-dataset
spec:
  url: "/data/helmet_detection/train_data/train_data.txt"
  format: "txt"
  nodeName: $WORKER_NODE
EOF
```{{execute}}

##### Create Initial Model Resource Object

```
kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: Model
metadata:
  name: initial-model
spec:
  url : "/models/base_model"
  format: "ckpt"
EOF
```{{execute}}

##### Create Deploy Model Resource Object

```
kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: Model
metadata:
  name: deploy-model
spec:
  url : "/models/deploy_model/saved_model.pb"
  format: "pb"
EOF
```{{execute}}

##### Create Incremental Learning Job

```
IMAGE=jimmyyang20/sedna-example-incremental-learning-helmet-detection:v0.1.2

kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: IncrementalLearningJob
metadata:
  name: helmet-detection-demo
spec:
  initialModel:
    name: "initial-model"
  dataset:
    name: "incremental-dataset"
    trainProb: 0.8
  trainSpec:
    template:
      spec:
        nodeName: $WORKER_NODE
        containers:
          - image: $IMAGE
            name:  train-worker
            imagePullPolicy: IfNotPresent
            args: ["train.py"]
            env:
              - name: "batch_size"
                value: "8"
              - name: "epochs"
                value: "1"
              - name: "input_shape"
                value: "352,640"
              - name: "class_names"
                value: "person,helmet,helmet-on,helmet-off"
              - name: "nms_threshold"
                value: "0.4"
              - name: "obj_threshold"
                value: "0.3"
    trigger:
      checkPeriodSeconds: 60
      timer:
        start: 01:00
        end: 23:00
      condition:
        operator: ">"
        threshold: 50
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
              - name: "input_shape"
                value: "352,640"
              - name: "class_names"
                value: "person,helmet,helmet-on,helmet-off"                    
  deploySpec:
    model:
      name: "deploy-model"
      hotUpdateEnabled: true
      pollPeriodSeconds: 60 
    trigger:
      condition:
        operator: ">="
        threshold: 0
        metric: precision[2] # helmet-on precision
    hardExampleMining:
      name: "IBT"
      parameters:
        - key: "threshold_img"
          value: "0.9"
        - key: "threshold_box"
          value: "0.9"
    template:
      spec:
        nodeName: $WORKER_NODE
        containers:
        - image: $IMAGE
          name:  infer-worker
          imagePullPolicy: IfNotPresent
          args: ["inference.py"]
          env:
            - name: "input_shape"
              value: "352,640"
            - name: "video_url"
              value: "file://video/video.mp4"
            - name: "HE_SAVED_URL" 
              value: "/he_saved_url"
          volumeMounts:
          - name: localvideo
            mountPath: /video/
          - name: hedir
            mountPath: /he_saved_url
          resources:  # user defined resources
            limits:
              memory: 2Gi
        volumes:   # user defined volumes
          - name: localvideo
            hostPath:
              path: /incremental_learning/video/
              type: Directory
          - name: hedir
            hostPath:
              path:  /incremental_learning/he/
              type: DirectoryOrCreate
  outputDir: "/output"
EOF
```{{execute}}


##### Check Incremental Learning Job
Query the service status:

```
kubectl get pods
```{{execute}}

```
kubectl get incrementallearningjob helmet-detection-demo -o yaml
```{{execute}}

### Job triggers
In the `IncrementalLearningJob` resource helmet-detection-demo, the following training trigger is configured:

```
trigger:
  checkPeriodSeconds: 60
  timer:
    start: 01:00
    end: 23:00
  condition:
    operator: ">"
    threshold: 100
    metric: num_of_samples
```

The LocalController component will check the number of the sample, realize trigger conditions are met and notice the GlobalManager Component to start train worker.
When the train worker finish, we can view the updated model in the `/output` directory in `$WORKER_NODE` node.
Then the eval worker will start to evaluate the model that train worker generated.

If the eval result satisfy the `deploySpec`'s trigger
```
trigger:
  condition:
    operator: ">"
    threshold: 0.01
    metric: # helmet-on precision
```
the deploy worker will load the new model and provide service.

### Effect Display
In this example, false and failed detections occur at stage of inference before incremental learning, after incremental learning,
all targets are correctly detected.

![img_1.png](https://github.com/kubeedge/sedna/blob/main/examples/incremental_learning/helmet_detection/image/effect_comparison.png?raw=true) 
