variable "bastion_public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/terraform.pub
DESCRIPTION
  default     = "./bastion.pub"
}

variable "application_public_key_path" {
  description = "SSH public key for all public servers"
  default     = "./app.pub"
}

variable "key_name1" {
  description = "Desired name of AWS key pair"
}

variable "key_name2" {
  description = "Desired name of AWS key pair"
}

variable "bastion_private_pem" {
  description = "Desired name of AWS key pair"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

# Ubuntu Bionic 18.04 LTS (x64)
variable "aws_amis" {
  default = {
    eu-west-1 = "ami-0c259a97cbf621daf"
    us-east-1 = "ami-033b95fb8079dc481"
    us-west-1 = "ami-0558dde970ca91ee5"
    us-west-2 = "ami-0bdef2eb518663879"
  }
}
