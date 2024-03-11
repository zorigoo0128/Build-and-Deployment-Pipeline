#!/bin/bash
cd "$(dirname "$0")"

BUILD_VERSION=
PROJECT_PATH=
TARGET=
EC2_INSTANCE_TYPE="c5.large"
FLEET_NAME="fleet-prod"
ROLE_ARN=
FLEET_TYPE='SPOT'
PROFILE='default'
# Parse command-line arguments
while getopts ":t:p:v:e:f:r:k:a:" opt; do
  case $opt in
    t)
      TARGET="$OPTARG"
      ;;
    p)
      PROJECT_PATH="$OPTARG"
      ;;
    v)
      BUILD_VERSION="$OPTARG"
      ;;
    e)
      EC2_INSTANCE_TYPE="$OPTARG"
      ;;
    f)
      FLEET_NAME="$OPTARG"
      ;;
    r)
      ROLE_ARN="$OPTARG"
      ;;
    k)
      FLEET_TYPE="$OPTARG"
      ;;
    a)
      PROFILE="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
ARCHIVE_DIR=$HOME/Packages/$BUILD_VERSION

export FLEET_TYPE
export ROLE_ARN
export BUILD_VERSION
export PROJECT_PATH
export TARGET
export ARCHIVE_DIR
export PROFILE
export FLEET_NAME
export EC2_INSTANCE_TYPE
# Access variables from the first script
echo "Build version: $BUILD_VERSION"
echo "Project path: $PROJECT_PATH"
echo "Target: $TARGET"
echo "Archive dir: $ARCHIVE_DIR"
echo "Fleet name: $FLEET_NAME"
echo "AWS Profile: $PROFILE"

echo $PWD

# Create dedicated server package
echo Packaging...
./package.sh > package.log

# Deploy package to AWS
echo Deploying...
./deploy.sh > deploy.log

# Done
echo Done