#!/usr/bin/env bash

# Initialize variables
remove_env_file=true
skip_bitwarden=false

# Define the options using getopt
OPTIONS=$(getopt -o k,s --long keep-env,skip-bitwarden -n "$0" -- "$@")
if [ $? -ne 0 ]; then
    echo "Usage: $0 [--keep-env] [--skip-bitwarden] path_to_env_file"
    exit 1
fi

# Parse the options
eval set -- "$OPTIONS"
while true; do
    case "$1" in
        -k | --keep-env)
            remove_env_file=false
            shift
            ;;
        -s | --skip-bitwarden)
            skip_bitwarden=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done

# Check if an env file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [--keep-env] [--skip-bitwarden] path_to_env_file"
    exit 1
fi

env_file="$1"

if [ ! -f "$env_file" ]; then
    echo "Provided env file does not exist"
    exit 1
fi