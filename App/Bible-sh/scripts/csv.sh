#!/bin/sh

add_entry() {
    local csv_file="$1"
    local key="$2"
    local value="$3"
    # Check if the key already exists
    if grep -q "^$key," "$csv_file"; then
        echo "Error: Key '$key' already exists."
        return 1
    else
        # Add new key-value pair
        echo "$key,$value" >> "$csv_file"
        echo "Entry added: $key, $value"
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
        echo "Value for '$key': $value"
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
        touch "$csv_file"
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
            echo "Usage: $0 <csv_file> {add <key> <value>|get <key>|list}"
            return 1
            ;;
    esac
}

main "$@"
