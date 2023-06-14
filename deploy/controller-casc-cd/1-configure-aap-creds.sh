#!/bin/bash 
set -xe 
# https://automationiberia.github.io/controller-casc-cd/controller-casc-cd/021-initial-dir-and-files.html#_pre_requisites

if [ ! -d $HOME/controller-casc-cd ]; then
  echo "$HOME/controller-casc-cd not found"
  exit 1
fi 

export CONTROLLER_DEV_HOST=https://controller-ansible-automation-platform.apps.cluster-kz6tk.example.com/
export CONTROLLER_PRO_HOST=https://controller-ansible-automation-platform.apps.cluster-kz6tk..example.com/

cd $HOME/controller-casc-cd 

cat > inventory <<EOF
[dev]
${CONTROLLER_DEV_HOST}

[pro]
${CONTROLLER_PRO_HOST}
EOF

export SUPERADMIN_ORG=rhel-edge-cac

mkdir -p group_vars/{all,dev,pro}

mkdir -p orgs_vars/${SUPERADMIN_ORG}/env/{dev,pro}/controller_{instance_groups.d,hosts.d/app-casc,users.d,execution_environments.d/app-casc,settings.d/jobs,settings.d/user_interface,settings.d/authentication,settings.d/system,inventory_sources.d,credentials.d}
touch orgs_vars/${SUPERADMIN_ORG}/env/{dev,pro}/controller_{instance_groups.d,hosts.d/app-casc,users.d,execution_environments.d/app-casc,settings.d/jobs,settings.d/user_interface,settings.d/authentication,settings.d/system,inventory_sources.d,credentials.d}/.gitkeep

mkdir -p orgs_vars/${SUPERADMIN_ORG}/env/common/controller_{schedules.d/app-casc,workflow_job_templates.d/app-casc,job_templates.d/app-casc,job_templates.d/app-gitlab,projects.d/app-casc,projects.d/app-gitlab,teams.d,credential_types.d/app-casc,roles.d,inventories.d/app-casc,organizations.d/app-casc,credentials.d,groups.d/app-casc}
touch orgs_vars/${SUPERADMIN_ORG}/env/common/controller_{schedules.d/app-casc,workflow_job_templates.d/app-casc,job_templates.d/app-casc,job_templates.d/app-gitlab,projects.d/app-casc,projects.d/app-gitlab,teams.d,credential_types.d/app-casc,roles.d,inventories.d/app-casc,organizations.d/app-casc,credentials.d,groups.d/app-casc}/.gitkeep

cat > group_vars/all/configure_connection_controller_credentials.yml <<EOF
---
vault_controller_username: 'admin'
vault_controller_validate_certs: false
...
EOF

read -e -s -p ">>> Enter admin password for DEV environment? " ADMIN_DEV_PASSWORD
cat > group_vars/dev/configure_connection_controller_credentials.yml <<EOF
---
vault_controller_password: '${ADMIN_DEV_PASSWORD}'
vault_controller_hostname: "{{ groups['dev'][0] }}"
...
EOF

read -e -s -p ">>> Enter admin password for PRO environment? " ADMIN_PRO_PASSWORD
cat > group_vars/pro/configure_connection_controller_credentials.yml <<EOF
---
vault_controller_password: '${ADMIN_PRO_PASSWORD}'
vault_controller_hostname: "{{ groups['pro'][0] }}"
...
EOF

ansible-vault encrypt \
  group_vars/dev/configure_connection_controller_credentials.yml \
  group_vars/pro/configure_connection_controller_credentials.yml