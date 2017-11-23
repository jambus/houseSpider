#!/bin/bash
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "JSpider build script start to run to build the aws ec2 instance..."

#echo "Encoding the install-software script with base64"
#base64 install-software > install-software64

if [ $# -lt 1 ]; then
	echo "Use aws profile: ${green}Default${reset}"
else
	echo "Use aws profile: ${green}$1${reset}"
	export AWS_PROFILE=$1
fi

instanceSecurityGroup=`aws ec2 describe-security-groups --group-names ec2-spider-securitygroup --query 'SecurityGroups[0].GroupId'`
if [ $? -ne 0 ]; then
	instanceSecurityGroup=`aws ec2 create-security-group --group-name ec2-spider-securitygroup --description "ec2-spider security group" --query 'GroupId' | sed 's/"//g'`

	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 22 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 5000 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 80 --cidr 0.0.0.0/0
	aws ec2 authorize-security-group-ingress --group-name ec2-spider-securitygroup --protocol tcp --port 5432 --cidr 0.0.0.0/0

	echo "Security group created: ${green}$instanceSecurityGroup${reset}"
else
	instanceSecurityGroup=`echo $instanceSecurityGroup | sed 's/"//g'`
	echo "Security group used: ${green}$instanceSecurityGroup${reset}"
fi

instanceResourceId=`aws ec2 run-instances --image-id ami-15872773 --count 1 --instance-type t2.micro --key-name jambus2018-ec2 --security-group-ids $instanceSecurityGroup \
	--query 'Instances[0].InstanceId' \
	--user-data file://install-software | sed 's/"//g'` 

#instanceResourceId=`aws ec2 run-instances --profile $1 --image-id ami-15872773 --count 1 --instance-type t2.micro --key-name jambus2018-ec2 --security-group-ids sg-c02bdab9 \
#--query 'Instances[0].InstanceId' \
#--user-data file://install-software | sed 's/"//g'`

echo "Instance Resource ID created: ${green}$instanceResourceId${reset}"
aws ec2 create-tags --resources $instanceResourceId --tags Key=Name,Value=jambus_spider

instancePublicDNS=`aws ec2 describe-instances --instance-ids $instanceResourceId --query 'Reservations[0].Instances[0].PublicDnsName' | sed 's/"//g'`
#aws ec2 describe-instances --filters "Name=tag:Name,Values=jambus_spider" --query 'Reservations[0].Instances[0].PublicDnsName' | sed 's/"//g' | xargs -I {} echo "ssh -i ~/jambus2018-ec2.pem ubuntu@{}"
#aws ec2 describe-instances --instance-ids $instanceResourceId --query 'Reservations[0].Instances[0].PublicDnsName' | sed 's/"//g' | xargs -I {} echo "${green}ssh -i ~/jambus2018-ec2.pem ubuntu@{}${reset}"
echo "EC2 instance start to create. PublicDnsName is: ${green}$instancePublicDNS${reset}"
echo "Use below command to connect with SSH:"
echo "${green}ssh -i ~/jambus2018-ec2.pem ubuntu@$instancePublicDNS${reset}"

#echo "Clean up temp files"
#rm install-software64
