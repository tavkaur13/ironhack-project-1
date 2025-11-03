variable "ami_image_name" {
  description = "The AMI ID for the EC2 instances we are creating"
  type        = string
  default     = "ami-07d9b9ddc6cd8dd30"
}

variable "instance_type" {
  description = "The instance type for the EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "The name of the AWS key pair to use for SSH access"
  type        = string
}
 variable "aws_region" {
  description	= "The name of AWS region where the infrastructure will run"
  type		= string
  default	= "us-east-1"
}
