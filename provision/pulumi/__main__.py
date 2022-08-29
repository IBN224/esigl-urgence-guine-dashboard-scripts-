import pulumi
import pulumi_aws as aws

project_name = 'guinea-covid-reporting'
size = 'm5.large'
ami_id = 'ami-04505e74c0741db8d'
vpc_id = 'vpc-0649a716d1c97db1e'

group = aws.ec2.SecurityGroup('guinea-covid-uat-sg',
                              description='Enable HTTP access',
                              ingress=[
                                  {'protocol': 'tcp', 'from_port': 22, 'to_port': 22, 'cidr_blocks': ['0.0.0.0/0']},
                                  {'protocol': 'tcp', 'from_port': 80, 'to_port': 80, 'cidr_blocks': ['0.0.0.0/0']},
                                  {'protocol': 'tcp', 'from_port': 443, 'to_port': 443, 'cidr_blocks': ['0.0.0.0/0']}
                              ],
                              vpc_id=vpc_id)

user_data = """
#!/bin/bash

sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt install -y docker-ce

sudo usermod -aG docker ${USER}
"""

# subnet = aws.ec2.Subnet("gambia-uat-subnet",
#                         vpc_id=vpc_id,
#                         cidr_block="10.10.0.0/24",
#                         availability_zone="us-east-1c",
#                         tags={
#                                "Name": "gambia-uat-subnet",
#                            })
network_interface = aws.ec2.NetworkInterface("guinea-reporting-network-interface",
                                             subnet_id='subnet-0c7fa301d3d414ca1',
                                             private_ips=["10.10.0.250"],
                                             tags={
                                                 "Name": "primary_network_interface2",
                                             })

server = aws.ec2.Instance('guinea-covid-reporting-uat',
                          instance_type=size,
                          user_data=user_data,
                          key_name='TestEnvDockerHosts',
                          ami=ami_id,
                          root_block_device=aws.ec2.InstanceRootBlockDeviceArgs(
                              volume_size=60,
                              volume_type="gp2"
                          ),
                          tags={
                              "Name": "guinea-covid-reporting-stack-uat",
                              "BillTo": "Guinea"
                          },
                          network_interfaces=[aws.ec2.InstanceNetworkInterfaceArgs(
                              network_interface_id=network_interface.id,
                              device_index=0)]
                          )

eip = aws.ec2.Eip("guinea-reporting-uat-ip", vpc=True)
eip_assoc = aws.ec2.EipAssociation("guineaReportingEipAssoc",
                                   instance_id=server.id,
                                   allocation_id=eip.id)

pulumi.export('publicIp', server.public_ip)
pulumi.export('publicHostName', server.public_dns)

print (server.public_ip)