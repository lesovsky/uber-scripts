dnf install awscli
aws configure

aws ec2 create-key-pair --key-name NAME				# generate keypair for instances 

# create security group
aws ec2 create-security-group --dry-run --group-name GROUPNAME --description "postgresql-consulting"

# add rule to security group
aws ec2 authorize-security-group-ingress --dry-run --group-name GROUPNAME --protocol tcp --port 22 --cidr a.b.c.d/ee

# create an instance
aws ec2 run-instances --image-id AMI-ID --instance-type TYPE --key-name KEY --security-group-ids sg-xxxxxxxx --associate-public-ip-address

# add label to the instance
aws ec2 create-tags --resources i-xxxxxxxx --tags Key=Name,Value=MyInstance
