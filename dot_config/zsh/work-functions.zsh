# Work-specific functions - Used on both MacOS and Linux
# These functions are sourced in .zshrc

# Access Kubernetes cluster with k9s
k9h() {
    if [ -z "$1" ]; then
        echo "Usage: k9h <hostname>"
        return 1
    fi

    local hostname="$1"
    local kubeconfig="${HOME}/.kube/${hostname}.yaml"

    # Create .kube directory if it doesn't exist
    mkdir -p "${HOME}/.kube"

    # Fetch and configure kubeconfig, then launch k9s
    ssh root@"${hostname}".edgeos.illumina.com "cat /etc/rancher/k3s/k3s.yaml" | \
        yq ".clusters[0].cluster.server=\"https://${hostname}.edgeos.illumina.com:6443\"" > "${kubeconfig}" && \
        k9s --kubeconfig "${kubeconfig}"
}

# Add your work-specific functions below

