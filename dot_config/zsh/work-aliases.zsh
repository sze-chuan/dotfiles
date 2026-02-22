# Work-specific aliases - Used on both MacOS and Linux
# These aliases are sourced in .zshrc

# Docker/Development — password read from $POSTGRES_DEV_PASSWORD env var (set in ~/.env)
spd() {
    local pg_password="${POSTGRES_DEV_PASSWORD:?POSTGRES_DEV_PASSWORD is not set — add it to ~/.env}"
    docker run -p 127.0.0.1:5432:5432 -d --name postgres \
        -e POSTGRES_USER=user \
        -e POSTGRES_PASSWORD="$pg_password" \
        -e POSTGRES_DB=db \
        postgres
}

# Add your work-specific aliases below
# Examples:
# alias vpn='sudo openconnect your-vpn-server'
# alias work-ssh='ssh your-work-server'
# alias deploy-dev='kubectl config use-context dev && kubectl apply -f'
# alias logs-prod='kubectl logs -f deployment/app -n production'

