import json
import shutil
import time
import os
import subprocess
import argparse
import boto3

# Set default values
DEFAULT_EC2_INSTANCE_TYPE = "c5.large"
DEFAULT_FLEET_NAME = "fleet-prod"
DEFAULT_FLEET_TYPE = "SPOT"
DEFAULT_PROFILE = "default"

# SSL dirs
LIBRARY_DIR="Plugins/GameLiftServerSDK/ThirdParty/GameLiftServerSDK/Linux/x86_64-unknown-linux-gnu"
CRYPTO_FILE="libcrypto.so.1.1"
SSL_FILE="libssl.so.1.1"

# 

class GameLiftDeployer:
    def __init__(self, profile, 
                fleet_name, 
                build_version, 
                ec2_instance_type="c5.large", 
                fleet_type="SPOT",
                role_arn="", 
                project_path="",
                environment="", 
                launch_path_script="./get_launch_path.sh", 
                parameters = "-log",
                target="",
                sdk_version = '5.1.1',
                concurrent=7):
        self.build_target = target
        self.profile = profile
        self.fleet_name = fleet_name
        self.build_version = build_version
        self.archive_dir = f'{os.environ.get("HOME")}/Packages/{self.build_version}'
        self.ec2_instance_type = ec2_instance_type
        self.fleet_type = fleet_type
        self.role_arn = role_arn
        self.launch_path_script = launch_path_script
        self.additional_parameters = parameters
        self.project_path = project_path
        self.project_name = os.path.basename(self.project_path).split('.')[0]
        self.concurrent = concurrent
        self.env = environment
        self.server_sdk_version = sdk_version
        self.build_id = ''

    def get_aws_region(self):
        session = boto3.session.Session(profile_name=self.profile)
        return session.region_name

    def package(self):
        print("Packaging...")

        package_cmd = [
            os.path.join(os.getenv('UE_ROOT'), 'Engine/Build/BatchFiles/RunUAT.sh'),
            "BuildCookRun", "-Server", "-NoClient", "-ServerConfig=Shipping",
            f"-Project={self.project_path}",
            "-UTF8Output", "-NoDebugInfo", "-AllMaps", "-NoP4", "-Build", "-Cook", "-Stage", "-Pak", "-Package", "-Archive", "-Iterate",
            f"-ArchiveDirectory={self.archive_dir}",
            "-Platform=Linux", 
            f"-Target={self.build_target}"
        ]
        
        with open('package.log', 'w') as log_file:
            subprocess.run(package_cmd, check=True, stderr=subprocess.STDOUT)
        print('Package Created!')

    def upload_build(self):
        print("Uploading build...")
        aws_region = self.get_aws_region()
        upload_build_cmd = f"aws gamelift upload-build --name {self.build_target} --build-version {self.build_version} --server-sdk-version {self.server_sdk_version} --region {aws_region} --build-root {self.archive_dir}/LinuxServer --operating-system AMAZON_LINUX_2023 --output json"
        
        process = subprocess.check_output(upload_build_cmd, shell=True, text=True)

        last_line = ""
        for line in process.split('\n'):
            last_line = line if line else last_line
        if 'Build' in last_line:
            self.build_id = last_line.split(' ')[-1]
        else:
            print("Upload Build Error:", last_line)
        
        client = boto3.client("gamelift", region_name=aws_region)
        while True:
            build_response = client.describe_build(BuildId=self.build_id)
            if build_response and build_response['Build']['Status'] == 'READY':
                print('Upload completed! Build id: ', self.build_id)
                return 

            time.sleep(1)

    
    def check_build_exists(self, version):
        aws_region = self.get_aws_region()
        client = boto3.client("gamelift", region_name=aws_region)

        response = client.list_builds(
            Status='READY'
        )

        build_id = ''
        if response and 'Builds' in response:
            for build_info in response['Builds']:
                if 'Version' in build_info and build_info['Version'] == version:
                    build_id = build_info['BuildId']
        return build_id
            
        

    def create_fleet(self, build_id):
        print('Creating Fleet...')
        aws_region = self.get_aws_region()
        client = boto3.client("gamelift", region_name=aws_region)
        launch_path = os.path.join(self.project_name, 'Binaries', 'Linux', f'{self.build_target}-Linux-Shipping')

        response = client.create_fleet(
            Name=self.fleet_name,
            BuildId=build_id,
            EC2InstanceType=self.ec2_instance_type,
            EC2InboundPermissions=[
                {
                    'FromPort': 7777,
                    'ToPort': 7777 + self.concurrent,
                    'IpRange': '0.0.0.0/0',
                    'Protocol': 'UDP'
                }
            ],
            Tags=[
                {
                    'Key': 'project',
                    'Value': self.fleet_name
                }
            ],
            FleetType=self.fleet_type,
            RuntimeConfiguration={
                "ServerProcesses": [
                    {
                        "LaunchPath": f"/local/game/{launch_path}",
                        "Parameters": f"{self.additional_parameters}",
                        "ConcurrentExecutions": self.concurrent
                    }
                ]
            },
            CertificateConfiguration={
                'CertificateType': 'GENERATED'
            },
            InstanceRoleArn=self.role_arn,
            ComputeType='EC2',
            MetricGroups=[self.fleet_name]
        )
        print('Fleet created successful!')
        return response


    def copy_additional_libraries(self):
        try:
            shutil.copy( os.path.join( os.path.dirname(self.project_path) ,LIBRARY_DIR, CRYPTO_FILE), os.path.join(self.archive_dir, 'LinuxServer', self.project_name, LIBRARY_DIR) )
            shutil.copy( os.path.join( os.path.dirname(self.project_path) ,LIBRARY_DIR, SSL_FILE), os.path.join(self.archive_dir, 'LinuxServer', self.project_name, LIBRARY_DIR) )
            shutil.copy( os.path.join( os.path.dirname(self.project_path) ,'Scripts', 'install.sh'), os.path.join(self.archive_dir, 'LinuxServer') )

        except shutil.Error as e:
            print(f'Error copying files: {e}')
        except Exception as e:
            print(f'Unexpected error: {e}')

    def deploy(self):
        existing_build_id = deployer.check_build_exists(self.build_version)

        if not existing_build_id:
            self.package()
            self.copy_additional_libraries()
            self.upload_build()
            time.sleep(5)
        else:
            self.build_id = existing_build_id
        
        fleet_info = self.create_fleet(self.build_id)

        # Write fleet info to file as JSON
        with open('fleet_info.json', "w") as json_file:
            data_json = json.dumps(fleet_info, default=str, indent=4, sort_keys=True)
            json_file.write(data_json)

        print("\n--------------------------------------------")
        print(f"Build ID: {fleet_info['FleetAttributes']['BuildId']}")
        print(f"Fleet ID: {fleet_info['FleetAttributes']['FleetId']}")
        print(f"Fleet Name: {fleet_info['FleetAttributes']['Name']}")
        print(f"Fleet Type: {fleet_info['FleetAttributes']['FleetType']}")
        print("\n--------------------------------------------")

if __name__ == "__main__":




    parser = argparse.ArgumentParser(description="Script description")
    parser.add_argument("-t",   "--target", type=str, help="Target argument")
    parser.add_argument("-proj",    "--project_path", type=str, default="default", help="Project path argument")
    parser.add_argument("-ver",     "--build_version", type=str, help="Build version argument")
    parser.add_argument("-conc",    "--concurrent_proccess", type=int, help="Number of concurrent processes")
    parser.add_argument("-ec2",     "--ec2_instance_type", type=str, default=DEFAULT_EC2_INSTANCE_TYPE, help="EC2 instance type argument (default: {})".format(DEFAULT_EC2_INSTANCE_TYPE))
    parser.add_argument("-fname",   "--fleet_name", type=str, default=DEFAULT_FLEET_NAME, help="Fleet name argument (default: {})".format(DEFAULT_FLEET_NAME))
    parser.add_argument("-role",    "--rolearn", type=str, help="Role ARN argument")
    parser.add_argument("-ftype",   "--fleet_type", type=str, default=DEFAULT_FLEET_TYPE, help="Fleet type argument (default: {})".format(DEFAULT_FLEET_TYPE))
    parser.add_argument("-prof",    "--profile", type=str, default=DEFAULT_PROFILE, help="AWS Profile argument (default: {})".format(DEFAULT_PROFILE))
    parser.add_argument("-params",  "--parameters", type=str, default=DEFAULT_PROFILE, help="Fleet additional parameters (default: {})".format(DEFAULT_PROFILE))
    args = parser.parse_args()

    deployer = GameLiftDeployer(
        profile=args.profile,
        fleet_name=args.fleet_name,
        build_version=args.build_version,
        target=args.target,
        ec2_instance_type=args.ec2_instance_type,
        fleet_type=args.fleet_type,
        parameters=args.parameters,
        project_path=args.project_path,
        role_arn=args.rolearn,
        concurrent=args.concurrent_proccess)

    deployer.deploy()
