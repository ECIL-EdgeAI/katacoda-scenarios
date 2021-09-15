# Using Joint Inference Service in Helmet Detection Scenario

This case introduces how to use joint inference service in helmet detection scenario.
In the safety helmet detection scenario, the helmet detection shows lower performance due to limited resources in edge.
However, the joint inference service can improve overall performance, which uploads hard examples that identified by the hard example mining algorithm to the cloud and infers them.
The data used in the experiment is a video of workers wearing safety helmets.
The joint inference service requires to detect the wearing of safety helmets in the video.

### Prepare Sedna

Verify Sedna has been started, you can run:

`kubectl get deployments,pods,services -n sedna`{{execute}}

Optimally, the Pod status should say _Running_ in about ~15 seconds.

For more details, see [the installation doc](https://github.com/kubeedge/sedna/blob/main/docs/setup/install.md).

### Prepare Data and Model

Step1: download [little model](https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection-inference/little-model.tar.gz) to your edge node.

```
mkdir -p /data/little-model
cd /data/little-model
wget https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection-inference/little-model.tar.gz
tar -zxvf little-model.tar.gz
```{{execute}}

Step2: download [big model](https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection-inference/big-model.tar.gz) to your cloud node.

```
mkdir -p /data/big-model
cd /data/big-model
wget https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection-inference/big-model.tar.gz
tar -zxvf big-model.tar.gz
```{{execute HOST2}}

### Create Joint Inference Service

#### Create Big Model Resource Object for Cloud

```
kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind:  Model
metadata:
  name: helmet-detection-inference-big-model
  namespace: default
spec:
  url: "/data/big-model/yolov3_darknet.pb"
  format: "pb"
EOF
```{{execute}}

#### Create Little Model Resource Object for Edge

```
kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: Model
metadata:
  name: helmet-detection-inference-little-model
  namespace: default
spec:
  url: "/data/little-model/yolov3_resnet18.pb"
  format: "pb"
EOF
```{{execute}}

#### Create Joint Inference Service

Note the setting of the following parameters, which have to same as the script [little_model.py](https://raw.githubusercontent.com/kubeedge/sedna/main/examples/joint_inference/helmet_detection_inference/little_model/little_model.py):
- hardExampleMining: set hard example algorithm from {IBT, CrossEntropy} for inferring in edge side.
- video_url: set the url for video streaming.
- all_examples_inference_output: set your output path for the inference results.
- hard_example_edge_inference_output: set your output path for results of inferring hard examples in edge side.
- hard_example_cloud_inference_output: set your output path for results of inferring hard examples in cloud side.
  
Create joint inference service
```
CLOUD_NODE="node01"
EDGE_NODE=$HOSTNAME


kubectl create -f - <<EOF
apiVersion: sedna.io/v1alpha1
kind: JointInferenceService
metadata:
  name: helmet-detection-inference-example
  namespace: default
spec:
  edgeWorker:
    model:
      name: "helmet-detection-inference-little-model"
    hardExampleMining:
      name: "IBT"
      parameters:
        - key: "threshold_img"
          value: "0.9"
        - key: "threshold_box"
          value: "0.9"
    template:
      spec:
        nodeName: $EDGE_NODE
        containers:
        - image: kubeedge/sedna-example-joint-inference-helmet-detection-little:v0.3.1
          imagePullPolicy: IfNotPresent
          name:  little-model
          env:  # user defined environments
          - name: input_shape
            value: "416,736"
          - name: "video_url"
            value: "file://data/video/video.mp4"
          - name: "all_examples_inference_output"
            value: "/data/output"
          - name: "hard_example_cloud_inference_output"
            value: "/data/hard_example_cloud_inference_output"
          - name: "hard_example_edge_inference_output"
            value: "/data/hard_example_edge_inference_output"
          resources:  # user defined resources
            requests:
              memory: 64M
              cpu: 100m
            limits:
              memory: 2Gi
          volumeMounts:
            - name: outputdir
              mountPath: /data/
        volumes:   # user defined volumes
          - name: outputdir
            hostPath:
              # user must create the directory in host
              path: /joint_inference
              type: DirectoryOrCreate

  cloudWorker:
    model:
      name: "helmet-detection-inference-big-model"
    template:
      spec:
        nodeName: $CLOUD_NODE
        containers:
          - image: kubeedge/sedna-example-joint-inference-helmet-detection-big:v0.3.1
            name:  big-model
            imagePullPolicy: IfNotPresent
            env:  # user defined environments
              - name: "input_shape"
                value: "544,544"
            resources:  # user defined resources
              requests:
                memory: 2Gi
EOF
```{{execute}}

### Check Joint Inference Status

```
kubectl get pods
kubectl get jointinferenceservices.sedna.io
```{{execute}}

### Mock Video Stream for Inference in Edge Side

Download [video](https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection/video.tar.gz), unzip video.tar.gz, and put it into `/joint_inference/video/`.

```
mkdir -p /joint_inference/video/
cd /joint_inference/video/
wget https://kubeedge.obs.cn-north-1.myhuaweicloud.com/examples/helmet-detection/video.tar.gz
tar -zxvf video.tar.gz
```{{execute}}

### Check Inference Result

You can check the inference results in the output path (e.g. `/joint_inference/output`) defined in the JointInferenceService config.
```
cd /joint_inference
tree
```{{execute}}

* the result of edge inference vs the result of joint inference
  ![](https://github.com/kubeedge/sedna/blob/main/examples/joint_inference/helmet_detection_inference/images/inference-result.png?raw=true)
