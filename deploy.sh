#!/bin/bash

echo "Deploying Fleet $fleet_id with Version $version"

# Get the default AWS region
AWS_REGION=$(aws configure get region)

# GameLift build details
BUILD_ID=""
UDP_CONFIG="FromPort=7777,ToPort=7783,IpRange=0.0.0.0/0,Protocol=UDP"
INSTANCE_ROLE=$ROLE_ARN
LAUNCH_PATH=$(./get_launch_path.sh)

# Create build
echo "Uploading GameLift build..."
OUTPUT=$(aws gamelift upload-build --profile "$PROFILE" --name "$TARGET" --build-version "$BUILD_VERSION" --server-sdk-version "5.1.1" --region "$AWS_REGION" --build-root "$ARCHIVE_DIR/LinuxServer" --operating-system "AMAZON_LINUX_2023" --output json )
BUILD_ID=$(echo "$OUTPUT" | grep "Build ID:" | awk '{print $NF}')
sleep 5

# Create fleet
echo "Uploaded build with id: $BUILD_ID"
echo "Creating GameLift fleet..."
$(aws gamelift create-fleet --profile "$PROFILE" \
  --name "$FLEET_NAME" \
  --build-id "$BUILD_ID" \
  --ec2-instance-type "$EC2_INSTANCE_TYPE" \
  --ec2-inbound-permissions "$UDP_CONFIG" \
  --fleet-type "$FLEET_TYPE" \
  --runtime-configuration "ServerProcesses=[{LaunchPath=/local/game/$LAUNCH_PATH,Parameters=-log,ConcurrentExecutions=7}]" \
  --metric-groups "default" \
  --instance-role-arn "$INSTANCE_ROLE" \
  --output json > fleet_info.json) 

echo "Fleet created!"