################################################################
# Provider Configuration
################################################################

provider "aws"  {
  region     = "us-east-2"
  access_key = "AKIA6NZZHG62M6QY3G74"
  secret_key = "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"
}

################################################################
# variable declaration
################################################################

variable "database" {
        default = "wordpress"
                }

variable "db_user" {
        default = "wpuser"
                }

variable "db_password" {
        default = "admin123"
                }

variable "db_port" {
        default = "3306"
                }


################################################################
# VPC creation
################################################################

resource "aws_vpc" "blog" {
  cidr_block       = "172.18.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "blog"
  }
}


################################################################
#public subnet - 1  creation
################################################################

resource "aws_subnet" "blog-public1" {
  vpc_id     = aws_vpc.blog.id
  cidr_block = "172.18.0.0/18"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "blog-public1"
  }
}

################################################################
#public subnet - 2  creation
################################################################

resource "aws_subnet" "blog-public2" {
  vpc_id     = aws_vpc.blog.id
  cidr_block = "172.18.64.0/18"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "blog-public2"
  }
}

################################################################
#private subnet - 1  creation
################################################################

resource "aws_subnet" "blog-private1" {
  vpc_id     = aws_vpc.blog.id
  cidr_block = "172.18.128.0/18"
  availability_zone = "us-east-2c"
  tags = {
    Name = "blog-private1"
  }
}

################################################################
#private subnet - 2  creation
################################################################


resource "aws_subnet" "blog-private2" {
  vpc_id     = aws_vpc.blog.id
  cidr_block = "172.18.192.0/18"
  availability_zone = "us-east-2a"
  tags = {
    Name = "blog-private2"
  }
}

################################################################
#internet gateway  creation
################################################################


resource "aws_internet_gateway" "blog-igw" {
  vpc_id = aws_vpc.blog.id

  tags = {
    Name = "blog-igw"
  }
}

################################################################
#public route table  creation
################################################################

resource "aws_route_table" "blog-public-RT" {
  vpc_id = aws_vpc.blog.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.blog-igw.id
        }
   tags = {
        Name ="blog-public-RT"
        }
}


################################################################
#public route table  association
################################################################

resource "aws_route_table_association" "blog-public-RT" {
  subnet_id      = aws_subnet.blog-public1.id
  route_table_id = aws_route_table.blog-public-RT.id
}

################################################################
#public subnet 2 and  route table  association
################################################################

resource "aws_route_table_association" "blog-public2-RT" {
  subnet_id      = aws_subnet.blog-public2.id
  route_table_id = aws_route_table.blog-public-RT.id
}


################################################################
#eip creation
################################################################

resource "aws_eip" "nat" {
  vpc      = true
  tags = {
    Name = "blog-eip"
  }
}

################################################################
#nat gateway creation
################################################################


resource "aws_nat_gateway" "blog-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.blog-public2.id

  tags = {
    Name = "blog-NAT"
  }
}

################################################################
#private route table  creation
################################################################

resource "aws_route_table" "blog-private-RT" {
  vpc_id = aws_vpc.blog.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.blog-nat.id
  }

  tags = {
    Name = "blog-private-RT"
         }
}


################################################################
#private subnet 1 to route table  association
################################################################

resource "aws_route_table_association" "blog-private1-RT" {
  subnet_id      = aws_subnet.blog-private1.id
  route_table_id = aws_route_table.blog-private-RT.id
}


################################################################
#private subnet 2 to route table  association
################################################################

resource "aws_route_table_association" "blog-private1-RT2" {
  subnet_id      = aws_subnet.blog-private2.id
  route_table_id = aws_route_table.blog-private-RT.id
}

################################################################
#keypair
################################################################

resource "aws_key_pair" "ohio-server" {
  key_name   = "ohio-server"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoAJL9mho3P4BoYoeohHaTuJiFLODTaSDsTBNpZHVZrFax4PQtUf2QqXC03ojFM19HTHv7+HjN8A90L/NIey7m62Y4T3ITFoPQR2HAh3uCjLWp1TbzzBmQzNB04u9rYabG3bys48hDM+/aN3Gad+uaAbXYlMNojHI0twMbTRd2WqXMRIeyPRPKvcFXzXt08Q3O2hjBLggJAAlc7jP6JsgAxTWUWLKzeq5+McjJ8yE0gKvRGxwGiCVJszxoR1IkIXyRsHQKaV/BId2Gol3f8ixhV3psLeybiLONeoBhMqxklAYoCEulwANh/6BiEDFe4W4Ta3xsdIOjhvY77HLnU+vd root@ip-172-31-38-199.us-east-2.compute.internal"
}




################################################################
#security group for bastion
################################################################

resource "aws_security_group" "blog-bastion" {
  name        = "ssh access"
  description = "Allow 22 from all"
  vpc_id      = aws_vpc.blog.id

  ingress {
    description = "allow 22 from all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "allow from all"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-bastion"
  }
}


################################################################
#security group for webserver
################################################################

resource "aws_security_group" "blog-webserver" {
  name        = "webserver access"
  description = "Allow 80 from all, 22 from bastion"
  vpc_id      = aws_vpc.blog.id

  ingress {
    description = "allow 80 from all"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow 443 from all"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "allow 22 from all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.blog-bastion.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-webserver"
  }
}


################################################################
#security group for database server
################################################################

resource "aws_security_group" "blog-database" {
  name        = "database access"
  description = "Allow 22 from bastion, 3306 from webserver"
  vpc_id      = aws_vpc.blog.id

  ingress {
    description = "allow 22 from all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.blog-bastion.id]
  }

ingress {
    description = "allow 3306 from webserver"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.blog-webserver.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-database"
  }
}


################################################################
#bastion server creation
###############################################################

resource "aws_instance" "bastion" {
  ami           = "ami-09558250a3419e7d0"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ohio-server.id
  subnet_id = aws_subnet.blog-public2.id
  vpc_security_group_ids = [aws_security_group.blog-bastion.id]
  user_data = file("setup.sh")


  tags = {
    Name = "bastion"
  }
}

################################################################
#webserver server creation
################################################################

resource "aws_instance" "webserver" {
  ami           = "ami-0be67fbef55da254f"
  instance_type = "t2.micro"
  key_name = aws_key_pair.ohio-server.id
  subnet_id = aws_subnet.blog-public1.id
  vpc_security_group_ids = [aws_security_group.blog-webserver.id]
  tags = {
    Name = "webserver"
  }

provisioner "file" {

 content = templatefile("wp-config.php.tmp", {
                        db_name = var.database,
                        db_user = var.db_user,
                        db_pass = var.db_password,
                        db_port = var.db_port
                        db_host = aws_db_instance.blog-db.address
                        }
                        )

   destination = "/tmp/wp-config.php"
   
    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("ohio-server")
    host     = aws_instance.webserver.private_ip

    bastion_host = aws_instance.bastion.public_ip
    bastion_user     = "ec2-user"
    bastion_private_key = file("ohio-server")
    bastion_port = "7096"
  }
}

provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/wp-config.php /var/www/html/wp-config.php"
    ]

 

    connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("ohio-server")
    host     = aws_instance.webserver.private_ip

    bastion_host = aws_instance.bastion.public_ip
    bastion_user     = "ec2-user"
    bastion_private_key = file("ohio-server")
    bastion_port = "7096"
  }
 }

}


################################################################
#database subnet creation
################################################################

resource "aws_db_subnet_group" "blogdb-subnet" {
  name       = "blogdbsubnet"
  subnet_ids = [aws_subnet.blog-private1.id, aws_subnet.blog-private2.id]

  tags = {
    Name = "Blogdb-subnet"
  }
}

################################################################
#database server creation
################################################################

resource "aws_db_instance" "blog-db" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = var.database
  username             = var.db_user
  password             = var.db_password
  port                 = var.db_port
  parameter_group_name = "default.mysql5.7"
  deletion_protection = false
  apply_immediately = true
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.blogdb-subnet.id
  vpc_security_group_ids = [aws_security_group.blog-database.id]

  tags = {
        Name = "blog-db"
}
}

