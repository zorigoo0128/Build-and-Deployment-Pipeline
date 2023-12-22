#!/bin/bash
cd "$(dirname "$0")"

BUILD_VERSION=
PROJECT_PATH=
TARGET=
EC2_INSTANCE_TYPE="c5.large"
FLEET_NAME="fleet-prod"
ROLE_ARN=
# Parse command-line arguments
while getopts ":t:p:v:e:f:r:" opt; do
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

export ROLE_ARN
export BUILD_VERSION
export PROJECT_PATH
export TARGET
export ARCHIVE_DIR
export FLEET_NAME
export EC2_INSTANCE_TYPE
# Access variables from the first script
echo "Build version: $BUILD_VERSION"
echo "Project path: $PROJECT_PATH"
echo "Target: $TARGET"
echo "Archive dir: $ARCHIVE_DIR"
echo "Fleet name: $FLEET_NAME"

echo $PWD

# Create dedicated server package
echo Packaging...
./package.sh > package.log

# Deploy package to AWS
echo Deploying...
./deploy.sh > deploy.log

# Done
echo Done