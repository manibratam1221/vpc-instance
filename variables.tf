variable "region" {
  type = string
  description = "region details"
}

variable "ami" {
  type = string
  description = "ami information"
}

variable "ec2_type" {
  type = string
  description = "new ec2"
  validation {
    condition = var.ec2_type == "t2.micro"
    error_message = "Not an allowed type : it should be micro"
  }
}