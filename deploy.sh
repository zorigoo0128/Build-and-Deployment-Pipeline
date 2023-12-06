#!/bin/bash

echo "Deploying Fleet $fleet_id with Version $version"

# Get the default AWS region
AWS_REGION=$(aws configure get region)


# GameLift build details
BUILD_NAME="build-prod"
BUILD_ID=""
FLEET_TYPE="ON_DEMAND"
MIN_TCP_PORT=7777
MAX_TCP_PORT=7783
MIN_UDP_PORT=7777
MAX_UDP_PORT=7783
UDP_CONFIG="FromPort=$MIN_UDP_PORT,ToPort=$MAX_UDP_PORT,IpRange=0.0.0.0/0,Protocol=UDP"
TCP_CONFIG="FromPort=$MIN_TCP_PORT,ToPort=$MAX_TCP_PORT,IpRange=0.0.0.0/0,Protocol=TCP"
INSTANCE_ROLE=$ROLE_ARN
LAUNCH_PATH=$(./get_launch_path.sh)

# Create build
echo "Uploading GameLift build..."
OUTPUT=$(aws gamelift upload-build --name "$BUILD_NAME" --build-version "$BUILD_VERSION" --server-sdk-version "5.1.1" --region "$AWS_REGION" --build-root "$ARCHIVE_DIR/LinuxServer" --operating-system "AMAZON_LINUX_2023" --output json )
BUILD_ID=$(echo "$OUTPUT" | grep "Build ID:" | awk '{print $NF}')

echo "Uploaded build with id: $BUILD_ID"

echo "Creating GameLift fleet..."
FLEET_ID=$(aws gamelift create-fleet \
  --name "$FLEET_NAME" \
  --build-id "$BUILD_ID" \
  --ec2-instance-type "$EC2_INSTANCE_TYPE" \
  --ec2-inbound-permissions "$UDP_CONFIG" "$TCP_CONFIG" \
  --fleet-type "$FLEET_TYPE" \
  --runtime-configuration "ServerProcesses=[{LaunchPath=/local/game/$LAUNCH_PATH,Parameters=-log,ConcurrentExecutions=7}]" \
  --metric-groups "TargetTracking-AverageGameSessionRoundtripTime" \
  --instance-role-arn "$INSTANCE_ROLE" \
  --output json | jq -r '.FleetId')

echo "Fleet created: $FLEET_ID"