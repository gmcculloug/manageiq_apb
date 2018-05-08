INITIAL_DIR=$PWD
MINISHIFT_CONFIG_DIR=$(dirname $0)

minishift addons remove ansible-service-broker
minishift addons uninstall ansible-service-broker
minishift delete

minishift config set memory 4096
minishift config set cpus 4
minishift config set disk-size 40g

minishift config set openshift-version v3.9.0
export MINISHIFT_ENABLE_EXPERIMENTAL=y
minishift config set iso-url centos
minishift start --vm-driver=virtualbox --extra-clusterup-flags "--service-catalog"
# minishift start --extra-clusterup-flags "--service-catalog"

oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin developer
oc login -u developer -p smartvm

eval $(minishift docker-env)
printenv DOCKER_HOST
eval $(minishift oc-env)
docker login 172.30.1.1:5000 -u unused -p $(oc whoami -t)

oc create -f "$(dirname "$0")/projects"
minishift console
printenv DOCKER_HOST

cd $MINISHIFT_CONFIG_DIR
git clone https://github.com/eriknelson/minishift-addons
cd minishift-addons
git checkout add-dashboard-url
cd ../..

minishift addons install "$MINISHIFT_CONFIG_DIR/minishift-addons/add-ons/ansible-service-broker/"
sleep 10
minishift addons apply ansible-service-broker
# minishift addons enable ansible-service-broker

echo "Wait for Ansible Service Broker to start then press the Enter Key to continue installing APBs"
read

cd "$MINISHIFT_CONFIG_DIR/../lamp-stack-apb"
apb push

cd "$MINISHIFT_CONFIG_DIR/../hadoop-cluster-apb"
apb push

cd "$MINISHIFT_CONFIG_DIR/../centos7-satellite-apb hadoop-cluster-apb"
apb push

# oc label user/developer permissions=Requires-Approval
# oc label namespace myproject permissions=Requires-Approval
# oc describe namespace myproject
# oc edit oauthclient openshift-web-console

printenv DOCKER_HOST
cd $INITIAL_DIR
