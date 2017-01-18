# This is the installation script for Cisco Unified Container Networking platform.

. ./install/ansible/install_defaults.sh

# Ansible options. By default, this specifies a private key to be used and the vagrant user
def_ans_opts="--private-key $def_ans_key -u vagrant"
    
usage() {
  echo "Usage:"
  echo "./uninstall_swarm.sh -f <host configuration file> -n <netmaster IP> -a <ansible options> -e <ansible key> -i <uninstall scheduler stack> -z <installer config file>"

  echo ""
  exit 1
}

mkdir -p $src_conf_path
uninstall_scheduler=""
while getopts ":f:z:n:a:e:i" opt; do
  case $opt in
    f)
      cp $OPTARG $host_contiv_config
      ;;
    z)
      cp $OPTARG $host_installer_config
      ;;
    n)
      netmaster=$OPTARG
      ;;
    a)
      ans_opts=$OPTARG
      ;;
    e)
      ans_key=$OPTARG
      ;;
    i) 
      echo "Uninstalling docker will fail if the uninstallation is being run from a node in the cluster."
      echo "Press Ctrl+C to cancel the uininstall and start it from a host outside the cluster."
      echo "Uninstalling Contiv, Docker and Swarm in 20 seconds"
      sleep 20
      uninstall_scheduler="-i"
      ;;
    :)
      echo "An argument required for $OPTARG was not passed"
      usage
      ;;
    ?)
      usage
      ;;
  esac
done

if [[ ! -f $host_contiv_config ]]; then
	echo "Host configuration file missing"
  usage
fi

if [[ ! -f $host_installer_config ]]; then
	touch $host_installer_config
  echo "Created host_installer_config"
fi

if [[ "$netmaster" = ""  ]]; then
	echo "Netmaster IP/name is missing"
  usage
fi

if [[ "$ans_opts" = "" ]]; then
	echo "Attempting to install with default Ansible SSH options $def_ans_opts"
  ans_opts=$def_ans_opts
fi

if [[ -f $ans_key ]]; then
  cp $ans_key $host_ans_key
  ans_opts="$ans_opts --private-key $def_ans_key "
fi

# Copy the proxy container image to the host share path
cp ucn-proxy-image.tar $src_conf_path

echo "Starting the ansible container"
docker run --rm -v $src_conf_path:$container_conf_path contiv/install:devbuild sh -c "./install/ansible/uninstall.sh -n $netmaster -a \"$ans_opts\" $uninstall_scheduler"
rm -rf $src_conf_path
