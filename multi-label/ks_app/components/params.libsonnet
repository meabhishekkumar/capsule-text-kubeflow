{
  global: {
    // User-defined global parameters; accessible to all component and environments, Ex:
    // replicas: 4,
  },
  components: {
    // Component-level parameters, defined initially from 'ks prototype use ...'
    // Each object below should correspond to a component in the components/ directory
    train: {
      batchSize: 25,
      envVariables: 'GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/user-gcp-sa.json',
      learningRate: 0.001,
      image: '',
      modelType: 'capsule-A',
      name: 'capsnet-text-train',
      numPs: 0,
      numWorkers: 0,
      secret: '',
      secretKeyRefs: '',
      numEpochs: 20,
    },
    katib: {
      name: 'katib-capsnet-text',
      image: '',
      modelType: 'capsule-A',
      numEpochs: 10,
      algorithm : 'random', // you can try other values such as "grid" or "bayesianoptimization"
    },
  },
}
