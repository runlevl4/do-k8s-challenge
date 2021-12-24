# 2021 Digital Ocean Kubernetes Challenge

## Background

This repo represents my project for the 2021 [Kubernetes Challenge](https://www.digitalocean.com/community/pages/kubernetes-challenge) from Digital Ocean. For the challenge, I have decided to tackle deploying [Kyverno](https://github.com/kyverno/kyverno) to explore its open policy management.

Compliance and governance is something that I've been planning on POCing and exploring for work, so this is a great opportunity to dig in a little while I'm on vacation. ;-)

## Cluster

Thanks to the generous $120 promo credit issued by DO, I have decided to setup a 4-node cluster. This should give me some additional flexibility in determing where resources get deployed, etc. I figured you can always use more nodes, so I might as well take advantage of it.

### Makeup

- Kubernetes 1.21.5
- New York 3 datacenter

## Getting Started

Once my cluster was created, I downloaded the provided `kubectl` config file. I didn't want to mess with my existing config, so I decided to just alias a new command.

`alias kdo='kubectl --kubeconfig="k8s-challenge-kubeconfig.yaml" '`

Now I can run all of my commands with `kdo` instead of my normal `k` alias.

### Intallying Kyverno

I decided to simply things so I'm setting everyihng up with a makefile. I created a target to deploy Kyverno and it installed without a hitch.

```
make deploy-kyverno                                                                                                                                                            2 ✘
kubectl --kubeconfig="k8s-challenge-kubeconfig.yaml" apply -f foundation/kyverno/install.yaml
namespace/kyverno created
customresourcedefinition.apiextensions.k8s.io/clusterpolicies.kyverno.io created
customresourcedefinition.apiextensions.k8s.io/clusterpolicyreports.wgpolicyk8s.io created
customresourcedefinition.apiextensions.k8s.io/clusterreportchangerequests.kyverno.io created
customresourcedefinition.apiextensions.k8s.io/generaterequests.kyverno.io created
customresourcedefinition.apiextensions.k8s.io/policies.kyverno.io created
customresourcedefinition.apiextensions.k8s.io/policyreports.wgpolicyk8s.io created
customresourcedefinition.apiextensions.k8s.io/reportchangerequests.kyverno.io created
serviceaccount/kyverno-service-account created
clusterrole.rbac.authorization.k8s.io/kyverno:admin-policies created
clusterrole.rbac.authorization.k8s.io/kyverno:admin-policyreport created
clusterrole.rbac.authorization.k8s.io/kyverno:admin-reportchangerequest created
clusterrole.rbac.authorization.k8s.io/kyverno:customresources created
clusterrole.rbac.authorization.k8s.io/kyverno:generatecontroller created
clusterrole.rbac.authorization.k8s.io/kyverno:leaderelection created
clusterrole.rbac.authorization.k8s.io/kyverno:policycontroller created
clusterrole.rbac.authorization.k8s.io/kyverno:userinfo created
clusterrole.rbac.authorization.k8s.io/kyverno:webhook created
clusterrolebinding.rbac.authorization.k8s.io/kyverno:customresources created
clusterrolebinding.rbac.authorization.k8s.io/kyverno:generatecontroller created
clusterrolebinding.rbac.authorization.k8s.io/kyverno:leaderelection created
clusterrolebinding.rbac.authorization.k8s.io/kyverno:policycontroller created
clusterrolebinding.rbac.authorization.k8s.io/kyverno:userinfo created
clusterrolebinding.rbac.authorization.k8s.io/kyverno:webhook created
configmap/kyverno created
configmap/kyverno-metrics created
service/kyverno-svc created
service/kyverno-svc-metrics created
deployment.apps/kyverno created
poddisruptionbudget.policy/kyverno created
```

A quick check of the new `kyverno` namespace shows that its pod is up and running.

```
# kdo get po
NAME                       READY   STATUS    RESTARTS   AGE
kyverno-7dc7f46bd7-ntshk   1/1     Running   0          2m21s
```


