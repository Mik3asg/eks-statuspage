The cluster name lives in the VPC module -> subnet tagging requirements
When TF creates the subnet into main.tf, the cluster name has to be interpolated into that tag key

VPC needs cluster name → to tag subnets
EKS needs subnet IDs → to create the cluster

// main.tf
Maping out the resources we need and dependencies

aws_vpc
    ↓
aws_subnet (public x2, private x2)
    ↓
aws_internet_gateway        aws_eip
        ↓                      ↓
                        aws_nat_gateway
                               ↓
aws_route_table (public)   aws_route_table (private)
        ↓                      ↓
aws_route_table_association (x4)

1. Why do you need an aws_eip (Elastic IP) alongside the NAT Gateway?
2. You need two private subnets and two public subnets — how does Terraform let you create multiple subnets without repeating the resource block four times?
3. The public route table needs a route sending 0.0.0.0/0 to the internet gateway. The private route table needs a route sending 0.0.0.0/0 somewhere else — where, and why?

