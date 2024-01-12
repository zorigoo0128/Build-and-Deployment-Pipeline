# Build And Deployment (UE5, GameLift)

This Bash script is designed to build and deploy a `Unreal Engine` project to `GameLift` fleet with customizable options. The script accepts various parameters such as instance type, fleet type, port settings, IAM roles, and AWS location.

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) installed and configured with the necessary permissions.
- [jq](https://stedolan.github.io/jq/) installed for JSON parsing.
- *(Optional)* `dos2unix` installed for converting shell script into Unix format: `sudo apt install dos2unix` 


## Usage

1. Clone the repository:

    ```shell
    git clone https://github.com/zorigoo0128/Build-and-Deployment-Pipeline.git BuildAndDeployment
    cd BuildAndDeployment
    ```

2. Run the script with desired parameters:

    ```shell
    ./run.sh -f <fleet_name> -e <ec2_instance_type> -p <uproject_path> -t <build_target> -v <build_version> -r <role_arn>
    ```
    Parameter|Type|Required
    -|-|-
    `<fleet_name>`|string|Y
    `<ec2_instance_type>`|string|N
    `<uproject_path>`|string|Y
    `<build_target>`|string|Y
    `<build_version>`|string|Y
    `<role_arn>`|string|N


## Example

```shell
./run.sh -f fleet-myproject -e c5.large -p /home/user/MyProject/MyProject.uproject -t MyProjectServer -v v1.0.0 -r arn:aws:iam::22334455667788:role/RoleArn
```

This example creates a GameLift fleet with a `C5.large` instance type, using `On-Demand` instances, TCP and UDP port settings, SSH port 22, specific EC2 inbound permissions, and located in the awscli default region.

---

Feel free to customize the `README` further based on your specific use case and project structure. Adjust the usage instructions and example command to match the parameters and options you've implemented in your script.
