# Creating IAM role for Kubernetes clusters to make calls to other AWS services on your behalf to manage the resources that you use with the service.

resource "aws_iam_role" "my-eks-cluster-iam-role" {
  name               = "my-eks-cluster"
  assume_role_policy = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
   }
  ]
 }
POLICY
}
# Attaching the EKS-Cluster policies to the my-eks-cluster-iam-role role.

resource "aws_iam_role_policy_attachment" "my-eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.my-eks-cluster-iam-role.name
}
# Attaching the EKS-Service policies to the my-eks-cluster-iam-role role.
resource "aws_iam_role_policy_attachment" "my-eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.my-eks-cluster-iam-role.name
}


# Security group for network traffic to and from AWS EKS Cluster.
# vpc id is vpc id of where we deploy this eks. either you can create new vpc else you existing vpc
resource "aws_security_group" "my-eks-cluster-security-group" {
  name   = "my-eks-security-group"
  vpc_id = "vpc-0b5cfc803796afb0c"
  # Egress allows Outbound traffic from the EKS cluster to the  Internet
  egress { # Outbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Ingress allows Inbound traffic to EKS cluster from the  Internet

  ingress { # Inbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
# Creating the EKS cluster

resource "aws_eks_cluster" "my-eks-cluster" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.my-eks-cluster-iam-role.arn
  version  = "1.19"

  # Adding VPC Configuration

  vpc_config { # Configure EKS with vpc and network settings
    security_group_ids = [aws_security_group.my-eks-cluster-security-group.id]
    subnet_ids         = ["subnet-06150ebe214de8399", "subnet-02282c8f188d625b5"] # add your private subnet id within your vpc
  }

  depends_on = [
    aws_iam_role_policy_attachment.my-eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.my-eks-cluster-AmazonEKSServicePolicy,
  ]
}
# Creating IAM role for EKS nodes to work with other AWS Services.
resource "aws_iam_role" "my-eks-nodes-iam-role" {
  name = "my-eks-nodes-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


# Attaching the different Policies to Node Members.
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.my-eks-nodes-iam-role
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.my-eks-nodes-iam-role
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.my-eks-nodes-iam-role
}
# Create EKS cluster node group

resource "aws_eks_node_group" "my-eks-cluster-node-group" {
  cluster_name    = aws_eks_cluster.my-eks-cluster.name
  node_group_name = "my-eks-cluster-node-group"
  node_role_arn   = aws_iam_role.my-eks-nodes-iam-role.arn
  subnet_ids      = ["subnet-06150ebe214de8399", "subnet-02282c8f188d625b5"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}