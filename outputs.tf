output "my_vpc" {
  value = aws_vpc.my-vpc.id
}

output "aws_internet_gateway" {
  value = aws_internet_gateway.my_internet_gateway.id
}

output "aws_nat_gateway" {
  value = aws_nat_gateway.nat_gateway_my_vpc.id
}