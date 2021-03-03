#!/bin/bash

function usage()
{
   printf -- "\n"
   cprintf w "Usage: \n"
   cprintf w "  $0 [OPTIONS]\n\n"
   printf -- "Execute a script for every line in a given file\n\n"
   printf -- "Options:\n"
   printf -- "  -f, --file file            %s\n" "the file with parameters"
   printf -- "  -d, --domain domains       %s\n" "publisher's comma-separated domains"
   printf -- "  -s, --session file         %s\n" "path to session file"
   printf -- "  -h, --help                 %s\n" "show help"
   printf -- "  -v, --verbose              %s\n" "verbose mode"
   printf -- "\nExample:\n"
   printf -- "      $0 -a nypost -d \"nypost.com,pagesix.com\" -s ~/pms_session.env\n"
   printf -- "\n"
   exit 1
}

function parse_args()
{
     unknown_args=()

    # Parse the command line parameters
    while [[ $# -gt 0 ]]
    do
        case $1 in
            -h|--help)
                usage
            ;;
            -v|--verbose)
                verbose="on"
            ;;
            -a|--alias)
                integration_group="$2"
                shift
            ;;
            -d|--domain)
                site_domains="$2"
                shift
            ;;
            -s|--session)
                session_file=$(abs_path $2)
                shift
            ;;
            *)
                unknown_args+=("$1") 
            ;;
        esac
        shift
    done
    set -- "${unknown_args[@]}"
}
