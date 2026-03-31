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
        echo "Usage: add-ui-ca <hostname> [java_version]"
        echo "  hostname: The hostname to download CA certificate from"
        echo "  java_version: Java SDK version (11 or 17, default: 17)"
        echo ""
        echo "Examples:"
        echo "  add-ui-ca myserver.example.com"
        echo "  add-ui-ca myserver.example.com 11"
        echo "  add-ui-ca myserver.example.com 17"
        return 1
    fi

    local hostname="$1"
    local java_version="${2:-17}"
    local cert_url="http://${hostname}/v1/instruments/public/ca/file"
    local temp_cert="/tmp/ca_cert_${hostname}.crt"
    local keystore=""
    local alias="ca_${hostname}"

    # Determine keystore path based on Java version
    case "$java_version" in
        11)
            keystore="${HOME}/.local/share/mise/installs/java/corretto-11/lib/security/cacerts"
            ;;
        17)
            keystore="${HOME}/.local/share/mise/installs/java/openjdk-17/Contents/Home/lib/security/cacerts"
            ;;
        *)
            echo "Error: Unsupported Java version '${java_version}'"
            echo "Supported versions: 11, 17"
            return 1
            ;;
    esac

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

    # Check if alias already exists and remove it
    if keytool -list -alias "$alias" -keystore "$keystore" -storepass changeit &>/dev/null; then
        echo "Alias '${alias}' already exists, removing it..."
        if ! keytool -delete -alias "$alias" -keystore "$keystore" -storepass changeit; then
            echo "Error: Failed to remove existing alias"
            rm -f "$temp_cert"
            return 1
        fi
        echo "Existing alias removed successfully"
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

# Connect local UI dev environment to a remote EdgeOS server
connect-ui-dev() {
    if [ -z "$1" ]; then
        echo "Usage: connect-ui-dev <hostname>"
        echo "  hostname: The EdgeOS server hostname (FQDN)"
        echo ""
        echo "This function will:"
        echo "  1. Add the server's CA certificate to the Java keystore"
        echo "  2. Fetch the Keycloak UI client secret from the server"
        echo "  3. Update env.list in the current directory"
        echo ""
        echo "Example:"
        echo "  connect-ui-dev myserver.edgeos.illumina.com"
        return 1
    fi

    local hostname="$1"
    local env_file="./env.list"

    # Check env.list exists in current directory
    if [ ! -f "$env_file" ]; then
        echo "Error: env.list not found in current directory"
        return 1
    fi

    # Step 1: Add CA certificate
    echo "Adding CA certificate for ${hostname}..."
    if ! add-ui-ca "$hostname"; then
        echo "Error: Failed to add CA certificate"
        return 1
    fi

    # Step 2: Fetch Keycloak UI client secret from Kubernetes secret
    echo "Fetching Keycloak UI client secret from ${hostname}..."
    local client_secret
    client_secret=$(ssh root@"${hostname}" "kubectl get secret keycloak-client -o jsonpath='{.data.edgeos_ui_client_secret}'" | base64 --decode)

    if [ -z "$client_secret" ] || [ "$client_secret" = "null" ]; then
        echo "Error: Failed to retrieve Keycloak UI client secret"
        return 1
    fi

    # Step 3: Update env.list
    echo "Updating env.list..."

    # Portable in-place sed: BSD (macOS) needs -i '', GNU (Linux) needs -i
    local sed_i
    if [[ "$OSTYPE" == darwin* ]]; then
        sed_i=(sed -i '')
    else
        sed_i=(sed -i)
    fi

    if grep -q "^EDGEOS_UI_BASE_URL=" "$env_file"; then
        "${sed_i[@]}" "s|^EDGEOS_UI_BASE_URL=.*|EDGEOS_UI_BASE_URL=https://${hostname}|" "$env_file"
    else
        echo "EDGEOS_UI_BASE_URL=https://${hostname}" >> "$env_file"
    fi

    if grep -q "^EDGEOS_IMS_BASE_URL=" "$env_file"; then
        "${sed_i[@]}" "s|^EDGEOS_IMS_BASE_URL=.*|EDGEOS_IMS_BASE_URL=https://${hostname}|" "$env_file"
    else
        echo "EDGEOS_IMS_BASE_URL=https://${hostname}" >> "$env_file"
    fi

    if grep -q "^EDGEOS_UI_KEYCLOAK_CLIENT_EDGEOS_UI_SERVICE_SECRET=" "$env_file"; then
        "${sed_i[@]}" "s|^EDGEOS_UI_KEYCLOAK_CLIENT_EDGEOS_UI_SERVICE_SECRET=.*|EDGEOS_UI_KEYCLOAK_CLIENT_EDGEOS_UI_SERVICE_SECRET=${client_secret}|" "$env_file"
    else
        echo "EDGEOS_UI_KEYCLOAK_CLIENT_EDGEOS_UI_SERVICE_SECRET=${client_secret}" >> "$env_file"
    fi

    if grep -q "^EDGEOS_UI_IMS_BOOTSTRAPLOGIN_SECRET=" "$env_file"; then
        "${sed_i[@]}" "s|^EDGEOS_UI_IMS_BOOTSTRAPLOGIN_SECRET=.*|EDGEOS_UI_IMS_BOOTSTRAPLOGIN_SECRET=${client_secret}|" "$env_file"
    else
        echo "EDGEOS_UI_IMS_BOOTSTRAPLOGIN_SECRET=${client_secret}" >> "$env_file"
    fi

    echo ""
    echo "Successfully configured UI dev environment for ${hostname}"
    echo "Updated env.list with:"
    echo "  EDGEOS_UI_BASE_URL=https://${hostname}"
    echo "  EDGEOS_IMS_BASE_URL=https://${hostname}"
    echo "  EDGEOS_UI_KEYCLOAK_CLIENT_EDGEOS_UI_SERVICE_SECRET=<secret>"
    echo "  EDGEOS_UI_IMS_BOOTSTRAPLOGIN_SECRET=<secret>"
}

# Upgrade EdgeOS platform on a remote host
up-eos() {
    if [ -z "$1" ]; then
        echo "Usage: up-eos <installer_version>"
        echo "  installer_version: The installer version (e.g. 1.2.3)"
        echo ""
        echo "Example:"
        echo "  up-eos 1.2.3"
        return 1
    fi

    local version="$1"
    local fqdn="sky-p2-08.edgeos.illumina.com"
    local run_file="install_edgeos_platform-${version}-el9_sequencer2d2-com-e.run"
    local artifact_url="https://use1.artifactory.illumina.com/artifactory/generic-edgeos-run/dev/oracle9/sequencer2d2-com-e/${run_file}"
    local dest_dir="/usr/local/illumina"

    echo "Connecting to ${fqdn}..."
    ssh root@"${fqdn}" "
        set -e
        mkdir -p '${dest_dir}'
        echo 'Downloading installer ${version}...'
        curl -Lo '${dest_dir}/${run_file}' '${artifact_url}'
        echo 'Running installer...'
        bash '${dest_dir}/${run_file}'
        echo 'Cleaning up...'
        rm -f '${dest_dir}/${run_file}'
        echo 'Done.'
    "
}

# Load NextJS UI image onto an EdgeOS server
load-nextjs() {
    if [ -z "$1" ]; then
        echo "Usage: load-nextjs <hostname>"
        return 1
    fi

    local hostname="$1.edgeos.illumina.com"
    local tar_file="edgeos-ui-nextjs_latest.tar"
    local remote_path="/tmp/${tar_file}"

    echo "Copying ${tar_file} to root@${hostname}:${remote_path}..."
    if ! scp "$tar_file" "root@${hostname}:${remote_path}"; then
        echo "Error: Failed to copy tar file to ${hostname}"
        return 1
    fi

    echo "Importing image on ${hostname}..."
    if ! ssh "root@${hostname}" "k3s ctr images import ${remote_path} && rm -f ${remote_path}"; then
        echo "Error: Failed to import image on ${hostname}"
        return 1
    fi

    echo "Restarting NextJS pod on ${hostname}..."
    if ! ssh "root@${hostname}" "kubectl rollout restart deployment/edgeos-edgeosui-nextjs"; then
        echo "Error: Failed to restart NextJS pod on ${hostname}"
        return 1
    fi

    echo "Successfully loaded NextJS image onto ${hostname}"
}

# Get Keycloak password from EdgeOS cluster
get-kc-pw() {
    if [ -z "$1" ]; then
        echo "Usage: get-kc-pw <hostname>"
        return 1
    fi
    ssh root@"$1".edgeos.illumina.com "/usr/local/bin/kubectl get secrets keycloak-creds -o jsonpath='{.data.admin_password}'" | base64 --decode
}
