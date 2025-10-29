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

# Copy files from server using sftp
cfs() {
    # Parse arguments
    if [ -z "$1" ]; then
        echo "Usage: cfs [username@]hostname:source_path [destination_path]"
        echo "Examples:"
        echo "  cfs hostname:/path/to/file"
        echo "  cfs myuser@hostname:/path/to/file"
        echo "  cfs hostname:/path/to/file /tmp/myfiles"
        return 1
    fi

    local source_arg="$1"
    local dest="${2:-${HOME}/Downloads}"

    # Parse username@hostname:source_path format
    local username="ilmnadmin"
    local hostname=""
    local source_path=""
    local user_host=""

    # Split by colon to get source_path
    if [[ "$source_arg" == *:* ]]; then
        user_host="${source_arg%%:*}"
        source_path="${source_arg#*:}"
    else
        echo "Error: Invalid format. Use [username@]hostname:source_path"
        return 1
    fi

    # Split user_host by @ to get username and hostname
    if [[ "$user_host" == *@* ]]; then
        username="${user_host%%@*}"
        hostname="${user_host#*@}"
    else
        hostname="$user_host"
    fi

    # Validate required fields
    if [ -z "$hostname" ] || [ -z "$source_path" ]; then
        echo "Error: hostname and source_path are required"
        return 1
    fi

    # Ensure destination directory exists
    mkdir -p "$dest"

    # Create temporary batch file for sftp
    local batch_file=$(mktemp)
    echo "get -r \"$source_path\" \"$dest\"" > "$batch_file"

    echo "Copying from ${username}@${hostname}:${source_path} to ${dest}..."

    # Execute sftp with batch commands
    sftp -o PubKeyAuthentication=false -b "$batch_file" "${username}@${hostname}"
    local exit_code=$?

    # Cleanup
    rm -f "$batch_file"

    if [ $exit_code -eq 0 ]; then
        echo "Transfer completed successfully"
    else
        echo "Transfer failed with exit code $exit_code"
        return $exit_code
    fi
}

# Add your work-specific functions below

