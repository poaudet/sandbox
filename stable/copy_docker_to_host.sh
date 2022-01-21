#/bin/bash
if [ "$1" == "-h" ] ; 
    then
    echo "Usage: bash `basename $0` [-h] [ARGS]"
    echo "Copy files and folders from docker container to host"
    echo "First argument is the name of the container (e.g. busybox_container)"
    echo "Second argument is the container path you want to copy (e.g. /config or /data)"
    echo "Third argument is the host path where you want to copy (e.g. ~/docker-volumes or /mnt/sda)"
    echo "Fourth argument is 'docker cp' additionnals options. See 'docker cp --help'"
    exit 0
    else
    echo "List of files in $2"
    docker exec $1 ls -a $2
    echo "Starting Busybox container with name 'copy-busybox'"
    docker run -d --name=copy-busybox --volumes-from $1 busybox true
    echo "Executing docker cp $4 copy-busybox:$2 $3..."
    docker cp $4 copy-busybox:$2 $3
    echo "Removing container"
    docker rm copy-busybox
    echo "Files copied:"
    ls -a $3
fi