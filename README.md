
## Capsule Networks (for Text) on Kubeflow 

Presented at O'Reilly Artificial Intelligence Conference **"Industrialized capsule networks for text analytics"** [https://conferences.oreilly.com/artificial-intelligence/ai-ny/public/schedule/detail/73606]


**Highlights of the session :**

- Overview of Capsule Networks ( What and Why )
- Capsule Networks for text classification 
- How to leverage Kubeflow for Industrialization 
    - Setup Kubeflow on GCP with Multi GPU Support enabled
    - Use Tensorflow to create CaspNet Estimator [ from Tensorflow Keras Model to Tensorflow Estimator ]
    - Distributed Multi-GPU training of CapsNet [ using Tensorflow MirroredStrategy ]
    - Use TF-Job for distributed training on K8S cluster [ for Single-Class & Multi-Class Classification with Multiple Neural Network Architectures ]
    - Use Katib for highly scalable hyper-parameter tuning [ with Random Search, Grid Search and Bayesian Search for hyper-parameters]
- Challenges and Future Work

#### References and Credits 

We would like to acknowledge the work done by researchers and community in this field. 

**Research Papers**

- [Text Classification Using Capsules](https://arxiv.org/pdf/1808.03976.pdf)
- [Investigating Capsule Networks with Dynamic Routing for Text Classification](https://arxiv.org/pdf/1804.00538.pdf)

**Github Repos**

We have modified and adapted from following implementation and focused more on **Kubeflow** implementation for scalibility and performance. 

- [Capsnet with Pure Keras](https://github.com/bojone/Capsule/)
- [Capsnet for NLP with Keras](https://github.com/stefan-it/capsnet-nlp)
- [Capsule Text Classification](https://github.com/andyweizhao/capsule_text_classification)


## Step-By-Step Guide for Running CapsNet on Kubeflow

### 1. Get the Code 

1. Clone the github repo

```
git clone https://github.com/meabhishekkumar/capsule-text-kubeflow

```
2. navigate to code directory 

```
cd capsule-text-kubeflow
```

### 2. Setup Kubeflow in GCP 

1. Make sure you have gcloud SDK is installed and pointing to the right **GCP PROJECT**. You can use `gcloud init` to perform this action. 

2. Setup environment variables 

``` bash 
export DEPLOYMENT_NAME=<CHOOSE_ANY_DEPLOYMENT_NAME>
export PROJECT_ID=<YOUR_GCP_PROJECT_ID>
export ZONE=<YOUR_GCP_ZONE>
gcloud config set project ${PROJECT_ID}
gcloud config set compute/zone ${ZONE}
```

3. Use one-click deploy interface by GCP to setup kubeflow using https://deploy.kubeflow.cloud/#/ . For more details you can refer to official documentation[https://www.kubeflow.org/docs/gke/deploy/deploy-ui/]. 

one the deployment is completed. You can connect to the cluster. 

4. Connecting to the cluster 

``` bash
gcloud container clusters get-credentials ${DEPLOYMENT_NAME} \
  --project ${PROJECT_ID} \
  --zone ${ZONE}
```

Set context

```
kubectl config set-context $(kubectl config current-context) --namespace=kubeflow
kubectl get all
```


### 3. Experiments in Jupyter Notebook ( with Multiple GPUs)

1. If you want to use GPUs for your training process. You can add GPU backed Node pool in the Kubernetes Cluster. 

```
gcloud container node-pools create accel \
  --project ${PROJECT_ID} \
  --zone ${ZONE} \
  --cluster ${DEPLOYMENT_NAME} \
  --accelerator type=nvidia-tesla-k80,count=1 \
  --num-nodes 1 \
  --machine-type n1-highmem-8 \
  --disk-size=220 \
  --scopes cloud-platform \
  --verbosity error
```

2. You can then install required Nvidia Drivers to utilize the GPUs. 

```
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/stable/nvidia-driver-installer/cos/daemonset-preloaded.yaml
```

3. You can then Open the Ambassador Interface by navigating to your GCP console. Kubernetes Engine -> Services -> Ambassador -> Click on "Port Forwarding". Follow the instruction to open the Ambassador image. 


4. Build custom image for tensorflow with all GPU driver configuration ( setting `LB_LIBRARY_PATH` and installing `CUDATOOLKIT` & `CUDNN`).

```
//allow docker to access our GCR registry
gcloud auth configure-docker --quiet

cd jupyter-image && make build PROJECT_ID=$PROJECT_ID && cd ..
cd jupyter-image && make push PROJECT_ID=$PROJECT_ID && cd ..

```
5. Use **Notebooks** in **Ambassador UI** for running your experiments. Select custom image and set the image name that you just created. You can set the resources and GPUs. 

6. Upload the notebook available `capsnet-text-classification.ipynb` in **notebooks** subfolder inside the code directory.

### 4. Setting up Kustomize for Kubeflow

1. Install Kustomize

Set current working directory 

```
cd multi-label
WORKING_DIR=$(pwd)

```

```
// download kustomize for linux (including Cloud Shell)
// for macOS, use kustomize_2.0.3_darwin_amd64  for Linux use : kustomize_2.0.3_linux_amd64 
KS_VER=kustomize_2.0.3_darwin_amd64

//download tar of ksonnet
wget --no-check-certificate \
    https://github.com/kubernetes-sigs/kustomize/releases/download/v2.0.3/$KS_VER

mv kustomize_2.0.3_darwin_amd64 kustomize
//add ks command to path
PATH=$PATH:$(pwd)/$KS_VER
chmod +x kustomize
export PATH=${PATH}:$(pwd)


```

### 5. Build Train Image 

1. Build Image

```
cd $WORKDIR/train-image/
// sample : capsnet-kubeflow:v1
export TRAIN_IMAGE_NAME=<YOUR_TRAIN_IMAGE_NAME>
//set the path on GCR you want to push the image to
export TRAIN_PATH=gcr.io/$PROJECT_ID/$TRAIN_IMAGE_NAME

//build the tensorflow model into a container
//container is tagged with its eventual path on GCR, but it stays local for now
docker build $WORKING_DIR/train -t $TRAIN_PATH -f $WORKING_DIR/train/Dockerfile.model
```
2. Check locally

```
docker run -it $TRAIN_PATH
```

3. Push Docker image to GCR

```
//allow docker to access our GCR registry
gcloud auth configure-docker --quiet

//push container to GCR
docker push $TRAIN_PATH
```

### 6. Training on Kubeflow 

1. check service account access 
```
gcloud --project=$PROJECT_ID iam service-accounts list | grep $DEPLOYMENT_NAME
```

2. check kubernetes secrets

```
kubectl describe secret user-gcp-sa
```


4. Train on the cluster

For **capsule A**, set the modelType to **"capsule-A"** , for **capusle-B** set the **modelType** to **"capsule-B"** and change the **name** accordingly.

```
// set the parameters for this job : CNN
kustomize edit add configmap capsule-map-training --from-literal=modelType=CNN
kustomize edit add configmap capsule-map-training --from-literal=name=train-capsnet-text-CNN-1
kustomize edit set image training-image=$TRAIN_PATH
kustomize edit add configmap capsule-map-training --from-literal=learningRate=0.0005
kustomize edit add configmap capsule-map-training --from-literal=batchSize=25
kustomize edit add configmap capsule-map-training --from-literal=numEpochs=5
```

3. Set Google Application Credentials 

```
// set credentials
kustomize edit add configmap capsule-map-training --from-literal=secretName=user-gcp-sa
kustomize edit add configmap capsule-map-training --from-literal=secretMountPath=/var/secrets
kustomize edit add configmap capsule-map-training --from-literal=GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/user-gcp-sa.json
```
4. Train at Scale 
```
kustomize build . |kubectl apply -f -
kubectl describe tfjob
kubectl logs -f train-capsnet-text-CNN-1-chief-0
```


### 7. Hyper-Parameter Tuning using Katib 

We will be using [Katib](https://www.kubeflow.org/docs/components/hyperparameter/) for hyper-parameter tuning.

```

```
