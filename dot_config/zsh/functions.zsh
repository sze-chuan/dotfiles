# General functions - Used across all systems
# These functions are sourced in .zshrc

# Get Keycloak password from EdgeOS cluster
get-kc-pw() {
    if [ -z "$1" ]; then
        echo "Usage: get-kc-pw <hostname>"
        return 1
    fi
    ssh root@"$1".edgeos.illumina.com "/usr/local/bin/kubectl get secrets keycloak-creds -o jsonpath='{.data.admin_password}'" | base64 --decode
}

# Add your general functions below

