# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

#! /bin/bash

declare -A all_images
declare -A csm_module_images

# CSM Drivers
declare -A csi_driver_images
csi_driver_images[csi-powerscale]=""
csi_driver_images[csi-powerstore]=""
csi_driver_images[csi-powermax]=""
csi_driver_images[csi-vxflexos]=""
csi_driver_images[csi-unity]=""

# CSI Sidecars
declare -A csi_sidecar_images
csi_sidecar_images[attacher]=""
csi_sidecar_images[provisioner]=""
csi_sidecar_images[snapshotter]=""
csi_sidecar_images[resizer]=""
csi_sidecar_images[registrar]=""
csi_sidecar_images[external-health-monitor]=""

version_content_file="versions-content.txt"

get_all_images_raw() {
  readarray -t lines < $version_content_file
  for line in "${lines[@]}"; do
    if [[ -z $line ]] || [[ $line =~ ^# ]]; then
        continue
    fi

    name=$(echo $line | cut -d: -f1 | tr -d ' ')
    version=$(echo $line | cut -d: -f2 | tr -d ' ')

    if [[ $name == "csm-replication" ]]; then
      all_images[replicator]=$version
      continue
    elif [[ $name == "karavi-resiliency" ]]; then
      all_images[podmon]=$version
      continue
    elif [[ $name == "csm-authorization-v2" ]]; then
      all_images[authorization]=$version
      continue
    elif [[ $name == "csireverseproxy" ]]; then
      all_images[reverseproxy]=$version
      continue
    elif [[ $name == "csi-powerscale" ]]; then
      all_images[isilon]=$version
      continue
    fi

    all_images[$name]=$version
  done
}

# Creates appropriate map for just the CSI Sidecars images.
# This is to be used for easier substitution.
update_modules_versions() {
  # Parse out and save each needed CSM version
  readarray -t lines < $version_content_file
  for line in "${lines[@]}"; do
    name=$(echo $line | cut -d: -f1 | tr -d ' ')
    version=$(echo $line | cut -d: -f2 | tr -d ' ')

    if [[ $name == "csm-replication" ]]; then
      csm_module_images[replication]=$version
    elif [[ $name == "karavi-resiliency" ]]; then
      csm_module_images[resiliency]=$version
    elif [[ $name == "csm-authorization-v2" ]]; then
      csm_module_images[authorization]=$version
    elif [[ $name == "csireverseproxy" ]]; then
      csm_module_images[csireverseproxy]=$version
    elif [[ $name == "karavi-observability" ]]; then
      csm_module_images[observability]=$version
    elif [ "$name" == "csm-metrics-powerstore" ] || [ "$name" == "csm-metrics-powerscale" ] || [ "$name" == "csm-metrics-powermax" ]; then
      csm_module_images[$name]=$version
    fi
  done
}

# Creates appropriate map for just the CSI Sidecars images.
update_csi_sidecars_versions() {
  for key in "${!csi_sidecar_images[@]}"; do
    version=$(cat $version_content_file | grep "$key" | cut -d: -f2 | tr -d ' ')
    csi_sidecar_images[$key]=$version
  done
}

# Creates appropriate map for just the CSI Driver images.
update_csi_drivers_versions() {
  for key in "${!csi_driver_images[@]}"; do
    version=$(cat $version_content_file | grep "$key" | cut -d: -f2 | tr -d ' ')
    csi_driver_images[$key]=$version
  done
}

# Updates the version in the shortcodes. This needs to be aligned properly
# with the naming conventions.
update_shortcodes() {
  echo "Checking to see if any shortcodes need to be updated..."
  for key in "${!all_images[@]}"; do
    path="layouts/shortcodes/version-docs.html"
    name=$(echo $key | tr '-' '_')
    version=${all_images[$key]}

    # If no shortcode was found, we don't need to update it
    if ! grep -q "\"$name.*\" -}}" $path; then
      echo "No shortcode found for $key. Skipping."
      continue
    fi

    old_shortcode=$(grep -r "\"$name.*\" -}}" $path)

    # If shortcode already contains the version, we don't need to update it
    if [[ "$old_shortcode" == *"$version"* ]]; then
      continue
    fi

    new_shortcode=$(echo $old_shortcode | sed "s/}}.*/}}$version/")

    sed -i "s|${old_shortcode}|${new_shortcode}|g" $path
  done
}

# Specific substitution needed due to the fact that the overall helm file is formatting in a different manner.
update_installation_wizard_helm() {
  echo "Checking to see if any installation wizard helm files need to be updated..."
  # Sanitize the CSM version
  csm_version=$(echo ${all_images[csm-version]} | tr -d 'v' | tr -d '\r')

  # The installation wizard templates should have the latest version of the CSM.
  wizard_files=$(find content/docs/getting-started/installation/installationwizard/src/templates/helm/ -name "*$csm_version*")

  if [ -z "$wizard_files" ]; then
      echo "No Installation Wizard content for latest CSM found. Skipping."
      return
  fi

  for file in $wizard_files; do
    for key in "${!all_images[@]}"; do
      # Retrieve the current version from the file of the sidecar.
      old_version=$(grep -m 1 -E ".*image.*$key.*" $file | xargs)
      if [ -z "$old_version" ]; then
        continue
      fi

      # All instance of the image in a file either go "image:/value:" so we remove that to get the pure image.
      old_version=$(echo $old_version | cut -d':' -f2- | tr -d ' ')
      new_version=$(echo $old_version | sed "s/:.*/:${all_images[$key]}/")

      # If the version is the same, then we skip
      if [ "$old_version" == "$new_version" ]; then
        continue
      fi

      # Update the version in the file.
      sed -i "s|${old_version}|${new_version}|g" $file
    done
  done
}

# Properly parses the contents of each operator file and updates the image versions.
# Due to the use of 'yq', exact changes will not be tracked until the pull request is created.
update_installation_wizard_operator() {
  echo "Checking to see if any installation wizard operator files need to be updated..."

  # Sanitize the CSM version
  csm_version=$(echo ${all_images[csm-version]} | tr -d 'v' | tr -d '\r')

  wizard_files=$(find content/docs/getting-started/installation/installationwizard/src/templates/operator/ -name "*$csm_version*")

  if [ -z "$wizard_files" ]; then
    echo "No Installation Wizard content for latest CSM found. Skipping."
    return
  fi

  for file in $wizard_files; do
    driver_name=""
    if grep -q "isilon" $file; then
      driver_name="csi-powerscale"
    elif grep -q "powerstore" $file; then
      driver_name="csi-powerstore"
    elif grep -q "powermax" $file; then
      driver_name="csi-powermax"
    fi

    latest_version=${csi_driver_images[$driver_name]}

    # Update Driver version
    yq -i e "(.spec.driver.configVersion) = \"$latest_version\"" $file

    # Update Driver image
    yq -i e "(.spec.driver.common.image) |= sub(\":.*\"; \":$latest_version\")" $file

    # Update the modules.
    for key in "${!csm_module_images[@]}"; do
      # Retrieve latest version
      image_name=$key
      latest_version=${csm_module_images[$image_name]}

      # Update configVersion
      yq -i e "(.spec.modules[] | select(.name == \"$key\") | .configVersion) = \"$latest_version\"" $file

      # Since the image of observability is different for each driver, substitution is specific.
      if [[ $key == "observability" ]]; then
          component_name=""

          if grep -q "powerstore" $file; then
            component_name="metrics-powerstore"
          elif grep -q "powermax" $file; then
            component_name="metrics-powermax"
          elif grep -q "isilon" $file; then
            component_name="metrics-powerscale"
          fi

          if [ $component_name == "" ]; then
            echo "File is not a valid format in name"
            continue
          fi

          latest_version=${csm_module_images["csm-"$component_name]}

          yq -i e "(.spec.modules[] | select(.name == \"$key\") | .components[] | select(.name == \"$component_name\") | .image) |= sub(\":.*\"; \":$latest_version\")" $file

          # Update otel-collector and nginx
          otel_version=${all_images["otel-collector"]}
          yq -i e "(.spec.modules[] | select(.name == \"$key\") | .components[] | select(.name == \"otel-collector\") | .image) |= sub(\":.*\"; \":$otel_version\")" $file

          # Update nginx-unprivileged
          nginx_version=${all_images["nginx-unprivileged"]}
          yq -i e "(.spec.modules[] | select(.name == \"$key\") | .components[] | select(.name == \"otel-collector\") | .envs[] | select(.name == \"NGINX_PROXY_IMAGE\") | .value) |= sub(\":.*\"; \":$nginx_version\")" $file
          continue
      fi

      # Update all the images if they are the only image in the sidecar.
      yq -i e "(.spec.modules[] | select(.name == \"$key\") | .components[] | .image) |= sub(\":.*\"; \":$latest_version\")" $file
    done

    # Update the csi sidecars
    for key in "${!csi_sidecar_images[@]}"; do
      # Retrieve latest version
      image_name=$key
      latest_version=${csi_sidecar_images[$image_name]}

      # Update all the images if they are the only image in the sidecar.
      yq -i e "(.spec.driver.sideCars[] | select(.name == \"$image_name\") | .image) |= sub(\":.*\"; \":$latest_version\")" $file
    done
  done
}


get_all_images_raw
update_modules_versions
update_csi_sidecars_versions
update_csi_drivers_versions

update_shortcodes
update_installation_wizard_helm
update_installation_wizard_operator
