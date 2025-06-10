#!/bin/bash

# Database configuration script for Django project

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display menu and get selection
select_option() {
    local options=("$@")
    local selected=0
    local count=${#options[@]}

    while true; do
        clear
        echo -e "${BLUE}Select an option:${NC}"
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "${GREEN}➤ ${options[$i]}${NC}"
            else
                echo "  ${options[$i]}"
            fi
        done

        read -rsn1 key
        case "$key" in
            $'\x1b') # ESC
                read -rsn2 -t 0.1 key
                case "$key" in
                    '[A') selected=$(( (selected - 1 + count) % count )) ;;
                    '[B') selected=$(( (selected + 1) % count )) ;;
                esac
                ;;
            $'\x0a') # Enter
                return $selected
                ;;
            'q') exit 0 ;;
        esac
    done
}

# Function to select file with fzf
select_file() {
    local prompt=$1
    local default_dir=$2
    local file_pattern=$3
    
    echo -e "${YELLOW}$prompt${NC}"
    selected_file=$(find "$default_dir" -type f -name "$file_pattern" | fzf --height 40% --reverse --prompt="Select file: ")
    
    if [ -z "$selected_file" ]; then
        echo -e "${RED}No file selected. Exiting.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Selected: $selected_file${NC}"
    echo $selected_file
}

# Function to update database configuration
update_db_config() {
    local env_file=$1
    local env_name=$2
    
    echo -e "${YELLOW}Updating database configuration for $env_name environment...${NC}"
    
    # Get current DB config
    current_db_name=$(grep -oP 'DB_NAME=\K[^ ]+' $env_file)
    current_db_user=$(grep -oP 'DB_USER=\K[^ ]+' $env_file)
    current_db_pass=$(grep -oP 'DB_PASSWORD=\K[^ ]+' $env_file)
    current_db_host=$(grep -oP 'DB_HOST=\K[^ ]+' $env_file)
    current_db_port=$(grep -oP 'DB_PORT=\K[^ ]+' $env_file)
    
    echo -e "${BLUE}Current configuration:${NC}"
    echo "DB_NAME: $current_db_name"
    echo "DB_USER: $current_db_user"
    echo "DB_PASSWORD: [hidden]"
    echo "DB_HOST: $current_db_host"
    echo "DB_PORT: $current_db_port"
    
    # Get new values
    read -p "Enter new DB name [$current_db_name]: " db_name
    db_name=${db_name:-$current_db_name}
    
    read -p "Enter new DB user [$current_db_user]: " db_user
    db_user=${db_user:-$current_db_user}
    
    read -s -p "Enter new DB password (leave empty to keep current): " db_pass
    echo
    db_pass=${db_pass:-$current_db_pass}
    
    read -p "Enter new DB host [$current_db_host]: " db_host
    db_host=${db_host:-$current_db_host}
    
    read -p "Enter new DB port [$current_db_port]: " db_port
    db_port=${db_port:-$current_db_port}
    
    # Update the file
    sed -i "s/DB_NAME=.*/DB_NAME=$db_name/" $env_file
    sed -i "s/DB_USER=.*/DB_USER=$db_user/" $env_file
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$db_pass/" $env_file
    sed -i "s/DB_HOST=.*/DB_HOST=$db_host/" $env_file
    sed -i "s/DB_PORT=.*/DB_PORT=$db_port/" $env_file
    
    echo -e "${GREEN}Database configuration updated successfully!${NC}"
}

# Function to update API configuration in database
update_api_config() {
    local env_name=$1
    
    echo -e "${YELLOW}Updating API configuration for $env_name environment in database...${NC}"
    
    # Check if psql is available
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}PostgreSQL client (psql) is not installed. Cannot update database.${NC}"
        return 1
    fi
    
    # Get DB credentials from .env
    source $selected_env_file
    
    # Connect to DB and update config
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
    INSERT INTO configuraciones_api (entorno, nombre, valor, descripcion, activo)
    VALUES ('$env_name', 'environment', '$env_name', 'Current environment', true)
    ON CONFLICT (nombre, entorno) 
    DO UPDATE SET valor = '$env_name', descripcion = 'Current environment', activo = true;
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}API configuration updated successfully in database!${NC}"
    else
        echo -e "${RED}Failed to update API configuration in database.${NC}"
    fi
}

# Main script
main() {
    # Check if fzf is installed
    if ! command -v fzf &> /dev/null; then
        echo -e "${RED}fzf is not installed. Please install it first.${NC}"
        echo "On Ubuntu/Debian: sudo apt install fzf"
        echo "On macOS: brew install fzf"
        exit 1
    fi
    
    # Select .env file
    selected_env_file=$(select_file "Select your .env file:" "." ".env*")
    
    # Select environment
    environments=("production" "sandbox" "local")
    select_option "${environments[@]}"
    selected_env=${environments[$?]}
    
    # Menu options
    options=(
        "Update database configuration"
        "Update API configuration in database"
        "Both (update DB config and API config)"
        "Exit"
    )
    
    select_option "${options[@]}"
    selected_option=$?
    
    case $selected_option in
        0) # Update DB config
            update_db_config $selected_env_file $selected_env
            ;;
        1) # Update API config
            update_api_config $selected_env
            ;;
        2) # Both
            update_db_config $selected_env_file $selected_env
            update_api_config $selected_env
            ;;
        3) # Exit
            exit 0
            ;;
    esac
    
    echo -e "${GREEN}Operation completed successfully!${NC}"
}

# Run main function
main