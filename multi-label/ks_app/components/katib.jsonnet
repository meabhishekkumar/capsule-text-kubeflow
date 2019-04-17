// @apiVersion 0.1
// @name io.ksonnet.pkg.katib-studyjob-test-v1alpha1
// @description katib-studyjob-test
// @shortDescription A Katib StudyJob using provided suggestion
// @param name string Name for the job.

local k = import "k.libsonnet";
local env = std.extVar("__ksonnet/environments");
local params = std.extVar("__ksonnet/params").components.katib;


local name = params.name;
local namespace = env.namespace;

local studyjob = {
  apiVersion: "kubeflow.org/v1alpha1",
  kind: "StudyJob",
  metadata: {
    name: name,
    namespace: namespace,
  },
  spec: {
    studyName: name,
    owner: "crd",
    optimizationtype: "maximize",
    objectivevaluename: "val-accuracy",
    optimizationgoal: 0.99,
    requestcount: 3,
    metricsnames: ["val-loss","exact-match-rate","precision","recall","f1-score"],
    parameterconfigs: [
      {
        name: "--tf-learning-rate",
        parametertype: "double",
        feasible: {
          min: "0.001",
          max: "0.003",
        },
      }
    //,
    //   {
    //     name: "--num-layers",
    //     parametertype: "int",
    //     feasible: {
    //       min: "2",
    //       max: "5",
    //     },
    //   },
    //   {
    //     name: "--optimizer",
    //     parametertype: "categorical",
    //     feasible: {
    //       list: ["sgd", "adam", "ftrl"],
    //     },
    //   },
    ],
    workerSpec: {
      goTemplate: {
        rawTemplate: |||
          apiVersion: batch/v1
          kind: Job
          metadata:
            name: {{.WorkerID}}
            namespace: {{.NameSpace}}
          spec:
            template:
              spec:
                containers:
                - name: {{.WorkerID}}
                  image: %s
                  command:
                  - "/usr/bin/python"
                  - "main.py"
                  - "--tf-model-type=%s"
                  - "--tf-num-epochs=%g"
                  {{- with .HyperParameters}}
                  {{- range .}}
                  - "{{.Name}}={{.Value}}"
                  {{- end}}
                  {{- end}}
                restartPolicy: Never
        ||| % [params.image, params.modelType, params.numEpochs],
      },
    },
    suggestionSpec: {
      suggestionAlgorithm: params.algorithm,
      requestNumber: 3,
    },
  },
};

k.core.v1.list.new([
  studyjob,
])
