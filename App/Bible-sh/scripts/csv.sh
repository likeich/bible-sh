#!/bin/sh

add_entry() {
    local csv_file="$1"
    local key="$2"
    local value="$3"

    # Create a temporary file
    local temp_file="$csv_file.tmp"

    # Check if the key already exists
    if grep -q "^$key," "$csv_file"; then
        # The key exists, so replace the line
        # Rewrite the file, changing the line that matches the key
        while IFS= read -r line; do
            if [[ "$line" =~ ^$key, ]]; then
                echo "$key,$value" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        done < "$csv_file"

        # Overwrite the original file with the temporary file
        mv "$temp_file" "$csv_file"
    else
        # The key does not exist, add new key-value pair
        echo "$key,$value" >> "$csv_file"
    fi
}

get_value() {
    local csv_file="$1"
    local key="$2"
    local line=$(grep "^$key," "$csv_file")
    if [ -z "$line" ]; then
        echo "Error: Key '$key' not found."
        return 1
    else
        # Extract and print the value
        local value=$(echo "$line" | cut -d ',' -f 2)
        echo $value
    fi
}

list_entries() {
    local csv_file="$1"
    echo "All entries in CSV:"
    cat "$csv_file"
}

main() {
    local csv_file="$1"
    local command="$2"

    if [ ! -f "$csv_file" ]; then
        touch "$csv_file" 2>/dev/null
    fi

    case "$command" in
        add)
            add_entry "$csv_file" "$3" "$4"
            ;;
        get)
            get_value "$csv_file" "$3"
            ;;
        list)
            list_entries "$csv_file"
            ;;
        *)
            return 1
            ;;
    esac
}

main "$@"
