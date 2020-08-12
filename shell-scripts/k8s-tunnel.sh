#!/bin/bash

service_host="prod-ds-machine-learning.cubaneddie.k8s.clicktripz.io"
port="8888"
key_file=~/.ssh/id_rsa

usage ()
{
    printf -- "\n"
    printf -- "Usage: \n"
    printf -- "  $0 [OPTIONS]\n\n"
    printf -- "Setup a SSH channel to k8s service\n\n"
    printf -- "Options:\n"
    printf -- "  -u, --user string       specify <user>@<host> to log in as on the remote machine\n"
    printf -- "  -s, --service hostname  the hostname of k8s service (default: %s)\n" ${service_host}
    printf -- "  -p, --port number       the local port for the SSH tunnel (default: %s)\n" ${port}
    printf -- "  -k, --key filename      specify a file from which the identity for public key authentication is read (default: %s)\n" ${key_file}
    printf -- "  -h, --help              show help\n"
    printf -- "\n"
    exit 1
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
      usage
    ;;
    -u|--user)
    user="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--service)
    service_host="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--port)
    port="$2"
    shift # past argument
    shift # past value
    ;;
    -k|--key)
    key_file="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $user == "" ]]
then
  usage
fi

ssh -i ${key_file} -L ${port}:${service_host}:443 ${user}
