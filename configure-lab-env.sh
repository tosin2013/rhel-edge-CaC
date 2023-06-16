#!/bin/bash 


function wait_for_pod() {
  local pod_name=$1
  local namespace=$2

  while [[ $(oc get pods "$pod_name" -n "$namespace" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
    echo "Waiting for pod: $pod_name"
    sleep 5
  done
}


function dependency_check() {
    if ! yq -v  &> /dev/null
    then
        VERSION=v4.30.6
        BINARY=yq_linux_amd64
        sudo wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq &&\
        sudo chmod +x /usr/bin/yq
    fi

    if ! helm -v  &> /dev/null
    then
        echo "installing helm"
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
   fi

}

dependency_check

CHECK_IF_RUNNING=$(oc get pods -n openshift-gitops | grep openshift-gitops-server- | awk '{print $3}')
if [[ "$CHECK_IF_RUNNING" = "Running" ]]; then
  echo "OpenShift GitOps is already running"
else
  oc apply -k deploy/bootstrap/operators/
  oc label ns/openshift-authentication argocd.argoproj.io/managed-by=openshift-gitops
  oc label ns/openshift-config argocd.argoproj.io/managed-by=openshift-gitops
fi 

# Get the current phase of the CSV
phase=$(oc get csv -n openshift-gitops  | grep openshift-gitops-operator | grep Succeeded | awk '{print $8}')

# While the phase is not Succeeded, sleep for 10 seconds and then get the phase again
while [[ $phase != "Succeeded" ]]; do
  sleep 10
  phase=$(oc get csv -n openshift-gitops  | grep openshift-gitops-operator  | grep Succeeded | awk '{print $8}')
done

# Print a message when the phase is Succeeded
echo "openshift-gitops-operator CSV succeeded!"
GITOPS_POD=$(oc get pods -n openshift-gitops | grep openshift-gitops-server- | awk '{print $1}')
wait_for_pod $GITOPS_POD openshift-gitops 

oc apply -f deploy/lab-content/apps/


phase=$(oc get csv -n  devspaces-lab-sso |grep rhsso-operator | grep Succeeded | awk '{print $9}')
# While the phase is not Succeeded, sleep for 10 seconds and then get the phase again
while [[ $phase != "Succeeded" ]]; do
  sleep 10
  phase=$(oc get csv -n  devspaces-lab-sso |grep rhsso-operator | grep Succeeded | awk '{print $9}')
done

# Print a message when the phase is Succeeded
echo "rhsso-operator CSV succeeded!"

sleep 30s
SSO_POD=$(oc get pods -n devspaces-lab-sso  | grep keycloak-0 | awk '{print $1}')
wait_for_pod $SSO_POD devspaces-lab-sso 

KEYCLAK_URL=$(oc get routes -n devspaces-lab-sso | grep keycloak-devspaces-lab-sso | head -1 | awk '{print $2}')
# Extracting the desired subdomain using regular expressions and "grep"
SUBDOMAIN=$(echo "$KEYCLAK_URL" | grep -oP '(?<=keycloak-devspaces-lab-sso\.)(.*)')

echo "$SUBDOMAIN"
yq e -i  '.gitlab.route = "'gitlab.$SUBDOMAIN'"' deploy/lab-content/gitlab/values.yaml
yq e -i '.gitlab.sso.host = "'https://$KEYCLAK_URL'"' deploy/lab-content/gitlab/values.yaml

helm template deploy/lab-content/gitlab | oc apply -f -
sleep 30s
GITLAB_POD=$(oc get pods -n gitlab-ce  | grep gitlab-ce- | awk '{print $1}')
wait_for_pod $GITLAB_POD gitlab-ce