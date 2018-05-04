minishift delete
minishift config set memory 4096
minishift config set cpus 4
minishift config set disk-size 40g

minishift config set openshift-version v3.9.0
export MINISHIFT_ENABLE_EXPERIMENTAL=y
minishift config set iso-url centos
minishift start --vm-driver=virtualbox --extra-clusterup-flags "--service-catalog"
# minishift start --extra-clusterup-flags "--service-catalog"

eval $(minishift docker-env)
eval $(minishift oc-env)
docker login 172.30.1.1:5000 -u unused -p $(oc whoami -t)

minishift addons uninstall ansible-service-broker
minishift addons install ~/work/Summit/minishift-addons/add-ons/ansible-service-broker/
sleep 10
minishift addons apply ansible-service-broker

oc create -f "$(dirname "$0")/projects/myproject"

# oc login -u system:admin
# oc label namespace myproject permissions=Requires-Approval
# oc describe namespace myproject
# oc edit oauthclient openshift-web-console
# oc login -u developer -p dev

minishift console
