Run terraform apply tfplan
  
module.pilot_medspa.aws_db_subnet_group.clinicflow_db_subnet_group: Modifying... [id=clinicflow-db-subnet-group]
module.pilot_medspa.aws_internet_gateway.clinicflow_igw: Modifying... [id=igw-0ab1b8086481499dc]
module.pilot_medspa.aws_lb.clinicflow_alb: Modifying... [id=arn:aws:elasticloadbalancing:us-east-1:541495491866:loadbalancer/app/ClinicFlow-ALB/800e071bd03a2dda]
╷
│ Error: setting ELBv2 Load Balancer (arn:aws:elasticloadbalancing:us-east-1:541495491866:loadbalancer/app/ClinicFlow-ALB/800e071bd03a2dda) security groups: operation error Elastic Load Balancing v2: SetSecurityGroups, https response error StatusCode: 400, RequestID: 21429dbe-4f9d-48d0-94ed-851e60497daf, InvalidConfigurationRequest: One or more security groups are invalid
│ 
│   with module.pilot_medspa.aws_lb.clinicflow_alb,
│   on modules/clinicflow-vault/compute.tf line 2, in resource "aws_lb" "clinicflow_alb":
│    2: resource "aws_lb" "clinicflow_alb" {
│ 
╵
╷
│ Error: updating RDS DB Subnet Group (clinicflow-db-subnet-group): operation error RDS: ModifyDBSubnetGroup, https response error StatusCode: 400, RequestID: 81d38264-2684-4233-99b2-aa4287b61c21, api error InvalidParameterValue: The new Subnets are not in the same Vpc as the existing subnet group
│ 
│   with module.pilot_medspa.aws_db_subnet_group.clinicflow_db_subnet_group,
│   on modules/clinicflow-vault/database.tf line 4, in resource "aws_db_subnet_group" "clinicflow_db_subnet_group":
│    4: resource "aws_db_subnet_group" "clinicflow_db_subnet_group" {
│ 
╵
╷
│ Error: updating EC2 Internet Gateway (igw-0ab1b8086481499dc): attaching EC2 Internet Gateway (igw-0ab1b8086481499dc) to VPC (vpc-0867358f77f706712): operation error EC2: AttachInternetGateway, https response error StatusCode: 400, RequestID: 17f5add2-8bca-42bd-81ca-225dea1e1ff8, api error InvalidParameterValue: Network vpc-0867358f77f706712 already has an internet gateway attached
│ 
│   with module.pilot_medspa.aws_internet_gateway.clinicflow_igw,
│   on modules/clinicflow-vault/network.tf line 83, in resource "aws_internet_gateway" "clinicflow_igw":
│   83: resource "aws_internet_gateway" "clinicflow_igw" {
│ 
╵
Error: Terraform exited with code 1.
Error: Process completed with exit code 1.# Network Adoption Complete: 2026-05-23
