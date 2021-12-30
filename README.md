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
$ make deploy-kyverno 
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

## Creating a New Rule

One of the things I have run into in my daily job is not always knowing who to contact when things go wrong. Development teams don't always follow the rules and namespaces do not always get created with a Point of Contact. Our policy is to have namespaces annotated so the admin team knows who to reach out to when we see issues. I decided to see how I could enforce this with Kyverno.

The following policy will check any namespace resources for the appropriate annotation. I currently have it set to `audit`. It will still create the namespace, but I should see a report indicating that the policy wasn't followed.

```
apiVersion : kyverno.io/v1  
kind: ClusterPolicy
metadata:
  name: check-poc-annotation
spec:
  validationFailureAction: audit
  rules:
  - name: check-poc-annotation
    match:
      any:
      - resources:
          kinds: 
          - Namespace
    validate:
      message: "All namespace resources need to be created with the following annotation: 'internal-poc'"
      pattern:
        metadata:
          annotations:
            internal-poc: "*"
```

I created two sample files to test the policy against.

*ns-without-poc*
```
apiVersion: v1
kind: Namespace
metadata:
  name: no-poc
spec: {}
status: {}
```

*ns-with-poc*
```
apiVersion: v1
kind: Namespace
metadata:
  name: good-poc
  annotations:
    internal-poc: 'root@runlevl4.com'
spec: {}
status: {}
```

Next, I used the Kyverno CLI to test each manifest. You can see in the first example, the test failed. Exactly what I wanted.

```
$ ./kyverno apply rules/rule-ns-poc.yaml --resource scenarios/ns-without-poc.yaml                                                                                                1 ✘

Applying 1 policy to 1 resource...
(Total number of result count may vary as the policy is mutated by Kyverno. To check the mutated policy please try with log level 5)

policy check-poc-annotation -> resource default/Namespace/no-poc failed:
1. check-poc-annotation: validation error: All namespace resources need to be created with the following annotation: 'internal-poc'. Rule check-poc-annotation failed at path /metadata/annotations/

pass: 0, fail: 1, warn: 0, error: 0, skip: 0



$ ./kyverno apply rules/rule-ns-poc.yaml --resource scenarios/ns-with-poc.yaml Applying 1 policy to 1 resource...
(Total number of result count may vary as the policy is mutated by Kyverno. To check the mutated policy please try with log level 5)

pass: 1, fail: 0, warn: 0, error: 0, skip: 0
```

When policies are set to `audit` rather than `enforce` failures are logged either to a `policyreport` or `clusterpolicyreport` depending on the type of policy that was violated. In my case, I am creating cluster policies. You can see the output of my `clusterpolicyreport` here:

```
$ kdo get clusterpolicyreport clusterpolicyreport -o yaml 
apiVersion: wgpolicyk8s.io/v1alpha2
kind: ClusterPolicyReport
metadata:
  creationTimestamp: "2021-12-29T19:02:21Z"
  generation: 16
  name: clusterpolicyreport
  resourceVersion: "1313831"
  uid: 8d0413b8-45ef-4f2c-be70-665b4909697d
results:
- message: 'validation error: All namespace resources need to be created with the
    following annotation: ''internal-poc''. Rule check-poc-annotation failed at path
    /metadata/annotations/'
  policy: check-poc-annotation
  resources:
  - apiVersion: v1
    kind: Namespace
    name: default
    uid: e0de133c-bad2-4d49-ac77-9b0c63a1a2b5
  result: fail
  rule: check-poc-annotation
  scored: true
  source: Kyverno
  timestamp:
    nanos: 0
    seconds: 1640821824
- message: 'validation error: All namespace resources need to be created with the
    following annotation: ''internal-poc''. Rule check-poc-annotation failed at path
    /metadata/annotations/'
  policy: check-poc-annotation
  resources:
  - apiVersion: v1
    kind: Namespace
    name: ingress-nginx
    uid: f8fcc2d0-08ec-43ba-9d6e-e73305675c52
  result: fail
  rule: check-poc-annotation
  scored: true
  source: Kyverno
  timestamp:
    nanos: 0
    seconds: 1640821824
summary:
  error: 0
  fail: 2
  pass: 0
  skip: 0
  warn: 0
```

```
$ kdo apply -f scenarios/ns-without-poc.yaml  
Error from server: error when creating "scenarios/ns-without-poc.yaml": admission webhook "validate.kyverno.svc-fail" denied the request:

resource Namespace//no-poc was blocked due to the following policies

check-poc-annotation:
  check-poc-annotation: 'validation error: All namespace resources need to be created
    with the following annotation: ''internal-poc''. Rule check-poc-annotation failed
    at path /metadata/annotations/'
```

Great news! I just got blocked by my first policy! I tried to implicitly create a new namespace and the policy told me I couldn't do it.

```
$ kdo create ns multi-teams
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Namespace//multi-teams was blocked due to the following policies

check-poc-annotation:
  check-poc-annotation: 'validation error: All namespace resources need to be created
    with the following annotation: ''internal-poc''. Rule check-poc-annotation failed
    at path /metadata/annotations/'
```

## Expanding Policy Footprint

One of the things we recently noticed is that some of the teams have split responsibilities between sub-teams. We can no longer assume that one team is reponsible for every deployment within a single namespace. So let's expand the previous example to track the same info for Team Alpha and Team Bravo. We'll exclude system namespaces from the policy.

This time, we'll make a namespace-scoped policy. This policy will:

- be scoped only to the `multi-teams` namespace
- verify that the annotation has been specified
- ensure that the POC starts with `team` (just an example, not really real-world)

```
apiVersion : kyverno.io/v1  
kind: Policy
metadata:
  name: check-deployment-poc-annotation
  namespace: multi-teams
spec:
  validationFailureAction: enforce
  rules:
  - name: check-poc-annotation
    match:
      any:
      - resources:
          kinds: 
          - Deployment
    validate:
      message: "All Deployment resources need to be created with the following annotation: 'internal-poc'"
      pattern:
        metadata:
          annotations:
            internal-poc: "team*"
```

Creating a new Deployment without the appropriate annotation results in the same failure we saw previously with the namespace example.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: myapp
  annotations:
    internal-poc: "team-alpha@myco.com"
  name: myapp
  namespace: multi-teams
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  strategy: {}
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}

```

Now we can run the test again and see that the manifest passes.

```
$ ./kyverno apply rules/rule-deploy-poc.yaml --resource scenarios/deploy-poc/deploy-with-poc.yaml
Applying 1 policy to 1 resource...
(Total number of result count may vary as the policy is mutated by Kyverno. To check the mutated policy please try with log level 5)

pass: 1, fail: 0, warn: 0, error: 0, skip: 0
```

## Mutation Policies

This next example is more of a POC and not likely something I would do in real life. While I see the benefit of mutating webhooks, I don't think I like them in practice since the resources no longer match source control. For example, we're going to see if Kyverno can add resource limits if they weren't provided. If we do this when using a tool like ArgoCD, it will see the resource mismatch and want to sync to resolve it unless we tell it to ignore the difference. But then, that sort of defeats a purpose of having a GitOps tool like Argo.

We're going to throw a couple of interesting techniques in this example:

- We will mutate each container in the Pod with `foreach`
- If the limits aren't specified, we'll add both CPU and memory

Let's look at the rule now.

```
apiVersion : kyverno.io/v1  
kind: Policy
metadata:
  name: enforce-deployment-resource-limits
  namespace: multi-teams
spec:
  validationFailureAction: enforce
  rules:
  - name: enforce-deployment-resource-limits
    match:
      any:
      - resources:
          kinds: 
          - Pod
    mutate:
      foreach:
      - list: "request.object.spec.containers"
        patchStrategicMerge:
          spec:
            containers:
            - name: "{{ element.name }}" 
              image: artifactory.my.com:5000/acr/{{ images.containers."{{element.name}}".path}}:{{images.containers."{{element.name}}".tag}}
              resources:              
                limits:
                  +(cpu): 50m
                  +(memory): 250M
```

I've made this a policy targeting Pods rather than the deployment since that's the ultimate resource being created. In order to test, I created a sample Pod manifest based on my Deployment.

```
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: myapp
  name: myapp
  namespace: multi-teams
spec:
  containers:
  - image: nginx
    name: nginx
```

You can see that there aren't any resources specified. When we test it, however, you can see that Kyverno has added them. It's also added MyCo's private registry to ensure that the image comes from our scanned registry rather than Docker Hub.

```
$ ./kyverno apply rules/rule-deploy-enforce-limits.yaml --resource scenarios/mutate-limits/test-pod.yaml                                                                    ✔

Applying 1 policy to 1 resource...
(Total number of result count may vary as the policy is mutated by Kyverno. To check the mutated policy please try with log level 5)

mutate policy enforce-deployment-resource-limits applied to multi-teams/Pod/myapp:
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: myapp
  name: myapp
  namespace: multi-teams
spec:
  containers:
  - image: artifactory.myco.com:5000/acr/nginx:latest
    name: nginx
    resources:
      limits:
        cpu: 50m
        memory: 250M

---

pass: 1, fail: 0, warn: 0, error: 0, skip: 2
```

And finally, when I deploy the resource, you can see that it's been added to the resulting manifes.


```
spec:
  containers:
  - image: artifactory.myco.com:5000/acr/nginx:latest
    imagePullPolicy: Always
    name: nginx
    resources:
      limits:
        cpu: 50m
        memory: 250M
```

## Conclusion

Overall, Kyverno is working pretty well. It took a little digging and prodding to get things working right (namely mutations) but it works like a dream. Looking forward to doing a more in-depth POC to explore its capabilities even further.