#!/usr/bin/env bash
# Cloud Account Switcher - Fast CLI for multi-cloud, multi-account management
# Zero performance overhead - only runs when explicitly called

# ============================================================================
# AWS Profile Management
# ============================================================================

# Quick AWS profile switcher
awsp() {
    if [ -z "$1" ]; then
        echo "Current AWS Profile: ${AWS_PROFILE:-default}"
        echo ""
        echo "Available profiles:"
        grep '^\[profile' ~/.aws/config | sed 's/\[profile \(.*\)\]/  - \1/' | sort
        grep '^\[default\]' ~/.aws/config > /dev/null && echo "  - default"
        return
    fi

    export AWS_PROFILE="$1"
    echo "✓ Switched to AWS profile: $AWS_PROFILE"

    # Update tmux status if in tmux
    if [ -n "$TMUX" ]; then
        tmux refresh-client -S
    fi
}

# AWS profile aliases for quick switching
alias aws-datakai='export AWS_PROFILE=datakai && echo "✓ AWS: datakai"'
alias aws-westmonroe='export AWS_PROFILE=westmonroe && echo "✓ AWS: westmonroe"'
alias aws-express='export AWS_PROFILE=express && echo "✓ AWS: express"'
alias aws-trulieve='export AWS_PROFILE=trulieve && echo "✓ AWS: trulieve"'
alias aws-default='unset AWS_PROFILE && echo "✓ AWS: default"'

# Show current AWS identity
alias aws-whoami='aws sts get-caller-identity'

# ============================================================================
# Azure Subscription Management
# ============================================================================

# Quick Azure subscription switcher
azsp() {
    if [ -z "$1" ]; then
        echo "Current Azure Subscription:"
        az account show --query "{Name:name, ID:id, State:state}" -o table 2>/dev/null || echo "Not logged in"
        echo ""
        echo "Available subscriptions:"
        az account list --query "[].{Name:name, ID:id, State:state}" -o table 2>/dev/null
        return
    fi

    az account set --subscription "$1"
    echo "✓ Switched to Azure subscription: $1"

    # Update tmux status if in tmux
    if [ -n "$TMUX" ]; then
        tmux refresh-client -S
    fi
}

# Azure subscription aliases (update with your subscription names/IDs)
alias az-westmonroe='azsp "West Monroe Sandbox" && echo "✓ Azure: westmonroe"'
alias az-express='azsp "Express Pros Prod" && echo "✓ Azure: express"'
alias az-datakai='azsp "DataKai Development" && echo "✓ Azure: datakai"'

# Show current Azure identity
alias az-whoami='az account show'

# ============================================================================
# Databricks Profile Management
# ============================================================================

# Quick Databricks profile switcher
dbxp() {
    if [ -z "$1" ]; then
        echo "Current Databricks Profile: ${DATABRICKS_CONFIG_PROFILE:-DEFAULT}"
        echo ""
        echo "Available profiles (from ~/.databrickscfg):"
        grep '^\[' ~/.databrickscfg 2>/dev/null | sed 's/\[\(.*\)\]/  - \1/' | sort
        return
    fi

    export DATABRICKS_CONFIG_PROFILE="$1"
    echo "✓ Switched to Databricks profile: $DATABRICKS_CONFIG_PROFILE"

    # Update tmux status if in tmux
    if [ -n "$TMUX" ]; then
        tmux refresh-client -S
    fi
}

# Databricks profile aliases (update based on your ~/.databrickscfg)
alias dbx-westmonroe='export DATABRICKS_CONFIG_PROFILE=westmonroe && echo "✓ Databricks: westmonroe"'
alias dbx-trulieve='export DATABRICKS_CONFIG_PROFILE=trulieve && echo "✓ Databricks: trulieve"'
alias dbx-express='export DATABRICKS_CONFIG_PROFILE=express && echo "✓ Databricks: express"'
alias dbx-default='unset DATABRICKS_CONFIG_PROFILE && echo "✓ Databricks: default"'

# ============================================================================
# GCP Project Management
# ============================================================================

# Quick GCP project switcher
gcpp() {
    if [ -z "$1" ]; then
        echo "Current GCP Project: $(gcloud config get-value project 2>/dev/null || echo 'Not set')"
        echo ""
        echo "Available projects:"
        gcloud projects list --format="table(projectId, name)" 2>/dev/null
        return
    fi

    gcloud config set project "$1" --quiet
    echo "✓ Switched to GCP project: $1"

    # Update tmux status if in tmux
    if [ -n "$TMUX" ]; then
        tmux refresh-client -S
    fi
}

# GCP project aliases (update with your project IDs)
alias gcp-datakai='gcpp "datakai-prod" && echo "✓ GCP: datakai"'
alias gcp-westmonroe='gcpp "westmonroe-analytics" && echo "✓ GCP: westmonroe"'
alias gcp-express='gcpp "express-prod" && echo "✓ GCP: express"'

# Show current GCP identity
alias gcp-whoami='gcloud config list account --format "value(core.account)"'

# ============================================================================
# Snowflake Account Management
# ============================================================================

# Quick Snowflake account switcher
snowp() {
    if [ -z "$1" ]; then
        echo "Current Snowflake Account: ${SNOWFLAKE_ACCOUNT:-Not set}"
        echo "Current Snowflake User: ${SNOWFLAKE_USER:-Not set}"
        echo ""
        echo "Available aliases:"
        echo "  - datakai"
        echo "  - westmonroe"
        echo "  - express"
        echo "  - trulieve"
        return
    fi

    case "$1" in
        datakai)
            export SNOWFLAKE_ACCOUNT="datakai"
            export SNOWFLAKE_USER="admin@datakai.com"
            export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
            export SNOWFLAKE_DATABASE="ANALYTICS"
            echo "✓ Switched to Snowflake: datakai"
            ;;
        westmonroe)
            export SNOWFLAKE_ACCOUNT="westmonroe"
            export SNOWFLAKE_USER="hstecher@westmonroe.com"
            export SNOWFLAKE_WAREHOUSE="WM_WH"
            export SNOWFLAKE_DATABASE="WM_DATA"
            echo "✓ Switched to Snowflake: westmonroe"
            ;;
        express)
            export SNOWFLAKE_ACCOUNT="expresspros"
            export SNOWFLAKE_USER="hstecher@expresspros.com"
            export SNOWFLAKE_WAREHOUSE="EXPRESS_WH"
            export SNOWFLAKE_DATABASE="EXPRESS_DATA"
            echo "✓ Switched to Snowflake: express"
            ;;
        trulieve)
            export SNOWFLAKE_ACCOUNT="trulieve"
            export SNOWFLAKE_USER="hstecher@trulieve.com"
            export SNOWFLAKE_WAREHOUSE="TRU_WH"
            export SNOWFLAKE_DATABASE="TRU_DATA"
            echo "✓ Switched to Snowflake: trulieve"
            ;;
        *)
            echo "Usage: snowp {datakai|westmonroe|express|trulieve}"
            return 1
            ;;
    esac

    # Update tmux status if in tmux
    if [ -n "$TMUX" ]; then
        tmux refresh-client -S
    fi
}

# Snowflake aliases
alias snow-datakai='snowp datakai'
alias snow-westmonroe='snowp westmonroe'
alias snow-express='snowp express'
alias snow-trulieve='snowp trulieve'

# Show current Snowflake context
alias snow-whoami='echo "Account: $SNOWFLAKE_ACCOUNT | User: $SNOWFLAKE_USER | Warehouse: $SNOWFLAKE_WAREHOUSE"'

# ============================================================================
# Multi-Cloud Context Switcher (The Power Move)
# ============================================================================

# Switch ALL cloud contexts at once based on client
cloud-switch() {
    case "$1" in
        datakai)
            export AWS_PROFILE=datakai
            azsp "DataKai Development" 2>/dev/null
            unset DATABRICKS_CONFIG_PROFILE
            gcpp "datakai-prod" 2>/dev/null
            snowp datakai 2>/dev/null
            echo "✓ Switched to DataKai context"
            echo "  AWS: datakai | Azure: DataKai Development | GCP: datakai-prod"
            ;;
        westmonroe)
            export AWS_PROFILE=westmonroe
            azsp "West Monroe Sandbox" 2>/dev/null
            export DATABRICKS_CONFIG_PROFILE=westmonroe
            gcpp "westmonroe-analytics" 2>/dev/null
            snowp westmonroe 2>/dev/null
            echo "✓ Switched to West Monroe context"
            echo "  AWS: westmonroe | Azure: Sandbox | DBX: westmonroe | GCP: westmonroe-analytics"
            ;;
        express)
            export AWS_PROFILE=express
            azsp "Express Pros Prod" 2>/dev/null
            export DATABRICKS_CONFIG_PROFILE=express
            gcpp "express-prod" 2>/dev/null
            snowp express 2>/dev/null
            echo "✓ Switched to Express Pros context"
            echo "  AWS: express | Azure: Prod | DBX: express | GCP: express-prod"
            ;;
        trulieve)
            export AWS_PROFILE=trulieve
            export DATABRICKS_CONFIG_PROFILE=trulieve
            snowp trulieve 2>/dev/null
            echo "✓ Switched to Trulieve context"
            echo "  AWS: trulieve | DBX: trulieve | Snowflake: trulieve"
            ;;
        *)
            echo "Usage: cloud-switch {datakai|westmonroe|express|trulieve}"
            echo ""
            echo "Current context:"
            echo "  AWS:        ${AWS_PROFILE:-default}"
            echo "  Azure:      $(az account show --query name -o tsv 2>/dev/null || echo 'Not set')"
            echo "  Databricks: ${DATABRICKS_CONFIG_PROFILE:-DEFAULT}"
            echo "  GCP:        $(gcloud config get-value project 2>/dev/null || echo 'Not set')"
            echo "  Snowflake:  ${SNOWFLAKE_ACCOUNT:-Not set}"
            return 1
            ;;
    esac

    # Update tmux status if in tmux
    if [ -n "$TMUX" ]; then
        tmux refresh-client -S
    fi
}

# Quick aliases for cloud-switch
alias cs='cloud-switch'
alias cs-dk='cloud-switch datakai'
alias cs-wm='cloud-switch westmonroe'
alias cs-ep='cloud-switch express'
alias cs-tl='cloud-switch trulieve'

# ============================================================================
# Cloud Status Display
# ============================================================================

# Show current cloud context (all providers)
cloud-status() {
    echo "☁️  Current Cloud Context:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # AWS
    if [ -n "$AWS_PROFILE" ]; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "Unknown")
        echo "AWS Profile:    $AWS_PROFILE (Account: $AWS_ACCOUNT)"
    else
        echo "AWS Profile:    default"
    fi

    # Azure
    AZ_SUB=$(az account show --query name -o tsv 2>/dev/null || echo "Not logged in")
    echo "Azure Sub:      $AZ_SUB"

    # Databricks
    if [ -n "$DATABRICKS_CONFIG_PROFILE" ]; then
        echo "Databricks:     $DATABRICKS_CONFIG_PROFILE"
    else
        echo "Databricks:     DEFAULT"
    fi

    # GCP
    GCP_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "Not set")
    GCP_ACCOUNT=$(gcloud config get-value account 2>/dev/null || echo "Not set")
    echo "GCP Project:    $GCP_PROJECT ($GCP_ACCOUNT)"

    # Snowflake
    if [ -n "$SNOWFLAKE_ACCOUNT" ]; then
        echo "Snowflake:      $SNOWFLAKE_ACCOUNT ($SNOWFLAKE_USER)"
        echo "  Warehouse:    $SNOWFLAKE_WAREHOUSE"
        echo "  Database:     $SNOWFLAKE_DATABASE"
    else
        echo "Snowflake:      Not set"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

alias cstat='cloud-status'
alias cloudstat='cloud-status'

# ============================================================================
# Integration with .project.toml
# ============================================================================

# Auto-switch cloud context when entering a project
# This reads .project.toml and switches cloud accounts automatically
cloud-auto() {
    if [ -f .project.toml ]; then
        # Extract owner from .project.toml
        OWNER=$(grep 'primary.*=' .project.toml | sed 's/.*"\(.*\)".*/\1/')

        if [ -n "$OWNER" ]; then
            case "$OWNER" in
                datakai|westmonroe|express|trulieve)
                    cloud-switch "$OWNER"
                    ;;
            esac
        fi
    fi
}

# Add to your cd function or direnv
# Uncomment if you want auto-switching on cd:
# cd() {
#     builtin cd "$@" && cloud-auto
# }

# ============================================================================
# Terraform Workspace Helpers (for multi-account Terraform)
# ============================================================================

# Show Terraform workspace and cloud context together
tf-status() {
    echo "Terraform Workspace: $(terraform workspace show 2>/dev/null || echo 'Not in TF directory')"
    cloud-status
}

# Switch Terraform workspace AND cloud context
tf-switch() {
    if [ -z "$1" ]; then
        echo "Usage: tf-switch {datakai|westmonroe|express|trulieve}"
        return 1
    fi

    # Switch cloud context
    cloud-switch "$1"

    # Switch TF workspace if in a TF directory
    if [ -f "main.tf" ] || [ -f "terraform.tf" ]; then
        terraform workspace select "$1" 2>/dev/null || terraform workspace new "$1"
    fi
}

alias tfs='tf-switch'
alias tfstat='tf-status'
