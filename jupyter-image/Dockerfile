FROM gcr.io/kubeflow-images-public/tensorflow-1.13.1-notebook-gpu:v0.5.0

# setting up the PATH for nvidia drivers
ENV PATH="/usr/local/nvidia/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/nvidia/lib64"

# installing conda version 

RUN conda install -y tensorflow-gpu==1.13.1

ENV NB_PREFIX /
CMD ["sh","-c", "jupyter notebook --notebook-dir=/home/jovyan --ip=0.0.0.0 --no-browser --allow-root --port=8888 --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.allow_origin='*' --NotebookApp.base_url=${NB_PREFIX}"]
