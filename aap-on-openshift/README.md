https://developers.redhat.com/articles/2023/05/30/build-edge-manager-single-node-openshift?sc_cid=7013a000003Sa2FAAS#creating_a_pipeline_to_build_device_edge_images


# temp solution 
cat >extra_vars.yaml <<EOF
vm_template_password: temppassword
kubeadmin-username: admin 
kubeadmin-password: temppassword
rhsm_username: your username
rhsm_password: your password
image_username: your username
image_password: your password
inventory_hostname: localhost
EOF

ansible-playbook configure-controller.yml -e @extra_vars.yaml