#!/usr/bin/env bash
# ============================================================
# NexGen Cloud Platform (NCP)
# Manifest Parser Engine
# ============================================================

set -euo pipefail

# Parse a YAML manifest file and set shell variables prefixing them
# Usage: parse_manifest <file_path> [prefix]
parse_manifest() {
    local yaml_file="$1"
    local prefix="${2:-NCP_MANIFEST_}"

    if [ ! -f "$yaml_file" ]; then
        echo "Error: Manifest file not found at $yaml_file" >&2
        return 1
    fi

    local line
    local -a keys
    local indent_size=2
    
    local in_block=0
    local block_key=""
    local block_indent_len=0
    local block_type="" # folded '>' or literal '|'
    local block_content=""

    # Track active list object to support parsing lists of objects (like dependencies)
    local active_list_object_prefix=""
    local active_list_indent_level=0

    while IFS= read -r line || [ -n "$line" ]; do
        # If we are in block mode, check indentation
        if [ $in_block -eq 1 ]; then
            # If line is empty or purely whitespace, just append newline
            if [[ "$line" =~ ^[[:space:]]*$ ]]; then
                block_content="$block_content"$'\n'
                continue
            fi
            
            # Check indentation
            local current_indent=""
            if [[ "$line" =~ ^([[:space:]]+) ]]; then
                current_indent="${BASH_REMATCH[1]}"
            fi
            
            if [ ${#current_indent} -le $block_indent_len ]; then
                # End of block mode! Save the block content, reset, and fall through to process this line.
                # Strip trailing whitespace and newlines from block_content
                block_content=$(echo "$block_content" | sed -e 's/[[:space:]]*$//')
                if [ "$block_type" = ">" ]; then
                    # Replace newlines with space, squeeze spaces, and strip leading/trailing whitespace
                    block_content=$(echo "$block_content" | tr '\n' ' ' | tr -s ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                fi
                eval "${prefix}${block_key}=\"\$block_content\""
                in_block=0
                block_content=""
            else
                # Still in block mode!
                local content_line="${line:$((block_indent_len + 2))}"
                if [ -z "$block_content" ]; then
                    block_content="$content_line"
                else
                    block_content="$block_content"$'\n'"$content_line"
                fi
                continue
            fi
        fi

        # Ignore comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        # Calculate indentation
        local indent=""
        if [[ "$line" =~ ^([[:space:]]+) ]]; then
            indent="${BASH_REMATCH[1]}"
        fi
        local level=$((${#indent} / indent_size))
        
        # Trim whitespace
        local trimmed=$(echo "$line" | xargs)
        
        # Case 1: List item starting with '- '
        if [[ "$trimmed" =~ ^-[[:space:]]*(.*) ]]; then
            local val="${BASH_REMATCH[1]}"
            val=$(echo "$val" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            
            # Determine list parent key
            local parent_key=""
            local i
            for ((i=0; i<level; i++)); do
                if [ -n "${keys[i]:-}" ]; then
                    if [ -z "$parent_key" ]; then
                        parent_key="${keys[i]}"
                    else
                        parent_key="${parent_key}_${keys[i]}"
                    fi
                fi
            done
            
            if [ -n "$parent_key" ]; then
                local idx_var="${prefix}${parent_key}_count"
                local idx=0
                if [ -n "${!idx_var:-}" ]; then
                    idx=${!idx_var}
                fi
                
                # Check if it is a list of objects (like id: git) or a simple value
                if [[ "$val" =~ ^([a-zA-Z0-9_]+):[[:space:]]*(.*) ]]; then
                    local k="${BASH_REMATCH[1]}"
                    local v="${BASH_REMATCH[2]}"
                    v=$(echo "$v" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
                    eval "${prefix}${parent_key}_${idx}_${k}=\"\$v\""
                    
                    # Set as active list object for subsequent fields of the same item
                    active_list_object_prefix="${parent_key}_${idx}"
                    active_list_indent_level=$level
                else
                    eval "${prefix}${parent_key}_${idx}=\"\$val\""
                    # Simple list item, reset active list object
                    active_list_object_prefix=""
                    active_list_indent_level=0
                fi
                eval "${prefix}${parent_key}_count=\$((idx + 1))"
            fi
            continue
        fi
        
        # Case 2: Key-value pair key: value
        if [[ "$trimmed" =~ ^([a-zA-Z0-9_]+):[[:space:]]*(.*) ]]; then
            local key="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"
            
            keys[level]="$key"
            local i
            for ((i=level+1; i<${#keys[@]}; i++)); do
                keys[i]=""
            done
            
            # If we are not deeper than the active list level, reset active list prefix
            if [ -n "$active_list_object_prefix" ] && [ $level -le $active_list_indent_level ]; then
                active_list_object_prefix=""
                active_list_indent_level=0
            fi

            local full_key=""
            if [ -n "$active_list_object_prefix" ] && [ $level -gt $active_list_indent_level ]; then
                full_key="${active_list_object_prefix}_${key}"
            else
                for ((i=0; i<=level; i++)); do
                    if [ -n "${keys[i]:-}" ]; then
                        if [ -z "$full_key" ]; then
                            full_key="${keys[i]}"
                        else
                            full_key="${full_key}_${keys[i]}"
                        fi
                    fi
                done
            fi
            
            if [ -n "$val" ]; then
                if [ "$val" = ">" ] || [ "$val" = "|" ]; then
                    in_block=1
                    block_key="$full_key"
                    block_indent_len=${#indent}
                    block_type="$val"
                    block_content=""
                else
                    val=$(echo "$val" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
                    eval "${prefix}${full_key}=\"\$val\""
                fi
            else
                # Empty value - could be a nested object or list starting. Clear any previous value of this key.
                eval "${prefix}${full_key}=\"\""
            fi
        fi
    done < "$yaml_file"

    # Handle if we finished the file but were still in a block
    if [ $in_block -eq 1 ]; then
        block_content=$(echo "$block_content" | sed -e 's/[[:space:]]*$//')
        if [ "$block_type" = ">" ]; then
            # Replace newlines with space, squeeze spaces, and strip leading/trailing whitespace
            block_content=$(echo "$block_content" | tr '\n' ' ' | tr -s ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        fi
        eval "${prefix}${block_key}=\"\$block_content\""
    fi
}

# Helper to clear parsed variables
clear_manifest_variables() {
    local prefix="${1:-NCP_MANIFEST_}"
    # Unset all variables starting with the prefix
    # In bash, we can use compgen to list matching variables
    local var
    for var in $(compgen -v "$prefix" 2>/dev/null || set | grep -o "^${prefix}[a-zA-Z0-9_]*" | sort -u); do
        unset "$var"
    done
}
