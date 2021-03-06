#!/bin/bash

#Remove latest as option
if grep -q latest deploy/olm-catalog/konveyor-operator/konveyor-operator.package.yaml; then
  sed -i 3,4d deploy/olm-catalog/konveyor-operator/konveyor-operator.package.yaml
fi
sed -i s,konveyor-operator,cam-operator,g deploy/olm-catalog/konveyor-operator/konveyor-operator.package.yaml
rm -rf deploy/olm-catalogstable deploy/olm-catalog/konveyor-operator/latest

if [ -d deploy/olm-catalog/konveyor-operator/v1.2.0 ]; then
  #Declare v1.2 image information
  V1_2_IMAGES=(
    "controller"
    "operator"
    "plugin"
    "ui"
    "velero"
    "helper"
    "gcpplugin"
    "awsplugin"
    "azureplugin"
    "registry"
    "mustgather"
    "hookrunner"
  )

  declare -A V1_2_IMG_MAP
  V1_2_IMG_MAP[controller_repo]="openshift-migration-controller"
  V1_2_IMG_MAP[operator_repo]="openshift-migration-operator"
  V1_2_IMG_MAP[plugin_repo]="openshift-migration-plugin"
  V1_2_IMG_MAP[ui_repo]="openshift-migration-ui"
  V1_2_IMG_MAP[velero_repo]="openshift-migration-velero"
  V1_2_IMG_MAP[helper_repo]="openshift-migration-velero-restic-restore-helper"
  V1_2_IMG_MAP[gcpplugin_repo]="openshift-migration-velero-plugin-for-gcp"
  V1_2_IMG_MAP[awsplugin_repo]="openshift-migration-velero-plugin-for-aws"
  V1_2_IMG_MAP[azureplugin_repo]="openshift-migration-velero-plugin-for-microsoft-azure"
  V1_2_IMG_MAP[registry_repo]="openshift-migration-registry"
  V1_2_IMG_MAP[mustgather_repo]="openshift-migration-must-gather"
  V1_2_IMG_MAP[hookrunner_repo]="openshift-migration-hook-runner"

  #Get latest 1.2 images
  for i in ${V1_2_IMAGES[@]}; do
    docker pull registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_2_IMG_MAP[${i}_repo]}:v1.2 > /dev/null
  done

  #oc mirror 1.2 images to get correct shas
  for i in ${V1_2_IMAGES[@]}; do
    V1_2_IMG_MAP[${i}_sha]=$(oc image mirror --dry-run=true registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_2_IMG_MAP[${i}_repo]}:v1.2=quay.io/ocpmigrate/rhcam-${V1_2_IMG_MAP[${i}_repo]}:v1.2 2>&1 | grep -A1 manifests | grep sha256 | awk -F'[: ]' '{ print $8 }')
  done

  # Make 1.2.0 Downstream CSV Changes
  for f in deploy/olm-catalog/konveyor-operator/v1.2.0/konveyor-operator.v1.2.0.clusterserviceversion.yaml \
           deploy/non-olm/v1.2.0/operator.yml
    do
    if [[ "$f" =~ .*clusterserviceversion.* ]]; then
      sed -i "s,mig-operator-container:.*,openshift-migration-rhel7-operator@sha256:${V1_2_IMG_MAP[operator_sha]},g"                                        ${f}
    else
      sed -i "s,mig-operator-container:.*,openshift-migration-rhel7-operator:v1.2,g"                                                                        ${f}
    fi
    sed -i 's,quay.io,registry.redhat.io,g'                                                                                                                 ${f}
    sed -i 's,registry.redhat.io\/konveyor,registry.redhat.io/rhcam-1-2,g'                                                                                  ${f}
    sed -i 's,value: konveyor,value: rhcam-1-2,g'                                                                                                           ${f}
    sed -i "s,/mig-controller:.*,/openshift-migration-controller-rhel8@sha256:${V1_2_IMG_MAP[controller_sha]},g"                                            ${f}
    sed -i "s,/mig-ui:.*,/openshift-migration-ui-rhel8@sha256:${V1_2_IMG_MAP[ui_sha]},g"                                                                    ${f}
    sed -i "s,/velero:.*,/openshift-migration-velero-rhel8@sha256:${V1_2_IMG_MAP[velero_sha]},g"                                                            ${f}
    sed -i "s,/velero-restic-restore-helper:.*,/openshift-migration-velero-restic-restore-helper-rhel8@sha256:${V1_2_IMG_MAP[helper_sha]},g"                ${f}
    sed -i "s,/migration-plugin:.*,/openshift-migration-plugin-rhel8@sha256:${V1_2_IMG_MAP[plugin_sha]},g"                                                  ${f}
    sed -i "s,/velero-plugin-for-aws:.*,/openshift-migration-velero-plugin-for-aws-rhel8@sha256:${V1_2_IMG_MAP[awsplugin_sha]},g"                           ${f}
    sed -i "s,/velero-plugin-for-microsoft-azure:.*,/openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256:${V1_2_IMG_MAP[azureplugin_sha]},g" ${f}
    sed -i "s,/velero-plugin-for-gcp:.*,/openshift-migration-velero-plugin-for-gcp-rhel8@sha256:${V1_2_IMG_MAP[gcpplugin_sha]},g"                           ${f}
    sed -i "s,/registry:.*,/openshift-migration-registry-rhel8@sha256:${V1_2_IMG_MAP[registry_sha]},g"                                                      ${f}
    sed -i "s,/hook-runner:.*,/openshift-migration-hook-runner-rhel7@sha256:${V1_2_IMG_MAP[hookrunner_sha]},g"                                              ${f}
    sed -i "s,rhel7-operator@sha256:.*,rhel7-operator@sha256:${V1_2_IMG_MAP[operator_sha]},g"                                                               ${f}
    sed -i "s,controller-rhel8@sha256:.*,controller-rhel8@sha256:${V1_2_IMG_MAP[controller_sha]},g"                                                         ${f}
    sed -i "s,ui-rhel8@sha256:.*,ui-rhel8@sha256:${V1_2_IMG_MAP[ui_sha]},g"                                                                                 ${f}
    sed -i "s,velero-rhel8@sha256:.*,velero-rhel8@sha256:${V1_2_IMG_MAP[velero_sha]},g"                                                                     ${f}
    sed -i "s,velero-restic-restore-helper-rhel8@sha256:.*,velero-restic-restore-helper-rhel8@sha256:${V1_2_IMG_MAP[helper_sha]},g"                         ${f}
    sed -i "s,plugin-rhel8@sha256:.*,plugin-rhel8@sha256:${V1_2_IMG_MAP[plugin_sha]},g"                                                                     ${f}
    sed -i "s,aws-rhel8@sha256:.*,aws-rhel8@sha256:${V1_2_IMG_MAP[awsplugin_sha]},g"                                                                        ${f}
    sed -i "s,azure-rhel8@sha256:.*,azure-rhel8@sha256:${V1_2_IMG_MAP[azureplugin_sha]},g"                                                                  ${f}
    sed -i "s,gcp-rhel8@sha256:.*,gcp-rhel8@sha256:${V1_2_IMG_MAP[gcpplugin_sha]},g"                                                                        ${f}
    sed -i "s,registry-rhel8@sha256:.*,registry-rhel8@sha256:${V1_2_IMG_MAP[registry_sha]},g"                                                               ${f}
    sed -i "s,hook-runner-rhel7@sha256:.*,hook-runner-rhel7@sha256:${V1_2_IMG_MAP[hookrunner_sha]},g"                                                       ${f}
    sed -i 's,value: mig-controller,value: openshift-migration-controller-rhel8@sha256,g'                                                                   ${f}
    sed -i 's,value: mig-ui,value: openshift-migration-ui-rhel8@sha256,g'                                                                                   ${f}
    sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g'                                   ${f}
    sed -i 's,value: velero-plugin-for-gcp,value: openshift-migration-velero-plugin-for-gcp-rhel8@sha256,g'                                                 ${f}
    sed -i 's,value: velero-plugin-for-aws,value: openshift-migration-velero-plugin-for-aws-rhel8@sha256,g'                                                 ${f}
    sed -i 's,value: velero-plugin-for-microsoft-azure,value: openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256,g'                         ${f}
    sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                                                               ${f}
    sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                                                     ${f}
    sed -i 's,value: registry$,value: openshift-migration-registry-rhel8@sha256,g'                                                                          ${f}
    sed -i 's,konveyor-operator\.,cam-operator.,g'                                                                                                          ${f}
    sed -i 's,:\ konveyor-operator,: cam-operator,g'                                                                                                        ${f}
    sed -i 's/displayName: Konveyor Operator/displayName: Cluster Application Migration Operator/g'                                                         ${f}
    sed -i 's/The Konveyor Operator/The Cluster Application Migration Operator/g'                                                                           ${f}
    sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[controller_sha]}/"                                                            ${f}
    sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[ui_sha]}/"                                                                            ${f}
    sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[plugin_sha]}/"                                                                 ${f}
    sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[velero_sha]}/"                                                                        ${f}
    sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[helper_sha]}/"                                                  ${f}
    sed -i "/VELERO_GCP_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[gcpplugin_sha]}/"                                                          ${f}
    sed -i "/VELERO_AWS_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[awsplugin_sha]}/"                                                          ${f}
    sed -i "/VELERO_AZURE_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[azureplugin_sha]}/"                                                      ${f}
    sed -i "/MIGRATION_REGISTRY_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_2_IMG_MAP[registry_sha]}/"                                                          ${f}
  done
fi

if [ -d deploy/olm-catalog/konveyor-operator/v1.1.2 ]; then
  #Declare v1.1 image information
  V1_1_IMAGES=(
    "controller"
    "operator"
    "plugin"
    "ui"
    "velero"
    "helper"
    "gcpplugin"
    "awsplugin"
    "azureplugin"
    "registry"
  )

  declare -A V1_1_IMG_MAP
  V1_1_IMG_MAP[controller_repo]="openshift-migration-controller"
  V1_1_IMG_MAP[operator_repo]="openshift-migration-operator"
  V1_1_IMG_MAP[plugin_repo]="openshift-migration-plugin"
  V1_1_IMG_MAP[ui_repo]="openshift-migration-ui"
  V1_1_IMG_MAP[velero_repo]="openshift-migration-velero"
  V1_1_IMG_MAP[helper_repo]="openshift-migration-velero-restic-restore-helper"
  V1_1_IMG_MAP[gcpplugin_repo]="openshift-migration-velero-plugin-for-gcp"
  V1_1_IMG_MAP[awsplugin_repo]="openshift-migration-velero-plugin-for-aws"
  V1_1_IMG_MAP[azureplugin_repo]="openshift-migration-velero-plugin-for-microsoft-azure"
  V1_1_IMG_MAP[registry_repo]="openshift-migration-registry"

  #Get latest 1.1 images
  for i in ${V1_1_IMAGES[@]}; do
    docker pull registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_1_IMG_MAP[${i}_repo]}:v1.1 > /dev/null
  done

  #oc mirror 1.1 images to get correct shas
  for i in ${V1_1_IMAGES[@]}; do
    V1_1_IMG_MAP[${i}_sha]=$(oc image mirror --dry-run=true registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_1_IMG_MAP[${i}_repo]}:v1.1=quay.io/ocpmigrate/rhcam-${V1_1_IMG_MAP[${i}_repo]}:v1.1 2>&1 | grep -A1 manifests | grep sha256 | awk -F'[: ]' '{ print $8 }')
  done

  # Make 1.1 Downstream CSV Changes
  for f in deploy/olm-catalog/konveyor-operator/v1.1.2/konveyor-operator.v1.1.2.clusterserviceversion.yaml \
           deploy/non-olm/v1.1.2/operator.yml
    do
    if [[ "$f" =~ .*clusterserviceversion.* ]]; then
      sed -i s,quay.io,registry.redhat.io,g                                                                                                                 ${f}
      sed -i "s,mig-operator:.*,openshift-migration-rhel7-operator@sha256:${V1_1_IMG_MAP[operator_sha]},g"                                                  ${f}
    else
      sed -i s,quay.io,registry.redhat.io,g                                                                                                                 ${f}
      sed -i "s,mig-operator:.*,openshift-migration-rhel7-operator:v1.1,g"                                                                                  ${f}
    fi
    sed -i s,ocpmigrate,rhcam-1-1,g                                                                                                                         ${f}
    sed -i "s,/mig-controller:.*,/openshift-migration-controller-rhel8@sha256:${V1_1_IMG_MAP[controller_sha]},g"                                            ${f}
    sed -i "s,/mig-ui:.*,/openshift-migration-ui-rhel8@sha256:${V1_1_IMG_MAP[ui_sha]},g"                                                                    ${f}
    sed -i "s,/velero:.*,/openshift-migration-velero-rhel8@sha256:${V1_1_IMG_MAP[velero_sha]},g"                                                            ${f}
    sed -i "s,/velero-restic-restore-helper:.*,/openshift-migration-velero-restic-restore-helper-rhel8@sha256:${V1_1_IMG_MAP[helper_sha]},g"                ${f}
    sed -i "s,/migration-plugin:.*,/openshift-migration-plugin-rhel8@sha256:${V1_1_IMG_MAP[plugin_sha]},g"                                                  ${f}
    sed -i "s,/velero-plugin-for-aws:.*,/openshift-migration-velero-plugin-for-aws-rhel8@sha256:${V1_1_IMG_MAP[awsplugin_sha]},g"                           ${f}
    sed -i "s,/velero-plugin-for-microsoft-azure:.*,/openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256:${V1_1_IMG_MAP[azureplugin_sha]},g" ${f}
    sed -i "s,/velero-plugin-for-gcp:.*,/openshift-migration-velero-plugin-for-gcp-rhel8@sha256:${V1_1_IMG_MAP[gcpplugin_sha]},g"                           ${f}
    sed -i "s,/registry:.*,/openshift-migration-registry-rhel8@sha256:${V1_1_IMG_MAP[registry_sha]},g"                                                      ${f}
    sed -i "s,rhel7-operator@sha256:.*,rhel7-operator@sha256:${V1_1_IMG_MAP[operator_sha]},g"                                                               ${f}
    sed -i "s,controller-rhel8@sha256:.*,controller-rhel8@sha256:${V1_1_IMG_MAP[controller_sha]},g"                                                         ${f}
    sed -i "s,ui-rhel8@sha256:.*,ui-rhel8@sha256:${V1_1_IMG_MAP[ui_sha]},g"                                                                                 ${f}
    sed -i "s,velero-rhel8@sha256:.*,velero-rhel8@sha256:${V1_1_IMG_MAP[velero_sha]},g"                                                                     ${f}
    sed -i "s,velero-restic-restore-helper-rhel8@sha256:.*,velero-restic-restore-helper-rhel8@sha256:${V1_1_IMG_MAP[helper_sha]},g"                         ${f}
    sed -i "s,plugin-rhel8@sha256:.*,plugin-rhel8@sha256:${V1_1_IMG_MAP[plugin_sha]},g"                                                                     ${f}
    sed -i "s,aws-rhel8@sha256:.*,aws-rhel8@sha256:${V1_1_IMG_MAP[awsplugin_sha]},g"                                                                        ${f}
    sed -i "s,azure-rhel8@sha256:.*,azure-rhel8@sha256:${V1_1_IMG_MAP[azureplugin_sha]},g"                                                                  ${f}
    sed -i "s,gcp-rhel8@sha256:.*,gcp-rhel8@sha256:${V1_1_IMG_MAP[gcpplugin_sha]},g"                                                                        ${f}
    sed -i "s,registry-rhel8@sha256:.*,registry-rhel8@sha256:${V1_1_IMG_MAP[registry_sha]},g"                                                               ${f}
    sed -i 's,value: mig-controller,value: openshift-migration-controller-rhel8@sha256,g'                                                                   ${f}
    sed -i 's,value: mig-ui,value: openshift-migration-ui-rhel8@sha256,g'                                                                                   ${f}
    sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g'                                   ${f}
    sed -i 's,value: velero-plugin-for-gcp,value: openshift-migration-velero-plugin-for-gcp-rhel8@sha256,g'                                                 ${f}
    sed -i 's,value: velero-plugin-for-aws,value: openshift-migration-velero-plugin-for-aws-rhel8@sha256,g'                                                 ${f}
    sed -i 's,value: velero-plugin-for-microsoft-azure,value: openshift-migration-velero-plugin-for-microsoft-azure-rhel8@sha256,g'                         ${f}
    sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                                                               ${f}
    sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                                                     ${f}
    sed -i 's,value: registry$,value: openshift-migration-registry-rhel8@sha256,g'                                                                          ${f}
    sed -i 's,konveyor-operator\.,cam-operator.,g'                                                                                                          ${f}
    sed -i 's,: konveyor-operator,: cam-operator,g'                                                                                                         ${f}
    sed -i 's/displayName: Konveyor Operator/displayName: Cluster Application Migration Operator/g'                                                         ${f}
    sed -i 's/The Konveyor Operator/The Cluster Application Migration Operator/g'                                                                           ${f}
    sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[controller_sha]}/"                                                            ${f}
    sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[ui_sha]}/"                                                                            ${f}
    sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[plugin_sha]}/"                                                                 ${f}
    sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[velero_sha]}/"                                                                        ${f}
    sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[helper_sha]}/"                                                  ${f}
    sed -i "/VELERO_GCP_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[gcpplugin_sha]}/"                                                          ${f}
    sed -i "/VELERO_AWS_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[awsplugin_sha]}/"                                                          ${f}
    sed -i "/VELERO_AZURE_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[azureplugin_sha]}/"                                                      ${f}
    sed -i "/MIGRATION_REGISTRY_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_1_IMG_MAP[registry_sha]}/"                                                          ${f}
  done
fi

if [ -d deploy/olm-catalog/konveyor-operator/v1.0.1 ]; then
  #Declare v1.0 image information
  V1_0_IMAGES=(
    "controller"
    "operator"
    "plugin"
    "ui"
    "velero"
    "helper"
  )

 declare -A V1_0_IMG_MAP
  V1_0_IMG_MAP[controller_repo]="openshift-migration-controller"
  V1_0_IMG_MAP[operator_repo]="openshift-migration-operator"
  V1_0_IMG_MAP[plugin_repo]="openshift-migration-plugin"
  V1_0_IMG_MAP[ui_repo]="openshift-migration-ui"
  V1_0_IMG_MAP[velero_repo]="openshift-migration-velero"
  V1_0_IMG_MAP[helper_repo]="openshift-migration-velero-restic-restore-helper"

  #Get latest 1.0 images
  for i in ${V1_0_IMAGES[@]}; do
    docker pull registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_0_IMG_MAP[${i}_repo]}:v1.0 > /dev/null
  done

  #oc mirror 1.0 images to get correct shas
  for i in ${V1_0_IMAGES[@]}; do
    V1_0_IMG_MAP[${i}_sha]=$(oc image mirror --dry-run=true registry-proxy.engineering.redhat.com/rh-osbs/rhcam-${V1_0_IMG_MAP[${i}_repo]}:v1.0=quay.io/ocpmigrate/rhcam-${V1_0_IMG_MAP[${i}_repo]}:v1.0 2>&1 | grep -A1 manifests | grep sha256 | awk -F'[: ]' '{ print $8 }')
  done

  export V1_0_1_CSV=deploy/olm-catalog/konveyor-operator/v1.0.1/konveyor-operator.v1.0.1.clusterserviceversion.yaml
  sed -i s,quay.io,registry.redhat.io,g                                                                                                   ${V1_0_1_CSV}
  sed -i s,ocpmigrate,rhcam-1-0,g                                                                                                          ${V1_0_1_CSV}
  sed -i "s,mig-operator:.*,openshift-migration-rhel7-operator@sha256:${V1_0_IMG_MAP[operator_sha]},g"                                     ${V1_0_1_CSV}
  sed -i "s,/mig-controller:.*,/openshift-migration-controller-rhel8@sha256:${V1_0_IMG_MAP[controller_sha]},g"                             ${V1_0_1_CSV}
  sed -i "s,/mig-ui:.*,/openshift-migration-ui-rhel8@sha256:${V1_0_IMG_MAP[ui_sha]},g"                                                     ${V1_0_1_CSV}
  sed -i "s,/velero:.*,/openshift-migration-velero-rhel8@sha256:${V1_0_IMG_MAP[velero_sha]},g"                                             ${V1_0_1_CSV}
  sed -i "s,/velero-restic-restore-helper:.*,/openshift-migration-velero-restic-restore-helper-rhel8@sha256:${V1_0_IMG_MAP[helper_sha]},g" ${V1_0_1_CSV}
  sed -i "s,/migration-plugin:.*,/openshift-migration-plugin-rhel8@sha256:${V1_0_IMG_MAP[plugin_sha]},g"                                   ${V1_0_1_CSV}
  sed -i "s,rhel7-operator@sha256:.*,rhel7-operator@sha256:${V1_0_IMG_MAP[operator_sha]},g"                                                ${V1_0_1_CSV}
  sed -i "s,controller-rhel8@sha256:.*,controller-rhel8@sha256:${V1_0_IMG_MAP[controller_sha]},g"                                          ${V1_0_1_CSV}
  sed -i "s,ui-rhel8@sha256:.*,ui-rhel8@sha256:${V1_0_IMG_MAP[ui_sha]},g"                                                                  ${V1_0_1_CSV}
  sed -i "s,velero-rhel8@sha256:.*,velero-rhel8@sha256:${V1_0_IMG_MAP[velero_sha]},g"                                                      ${V1_0_1_CSV}
  sed -i "s,velero-restic-restore-helper-rhel8@sha256:.*,velero-restic-restore-helper-rhel8@sha256:${V1_0_IMG_MAP[helper_sha]},g"          ${V1_0_1_CSV}
  sed -i "s,plugin-rhel8@sha256:.*,plugin-rhel8@sha256:${V1_0_IMG_MAP[plugin_sha]},g"                                                      ${V1_0_1_CSV}
  sed -i 's,value: mig-ui,value: openshift-migration-ui-rhel8@sha256,g'                                                                    ${V1_0_1_CSV} 
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g'                    ${V1_0_1_CSV}
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                                                ${V1_0_1_CSV}
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                                      ${V1_0_1_CSV}
  sed -i 's,value: mig-controller,value: openshift-migration-controller-rhel8@sha256,g'                                                    ${V1_0_1_CSV}
  sed -i 's,: konveyor-operator,: cam-operator,g'                                                                                          ${V1_0_1_CSV}
  sed -i 's/displayName: Konveyor Operator/displayName: Cluster Application Migration Operator/g'                                          ${V1_0_1_CSV}
  sed -i 's/The Konveyor Operator/The Cluster Application Migration Operator/g'                                                            ${V1_0_1_CSV}
  sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[controller_sha]}/"                                             ${V1_0_1_CSV}
  sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[ui_sha]}/"                                                             ${V1_0_1_CSV}
  sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[plugin_sha]}/"                                                  ${V1_0_1_CSV}
  sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[velero_sha]}/"                                                         ${V1_0_1_CSV}
  sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[helper_sha]}/"                                   ${V1_0_1_CSV}

  # Make 1.0.1 Downstream non-OLM changes
  export V1_0_1_YAML=deploy/non-olm/v1.0.1/operator.yml
  sed -i s,quay.io,registry.redhat.io,g                                                                                 ${V1_0_1_YAML}
  sed -i s,ocpmigrate,rhcam-1-0,g                                                                                       ${V1_0_1_YAML}
  sed -i s,mig-operator:release-1\.0,openshift-migration-rhel7-operator:v1.0,g                                          ${V1_0_1_YAML}
  sed -i s,mig-controller,openshift-migration-controller-rhel8@sha256,g                                                 ${V1_0_1_YAML}
  sed -i s,mig-ui,openshift-migration-ui-rhel8@sha256,g                                                                 ${V1_0_1_YAML}
  sed -i 's,value: velero-restic-restore-helper,value: openshift-migration-velero-restic-restore-helper-rhel8@sha256,g' ${V1_0_1_YAML}
  sed -i 's,value: velero,value: openshift-migration-velero-rhel8@sha256,g'                                             ${V1_0_1_YAML}
  sed -i 's,value: migration-plugin,value: openshift-migration-plugin-rhel8@sha256,g'                                   ${V1_0_1_YAML}
  sed -i "/MIG_CONTROLLER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[controller_sha]}/"                          ${V1_0_1_YAML}
  sed -i "/MIG_UI_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[ui_sha]}/"                                          ${V1_0_1_YAML}
  sed -i "/VELERO_PLUGIN_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[plugin_sha]}/"                               ${V1_0_1_YAML}
  sed -i "/VELERO_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[velero_sha]}/"                                      ${V1_0_1_YAML}
  sed -i "/VELERO_RESTIC_RESTORE_HELPER_TAG/,/^ *[^:]*:/s/value: .*/value: ${V1_0_IMG_MAP[helper_sha]}/"                ${V1_0_1_YAML}
fi
