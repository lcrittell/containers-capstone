#!/bin/bash

set -uo pipefail

# Locate the project root
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Locate the automation scripts
SCRIPTS_DIR="$PROJECT_DIR/scripts"

# Run a selected script and report its result
run_script() {
    local script_name="$1"
    shift

    local script_path="$SCRIPTS_DIR/$script_name"

    echo ""
    echo "=================================="
    echo "Running: $script_name"
    echo "=================================="

    if [[ ! -f "$script_path" ]]; then
        echo "[ERROR] Script not found: $script_path"
    elif "$script_path" "$@"; then
        echo ""
        echo "[SUCCESS] $script_name completed."
    else
        local exit_code=$?
        echo ""
        echo "[ERROR] $script_name failed (exit code: $exit_code)."
    fi

    echo ""
    read -rp "Press Enter to return to the menu..."
}

# Display the main menu
show_menu() {
    clear

    echo "=================================="
    echo "     CONTAINERS CAPSTONE"
    echo "       MANAGEMENT MENU"
    echo "=================================="
    echo ""
    echo "  DOCKER (requires sudo)"
    echo "  1. Build Docker Image"
    echo "  2. Deploy Application"
    echo "  3. Validate Deployment"
    echo "  4. Cleanup Deployment"
    echo ""
    echo "  REGISTRY"
    echo "  5. Publish Image to Quay"
    echo ""
    echo "  PODMAN"
    echo "  6. Build Podman Image"
    echo "  7. Deploy Podman Application"
    echo "  8. Validate Podman Deployment"
    echo "  9. Cleanup Podman Deployment"
    echo ""
    echo "  10. Exit"
    echo ""
    echo "=================================="
}

# Main menu loop
while true; do
    show_menu

    if ! read -rp "Select an option: " choice; then
        echo ""
        echo "Exiting..."
        exit 0
    fi

    case "$choice" in
        1)
            read -rp "Enter image version [1.0.0]: " version
            version="${version:-1.0.0}"
            run_script "build.sh" "$version"
            ;;
        2)
            run_script "deploy.sh"
            ;;
        3)
            run_script "validate.sh"
            ;;
        4)
            run_script "cleanup.sh"
            ;;
        5)
            read -rp "Enter image version to publish [1.0.0]: " version
            version="${version:-1.0.0}"
            run_script "publish.sh" "$version"
            ;;
        6)
            read -rp "Enter image version [1.0.0]: " version
            version="${version:-1.0.0}"
            run_script "podman-build.sh" "$version"
            ;;
        7)
            read -rp "Enter image version to deploy [1.0.0] " version
            version="${version:-1.0.0}"
            run_script "podman-deploy.sh" "$version"
            ;;
        8)
            run_script "podman-validate.sh"
            ;;
        9)
            run_script "podman-cleanup.sh"
            ;;
        10)
            echo ""
            echo "Exiting Containers Capstone Manager."
            exit 0
            ;;
        *)
            echo ""
            echo "[ERROR] Invalid selection."
            read -rp "Press Enter to try again..."
            ;;
    esac
done
