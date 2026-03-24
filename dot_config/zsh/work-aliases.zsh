# Work-specific aliases - Used on both MacOS and Linux
# These aliases are sourced in .zshrc

# Docker/Development
alias spd='docker run -p 127.0.0.1:5432:5432 -d --name postgres -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_DB=db postgres'

# Kubernetes
alias k='kubectl'
alias kg='kubectl get'
alias kgp='kubectl get pods -o wide'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
alias kgcm='kubectl get configmaps'
alias kgsec='kubectl get secrets'
alias kgpv='kubectl get pv'
alias kgpvc='kubectl get pvc'
alias kging='kubectl get ingress'
alias kgsa='kubectl get serviceaccounts'

alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe node'

alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'

alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kdel='kubectl delete'

alias kn='kubectl config set-context --current --namespace'
alias kcx='kubectl config use-context'
alias kcgx='kubectl config get-contexts'

alias krr='kubectl rollout restart deployment'
alias krs='kubectl rollout status deployment'
alias krh='kubectl rollout history deployment'

alias kpf='kubectl port-forward'

# EdgeOS development
alias reset='make helm-uninstall clean build load helm-integration'
alias install='make clean build load helm-integration'
alias helm-reset='make helm-uninstall helm-integration'
alias cbl='make clean build load'
