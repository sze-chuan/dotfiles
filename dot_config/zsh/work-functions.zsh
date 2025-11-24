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

# Grep lines containing service name from input file to output file
grepl() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: grepl <service_name> <input_file> <output_file>"
        echo "Example: grepl myservice input.log output.log"
        return 1
    fi

    local service_name="$1"
    local input_file="$2"
    local output_file="$3"

    # Validate input file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' does not exist"
        return 1
    fi

    # Execute awk command
    awk "/^.*${service_name}/" "$input_file" > "$output_file"
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "Filtered lines containing '${service_name}' from ${input_file} to ${output_file}"
    else
        echo "Error: Command failed with exit code $exit_code"
        return $exit_code
    fi
}

# Download CA certificate and add to OpenJDK certificate store
add-ui-ca() {
    if [ -z "$1" ]; then
        echo "Usage: add-ui-ca <hostname>"
        echo "Example: add-ui-ca myserver.example.com"
        return 1
    fi

    local hostname="$1"
    local cert_url="http://${hostname}/v1/instruments/public/ca/file"
    local temp_cert="/tmp/ca_cert_${hostname}.crt"
    local keystore="${HOME}/Library/Java/JavaVirtualMachines/openjdk-22.0.2/Contents/Home/lib/security/cacerts"
    local alias="ca_${hostname}"

    # Download CA certificate
    echo "Downloading CA certificate from ${cert_url}..."
    if ! curl -o "$temp_cert" "$cert_url"; then
        echo "Error: Failed to download CA certificate from ${cert_url}"
        return 1
    fi

    # Check if certificate was downloaded successfully
    if [ ! -f "$temp_cert" ]; then
        echo "Error: Certificate file not found at ${temp_cert}"
        return 1
    fi

    # Check if keystore exists
    if [ ! -f "$keystore" ]; then
        echo "Error: Keystore not found at ${keystore}"
        rm -f "$temp_cert"
        return 1
    fi

    # Import certificate into keystore
    echo "Importing certificate into OpenJDK keystore..."
    if keytool -importcert -file "$temp_cert" -alias "$alias" -keystore "$keystore" \
        -storepass changeit -noprompt; then
        echo "Successfully imported CA certificate for ${hostname}"
        # Cleanup temp file
        rm -f "$temp_cert"
        return 0
    else
        echo "Error: Failed to import certificate into keystore"
        rm -f "$temp_cert"
        return 1
    fi
}

# Get Keycloak password from EdgeOS cluster
get-kc-pw() {
    if [ -z "$1" ]; then
        echo "Usage: get-kc-pw <hostname>"
        return 1
    fi
    ssh root@"$1".edgeos.illumina.com "/usr/local/bin/kubectl get secrets keycloak-creds -o jsonpath='{.data.admin_password}'" | base64 --decode
}
