deploy-kyverno:
	kubectl --kubeconfig="k8s-challenge-kubeconfig.yaml" apply -f foundation/kyverno/install.yaml