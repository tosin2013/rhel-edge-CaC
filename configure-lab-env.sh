#!/bin/bash 

function waitforme() {
  while [[ $(oc get pods $1 -n $2 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod: $1" && sleep 5; done
}


function dependency_check() {
    if ! yq -v  &> /dev/null
    then
        VERSION=v4.30.6
        BINARY=yq_linux_amd64
        sudo wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq &&\
        sudo chmod +x /usr/bin/yq
    fi

    if ! yq -v  &> /dev/null
    then
        echo "installing helm"
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
   fi

}



oc apply -k deploy/bootstrap/operators/
oc label ns/openshift-authentication argocd.argoproj.io/managed-by=openshift-gitops
oc label ns/openshift-config argocd.argoproj.io/managed-by=openshift-gitops

# Get the current phase of the CSV
phase=$(oc get csv -n openshift-gitops | grep Succeeded | awk '{print $8}')

# While the phase is not Succeeded, sleep for 10 seconds and then get the phase again
while [[ $phase != "Succeeded" ]]; do
  sleep 10
  phase=$(oc get csv -n openshift-gitops | grep Succeeded | awk '{print $8}')
done

# Print a message when the phase is Succeeded
echo "CSV succeeded!"
GITOPS_POD=$(oc get pods -n openshift-gitops | grep openshift-gitops-server- | awk '{print $1}')
waitforme $GITOPS_POD openshift-gitops 

oc apply -f deploy/lab-content/apps/


phase=$(oc get csv -n  devspaces-lab-sso |grep rhsso-operator | grep Succeeded | awk '{print $9}')
# While the phase is not Succeeded, sleep for 10 seconds and then get the phase again
while [[ $phase != "Succeeded" ]]; do
  sleep 10
  phase=$(oc get csv -n  devspaces-lab-sso |grep rhsso-operator | grep Succeeded | awk '{print $9}')
done

# Print a message when the phase is Succeeded
echo "CSV succeeded!"

SSO_POD=$(oc get pods -n devspaces-lab-sso  | grep keycloak-0 | awk '{print $1}')
waitforme $SSO_POD devspaces-lab-sso 

KEYCLAK_URL=$(oc get routes -n devspaces-lab-sso | grep keycloak-devspaces-lab-sso | head -1 | awk '{print $2}')
# Extracting the desired subdomain using regular expressions and "grep"
SUBDOMAIN=$(echo "$KEYCLAK_URL" | grep -oP '(?<=keycloak-devspaces-lab-sso\.)(.*)')

echo "$SUBDOMAIN"
yq e  '.gitlab.route = "'gitlab.$SUBDOMAIN'"' deploy/lab-content/gitlab/values.yaml
yq e  '.gitlab.sso.host = "'https://$KEYCLAK_URL'"' deploy/lab-content/gitlab/values.yaml