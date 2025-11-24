# Git Worktree Management Functions
# These functions help manage multiple git worktrees in a clean directory structure
# Structure: <repo>/.bare/ (bare repo) + <repo>/main/, <repo>/feature/, etc.

# Initialize a repository for worktree-based workflow
# Usage: gwt-init [main-branch-name]
gwt-init() {
    local main_branch="${1:-main}"

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi

    # Check if already using worktree structure
    if [[ "$(git rev-parse --git-common-dir)" == *".bare"* ]]; then
        echo "Error: Repository already using worktree structure"
        return 1
    fi

    local repo_root=$(git rev-parse --show-toplevel)
    local repo_name=$(basename "$repo_root")
    local parent_dir=$(dirname "$repo_root")

    echo "Converting $repo_name to worktree structure..."
    echo "Current location: $repo_root"
    echo "New structure: $repo_root/.bare/ + $repo_root/$main_branch/"
    echo
    read -q "REPLY?Continue? (y/n) "
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        return 1
    fi

    # Create temporary directory for building new structure
    local temp_dir=$(mktemp -d)
    echo "Building new structure in temporary location..."

    # Copy .git to temp as .bare
    cp -r "$repo_root/.git" "$temp_dir/.bare"

    # Configure as bare repository
    git -C "$temp_dir/.bare" config core.bare true

    # Remove the worktree configuration (if any) from the bare repo
    rm -rf "$temp_dir/.bare/worktrees"

    # Create main worktree in temp
    echo "Creating main worktree..."
    if ! git -C "$temp_dir/.bare" worktree add "$temp_dir/$main_branch" "$main_branch" 2>/dev/null; then
        echo "Error: Failed to create main worktree"
        rm -rf "$temp_dir"
        return 1
    fi

    # Copy working files to new main worktree
    echo "Copying files..."
    rsync -a --exclude='.git' "$repo_root/" "$temp_dir/$main_branch/"

    # Now safely remove old .git and working files, keeping the directory structure
    echo "Cleaning up old structure..."
    rm -rf "$repo_root/.git"

    # Remove all files and directories except hidden files/dirs we want to keep
    # Use find to remove everything at depth 1 except .git (already removed)
    find "$repo_root" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

    # Move new structure into place
    echo "Moving new structure into place..."
    mv "$temp_dir/.bare" "$repo_root/"
    mv "$temp_dir/$main_branch" "$repo_root/"

    # Update worktree path in git config
    # The worktree path in .bare/worktrees/<branch>/gitdir needs to be updated
    local worktree_config="$repo_root/.bare/worktrees/$main_branch/gitdir"
    if [[ -f "$worktree_config" ]]; then
        echo "$repo_root/$main_branch/.git" > "$worktree_config"
    fi

    # Clean up temp directory
    rm -rf "$temp_dir"

    echo
    echo "✓ Conversion complete!"
    echo "  Bare repo: $repo_root/.bare/"
    echo "  Main worktree: $repo_root/$main_branch/"
    echo
    echo "Next steps:"
    echo "  cd $repo_root/$main_branch"
    echo "  gwt-add <branch-name>  # Create additional worktrees"
}

# Create a new worktree
# Usage: gwt-add <branch-name> [base-branch]
gwt-add() {
    if [[ -z "$1" ]]; then
        echo "Usage: gwt-add <branch-name> [base-branch]"
        echo
        echo "Examples:"
        echo "  gwt-add feature-auth          # Create from current branch"
        echo "  gwt-add feature-auth main     # Create from main"
        echo "  gwt-add pr-review origin/pr   # Create from remote branch"
        return 1
    fi

    local branch_name="$1"
    local base_branch="${2:-HEAD}"

    # Check if we're in a worktree-based repository
    local git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    if [[ -z "$git_common_dir" ]] || [[ "$git_common_dir" != *".bare"* ]]; then
        echo "Error: Not in a worktree-based repository"
        echo "Run 'gwt-init' first to convert this repository"
        return 1
    fi

    # Get the parent directory (where all worktrees live)
    local current_worktree=$(git rev-parse --show-toplevel)
    local parent_dir=$(dirname "$current_worktree")
    local new_worktree="$parent_dir/$branch_name"

    # Check if worktree directory already exists
    if [[ -d "$new_worktree" ]]; then
        echo "Error: Directory already exists: $new_worktree"
        return 1
    fi

    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Branch '$branch_name' exists, checking it out..."
        git worktree add "$new_worktree" "$branch_name"
    else
        echo "Creating new branch '$branch_name' from '$base_branch'..."
        git worktree add -b "$branch_name" "$new_worktree" "$base_branch"
    fi

    if [[ $? -eq 0 ]]; then
        echo
        echo "✓ Worktree created: $new_worktree"
        echo "  cd $new_worktree"
    fi
}

# Remove a worktree
# Usage: gwt-rm <branch-name> [-d]
gwt-rm() {
    if [[ -z "$1" ]]; then
        echo "Usage: gwt-rm <branch-name> [-d]"
        echo
        echo "Options:"
        echo "  -d    Also delete the branch"
        echo
        echo "Examples:"
        echo "  gwt-rm feature-auth      # Remove worktree only"
        echo "  gwt-rm feature-auth -d   # Remove worktree and delete branch"
        return 1
    fi

    local branch_name="$1"
    local delete_branch=false

    if [[ "$2" == "-d" ]]; then
        delete_branch=true
    fi

    # Get the parent directory
    local current_worktree=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$current_worktree" ]]; then
        echo "Error: Not in a git repository"
        return 1
    fi

    local parent_dir=$(dirname "$current_worktree")
    local worktree_path="$parent_dir/$branch_name"

    # Check if we're trying to remove current worktree
    if [[ "$current_worktree" == "$worktree_path" ]]; then
        echo "Error: Cannot remove current worktree"
        echo "Please switch to a different worktree first"
        return 1
    fi

    # Check if worktree exists
    if ! git worktree list | grep -q "$worktree_path"; then
        echo "Error: Worktree '$branch_name' not found"
        return 1
    fi

    # Remove the worktree
    echo "Removing worktree: $worktree_path"
    git worktree remove "$worktree_path"

    if [[ $? -eq 0 ]]; then
        echo "✓ Worktree removed"

        # Delete branch if requested
        if [[ "$delete_branch" == true ]]; then
            echo "Deleting branch: $branch_name"
            git branch -d "$branch_name"
            if [[ $? -eq 0 ]]; then
                echo "✓ Branch deleted"
            else
                echo "Note: Use 'git branch -D $branch_name' to force delete"
            fi
        fi
    fi
}

# List all worktrees
# Usage: gwt-list
gwt-list() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi

    echo "Active worktrees:"
    echo
    git worktree list
}

# Change to a worktree directory
# Usage: gwt-cd <branch-name>
# Note: This must be used with: cd $(gwt-cd <branch-name>)
gwt-cd() {
    if [[ -z "$1" ]]; then
        echo "Usage: cd \$(gwt-cd <branch-name>)"
        echo
        echo "Tip: Add this alias to make it easier:"
        echo "  alias gcd='cd \$(gwt-cd)'"
        return 1
    fi

    local branch_name="$1"

    # Get the parent directory
    local current_worktree=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$current_worktree" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    local parent_dir=$(dirname "$current_worktree")
    local target_worktree="$parent_dir/$branch_name"

    # Check if worktree exists
    if [[ ! -d "$target_worktree" ]]; then
        echo "Error: Worktree '$branch_name' not found" >&2
        return 1
    fi

    # Verify it's actually a git worktree
    if ! git -C "$target_worktree" rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: '$target_worktree' is not a valid git worktree" >&2
        return 1
    fi

    echo "$target_worktree"
}

# Clone a repository with worktree structure
# Usage: gwt-clone <repo-url> [directory] [main-branch]
gwt-clone() {
    if [[ -z "$1" ]]; then
        echo "Usage: gwt-clone <repo-url> [directory] [main-branch]"
        echo
        echo "Examples:"
        echo "  gwt-clone https://github.com/user/repo.git"
        echo "  gwt-clone https://github.com/user/repo.git my-project"
        echo "  gwt-clone https://github.com/user/repo.git my-project develop"
        return 1
    fi

    local repo_url="$1"
    local repo_name="${2:-$(basename -s .git "$repo_url")}"
    local main_branch="${3}"

    # Check if directory already exists
    if [[ -d "$repo_name" ]]; then
        echo "Error: Directory '$repo_name' already exists"
        return 1
    fi

    echo "Cloning $repo_url as worktree structure..."

    # Create directory structure
    mkdir -p "$repo_name"

    # Clone as bare repository
    git clone --bare "$repo_url" "$repo_name/.bare"

    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to clone repository"
        rm -rf "$repo_name"
        return 1
    fi

    # Auto-detect default branch if not specified
    if [[ -z "$main_branch" ]]; then
        main_branch=$(git -C "$repo_name/.bare" symbolic-ref --short HEAD 2>/dev/null)
        if [[ -z "$main_branch" ]]; then
            # Fallback: try to detect from refs
            main_branch=$(git -C "$repo_name/.bare" branch -a | grep -o 'HEAD -> [^/]*/\K.*' | head -1)
        fi
        if [[ -z "$main_branch" ]]; then
            # Last resort: use 'main' as default
            main_branch="main"
        fi
        echo "Detected default branch: $main_branch"
    fi

    # Create main worktree
    echo "Creating main worktree..."
    # Use ../ since we're running git from within .bare directory
    git -C "$repo_name/.bare" worktree add "../$main_branch" "$main_branch"

    if [[ $? -eq 0 ]]; then
        echo
        echo "✓ Repository cloned with worktree structure!"
        echo "  Bare repo: $repo_name/.bare/"
        echo "  Main worktree: $repo_name/$main_branch/"
        echo
        echo "Next steps:"
        echo "  cd $repo_name/$main_branch"
    else
        echo "Error: Failed to create main worktree"
        echo "Tip: Check if branch '$main_branch' exists with: git -C $repo_name/.bare branch -a"
        rm -rf "$repo_name"
        return 1
    fi
}

# Show help for git worktree functions
gwt-help() {
    cat << 'EOF'
Git Worktree Management Functions

These functions help you work with multiple branches simultaneously
without the need to stash changes.

COMMANDS:
  gwt-init [branch]           Convert existing repo to worktree structure
  gwt-clone <url> [dir]       Clone repo with worktree structure
  gwt-add <branch> [base]     Create new worktree
  gwt-rm <branch> [-d]        Remove worktree (optionally delete branch)
  gwt-list                    List all worktrees
  gwt-cd <branch>             Get path to worktree (use with cd)
  gwt-help                    Show this help

WORKFLOW EXAMPLE:
  # One-time setup
  cd ~/projects/myrepo
  gwt-init                    # Convert to worktree structure

  # Daily workflow
  gwt-add feature-auth        # Create feature branch worktree
  cd ../feature-auth          # Work on feature

  gwt-add pr-review main      # Need to review a PR? Create another worktree
  cd ../pr-review             # Review code

  cd ../feature-auth          # Back to your work (no stashing needed!)

  gwt-rm pr-review           # Done with review

DIRECTORY STRUCTURE:
  myrepo/
  ├── .bare/                  # Bare git repository
  ├── main/                   # Main branch worktree
  ├── feature-auth/           # Feature worktree
  └── pr-review/              # PR review worktree

For more info: https://git-scm.com/docs/git-worktree
EOF
}
