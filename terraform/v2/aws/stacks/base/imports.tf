import {
  to = module.network.aws_vpc.main
  id = "vpc-084f479ca5550d37f"
}

import {
  to = module.network.aws_internet_gateway.igw
  id = "igw-089e0a2d432fed71a"
}

import {
  to = module.network.aws_subnet.public[0]
  id = "subnet-05497c61608e97214"
}

import {
  to = module.network.aws_route_table.public
  id = "rtb-0afa82b7a4938ea3b"
}

import {
  to = module.network.aws_route.public_internet
  id = "rtb-0afa82b7a4938ea3b_0.0.0.0/0"
}

import {
  to = module.network.aws_route_table_association.public[0]
  id = "subnet-05497c61608e97214/rtb-0afa82b7a4938ea3b"
}

##############################
# RDS
##############################
import {
  to = module.rds.aws_db_instance.main
  id = "daeng-map-rds"
}

import {
  to = module.rds.aws_db_subnet_group.main
  id = "default-vpc-084f479ca5550d37f"
}

import {
  to = module.rds.aws_security_group.rds
  id = "sg-08ca54a62f245502b"
}