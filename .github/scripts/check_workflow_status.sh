# Copyright (c) 2025 Dell Inc., or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0

# Script to check the status of the latest workflow run for a specified event type

#!/bin/bash

GITHUB_TOKEN=$1
REPO=$2
EVENT_TYPE=$3
MAX_RETRIES=5
POLL_INTERVAL=30
RETRY_COUNT=0
WORKFLOWS_API_URL="https://api.github.com/repos/${REPO}/actions/runs?event=${EVENT_TYPE}"
LATEST_WORKFLOW_ID=""

echo "Checking workflow status for ${REPO}..."

# Get the latest workflow run status for the specified event type
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$WORKFLOWS_API_URL")

# Check if the API call was successful
if [ $? -ne 0 ]; then
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "API call failed after $MAX_RETRIES attempts."
    exit 1
  else
    echo "API call failed. Retrying ($RETRY_COUNT/$MAX_RETRIES)..."
    sleep 5
    continue
  fi
fi

WORKFLOW_ID=$(echo "${RESPONSE}" | jq -r '.workflow_runs[0].id')
LATEST_WORKFLOW_ID=0

# Check if the workflow ID is different from the last detected workflow ID
if [ "$WORKFLOW_ID" != "$LATEST_WORKFLOW_ID" ]; then
  LATEST_WORKFLOW_ID="$WORKFLOW_ID"
  echo "fetching the recently submitted workflow..."
  for ((i=1; i<=5; i++)); do
    sleep "$POLL_INTERVAL"
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$WORKFLOWS_API_URL")
    NEW_WORKFLOW_ID=$(echo "${RESPONSE}" | jq -r '.workflow_runs[0].id')
    if [ "$NEW_WORKFLOW_ID" != "$LATEST_WORKFLOW_ID" ]; then
      LATEST_WORKFLOW_ID="$NEW_WORKFLOW_ID"
      WORKFLOW_ID=$LATEST_WORKFLOW_ID
      break
    fi
  done
fi

WORKFLOW_API_URL="https://api.github.com/repos/${REPO}/actions/runs/${WORKFLOW_ID}"
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$WORKFLOW_API_URL")
STATUS=$(echo "${RESPONSE}" | jq -r '.status')
CONCLUSION=$(echo "${RESPONSE}" | jq -r '.conclusion')

echo "WORKFLOW_ID: ${WORKFLOW_ID}"
echo "URL: ${WORKFLOW_API_URL}"

# Poll up to 5 times to check for an in_progress status of the most recently submitted.
# Once it finds an in_progress or queued workflow, it will keep polling until the workflow is completed successfully or failed.
if [ "${STATUS}" == "in_progress" ] || [ "${STATUS}" == "queued" ]; then
  echo "Workflow in progress for ${REPO}."

  while [ "${STATUS}" == "in_progress" ]; do
    sleep "$POLL_INTERVAL"
    RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$WORKFLOW_API_URL")
    STATUS=$(echo "${RESPONSE}" | jq -r '.status')
    CONCLUSION=$(echo "${RESPONSE}" | jq -r '.conclusion')  
  done

  if [ "${STATUS}" == "completed" ]; then
    if [ "${CONCLUSION}" == "success" ]; then
      echo "Workflow completed successfully for ${REPO}."
      exit 0
    else
      echo "Workflow failed for ${REPO}."
      exit 1
    fi
  fi

elif [ "${STATUS}" == "completed" ]; then
    if [ "${CONCLUSION}" == "success" ]; then
      echo "Workflow completed successfully for ${REPO}."
      exit 0
    fi

else
  echo "Either workflow ${WORKFLOW_ID} failed or is stuck for ${REPO}."
  echo "Check at URL: ${WORKFLOW_API_URL}" 
  exit 1
fi