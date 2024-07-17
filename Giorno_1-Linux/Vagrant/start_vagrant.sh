#!/bin/bash

# set -euxo pipefail

HEAD()
{
    echo -e "Define Vagrant installation session and start vms' deploy"
    echo -e "the machines are reachable through the NATted NICS at 10.0.2.5 as:"
    echo -e "gateway :      127.0.0.1:2251"
    echo -e "               public nic ( based on your dhcp )"
    echo -e "               private nic 10.0.0.15"
    echo -e "controlplane:  127.0.0.1:2231"
    echo -e "               private nic 10.0.0.10"
    echo -e "node01:        127.0.0.1:2241"
    echo -e "               private nic 10.0.0.11"
    echo -e "node02:        127.0.0.1:2242"
    echo -e "               private nic 10.0.0.12"
}

SHOWHELP()
{
        echo 'Usage: start_vagrant.sh [OPTIONS]'
        echo 'OPTIONS:'
        echo '-k | --k8s | deploys a 3 node Kubernetes cluster'
        echo '           | with a fourth gateway vm'
        echo '-d | --def | deploys 4 machines'
        echo '           | without specific configuration'
}

K8S()
{
    rm -f ./$FILE
    cp ./$FILE.conf ./$FILE
    sed -i '/\#DEF/d' $FILE
    sed -i 's/#K8S//g' $FILE
    echo -e "\nNow you can run --> vagrant up <--\n"
}

DEF()
{
    rm -f ./$FILE
    cp ./$FILE.conf ./$FILE
    sed -i '/\#K8S/d' $FILE
    sed -i 's/#DEF//g' $FILE
    echo -e "\nNow you can run --> vagrant up <--\n"
}


FILE=Vagrantfile

while [ $1 ]; do
        case $1 in
                '-h' | '--help' | '?' )
                        HEAD
                        SHOWHELP
                        exit 0
                        ;;
                '--def' | '-d' )
                        DEF
                        exit 0
                        ;;
                '--k8s' | '-k' )
                        K8S
                        exit 0
                        ;;
                * )
                        HEAD
                        SHOWHELP
                        exit 0
                        ;;
        esac
        shift
done

HEAD

echo "Now you can run --> vagrant up <--"