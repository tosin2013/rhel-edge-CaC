#!/bin/bash

if [ ! -d ${HOME}/controller-casc-cd ]; then
  git clone https://github.com/tosin2013/superadmin-workshop-template.git ${HOME}/controller-casc-cd

fi

cd ${HOME}/controller-casc-cd
git remote remove origin
git config --global user.name "Lab One"
git config --global user.email "lab1@example.com"
git remote add origin https://gitlab.apps.cluster-ss575.ss575.sandbox3178.opentlc.com/lab1/controller-casc-cd.git

cat > .gitignore <<EOF
collections/ansible_collections
users.csv
users_old.csv
.vault*
*artifact*
ansible-navigator.log
.*.swp
inventory_bastions
list
p.yml
id_rsa*
venv
EOF

cat > .yamllint.yml <<EOF
---
extends: default

ignore: |
  changelogs
  group_vars/*/configure_connection_controller_credentials.yml
  group_vars/*/vault
  orgs_vars/*/env/*/controller_credentials.d/
  orgs_vars/*/env/*/controller_users.d/
  orgs_vars/*/env/*/controller_settings.d/authentication/controller_settings_ldap.yml

yaml-files:
  - '*.yaml'
  - '*.yml'

rules:
  # 80 chars should be enough, but don't fail if a line is longer
  line-length: disable
  comments:
    require-starting-space: true
    ignore-shebangs: true
    min-spaces-from-content: 2
  commas:
    max-spaces-before: 0
    min-spaces-after: 1
    max-spaces-after: 1
  colons:
    max-spaces-before: 0
    max-spaces-after: -1
  document-end: {present: true}
  indentation:
    level: error
    indent-sequences: consistent
  truthy:
    level: error
    allowed-values:
      - 'True'
      - 'False'
      - 'true'
      - 'false'
      - 'on'
...
EOF

cat > .gitlab-ci.yml <<'EOF'
---
stages:
  - lint
  - prepare
  - release

yamllint:
  stage: lint
  image: quay.io/automationiberia/aap/ee-casc:latest
  tags:
    - casc
    - controller-group
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never
    - if: '$CI_COMMIT_BRANCH'
  script:
    - yamllint -c ./.yamllint.yml .

generate_tag:
  stage: prepare
  image: registry.gitlab.com/gitlab-org/release-cli
  tags:
    - casc
    - controller-group
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /First Commit/
      when: never
    - if: $CI_COMMIT_TAG
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      exists:
        - VERSION
      changes:
        - VERSION
  script:
    - echo "TAG=$(cat VERSION)" > tag.env
  artifacts:
    reports:
      dotenv: tag.env

auto-release-master:
  image: registry.gitlab.com/gitlab-org/release-cli
  tags:
    - casc
    - controller-group
  needs:
    - job: generate_tag
      artifacts: true
  stage: release
  rules:
    - if: $CI_COMMIT_TAG
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      exists:
        - VERSION
      changes:
        - VERSION
  script:
    - echo "Release $TAG"
  release:
    name: "Release $TAG"
    description: "Created using the release-cli $EXTRA_DESCRIPTION"
    tag_name: v$TAG
    ref: $CI_COMMIT_SHA
...
EOF

git add .
git commit -m "Initial commit"
git push -u origin main