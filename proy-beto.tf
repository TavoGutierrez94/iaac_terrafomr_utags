provider "aws" {
  region = "us-east-1"
}

#crearemos la vpc junto con sus subredes
resource "aws_vpc" "PROYECTOBETO" {
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = "PROYECTOBETO"
    }      
}

#se crearan 2 subredes publicas
resource "aws_subnet" "PB-SUBREDPUBLIC1" {

    vpc_id = aws_vpc.PROYECTOBETO.id #la ligamos a la vpc
    cidr_block = "10.0.16.0/20"
    availability_zone = "us-east-1b" 

    tags = {
      "Name" = "PB-SUBREDPUBLIC1"
    }  
}

resource "aws_subnet" "PB-SUBREDPUBLIC2" {

    vpc_id = aws_vpc.PROYECTOBETO.id #la ligamos a la vpc
    cidr_block = "10.0.128.0/20"
    availability_zone = "us-east-1a" 

    tags = {
      "Name" = "PB-SUBREDPUBLIC2"
    }  
}

#se crearan 2 subredes privadas
resource "aws_subnet" "PB-SUBREDPRIV1" {
    vpc_id = aws_vpc.PROYECTOBETO.id #la ligamos a la vpc
    cidr_block = "10.0.144.0/20"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "SUBNET-PRIVATE"
    }
  
}

resource "aws_subnet" "PB-SUBREDPRIV2" {
    vpc_id = aws_vpc.PROYECTOBETO.id #la ligamos a la vpc
    cidr_block = "10.0.0.0/20"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "SUBNET-PRIVATE"
    }
  
}

#creamos un ig para la salida a internet
resource "aws_internet_gateway" "IGW-PB" {
    vpc_id = aws_vpc.PROYECTOBETO.id #la ligamos a la vpc

    tags = {
      "name" = "IGW-PB"
    }
}

#se crean las tablas de ruteo para la subred publica 1
resource "aws_route_table" "TR-SUBPUBLICA" {
    vpc_id = aws_vpc.PROYECTOBETO.id #la asociamos a la vpc

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW-PB.id #la asociamos a la IG
    }

    tags = {
      "Name" = "TR-SUBPUBLICA"
    }
  
}
#creamos la asociacion entre la tabla y la subred 
resource "aws_route_table_association" "TR-ASSOS-SUBPUB1" {
    subnet_id = aws_subnet.PB-SUBREDPUBLIC.id #la asociamos a la subred publica 1
    route_table_id = aws_route_table.TR-SUBPUBLICA.id  #y a la tabla de ruteo 1
}


#se crean las tablas de ruteo para la subred publica 2
resource "aws_route_table" "TR-SUBPUBLICA2" {
    vpc_id = aws_vpc.PROYECTOBETO.id #la asociamos a la vpc

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.IGW-PB.id #la asociamos a la IG
    }

    tags = {
      "Name" = "TR-SUBPUBLICA2"
    }  
}
#creamos la asociacion entre la tabla y la subred 
resource "aws_route_table_association" "TR-ASSOS-SUBPUB2" {
    subnet_id = aws_subnet.PB-SUBREDPUBLIC2.id  #la asociamos a la subred publica 2
    route_table_id = aws_route_table.TR-SUBPUBLICA2.id #y a la tabla de ruteo 2
}

#creamos una elactic ip para la subred publica 1
resource "aws_eip" "EI-SEBPUB" {
    vpc = true

    tags = {
        Name = "EI-SEBPUB"
    }  
}
#creamos una NAT GATEWAY
resource "aws_nat_gateway" "NW-PUBLIC" {
    allocation_id = aws_eip.EI-SEBPUB.id #le asociamos la ip elastica
    subnet_id = aws_subnet.PB-SUBREDPUBLIC1.id #y a la subred publica 1

    tags = {
      "Name" = "NW-PUBLIC"
    }
}


#se crean las tablas de ruteo para la subred privada 1
resource "aws_route_table" "TR-SUBPRIV11" {
      vpc_id = aws_vpc.PROYECTOBETO.id #la asignamos a la vpc
      route {
          cidr_block = "0.0.0.0/0"
          nat_gateway_id = aws_nat_gateway.NW-PUBLIC.id #y le creamos unas ruta hacia la nat gateway
      }
      tags = {
        "Name" = "TR-SUBPRIV1"
      }
}

#creamos la asociacion entre la tabla y la subred privada
resource "aws_route_table_association" "TR-ASSOS-SUBPRIV1" {
    subnet_id = aws_subnet.PB-SUBREDPRIV1.id #la asociamos a la subred privada 1
    route_table_id = aws_route_table.TR-SUBPRIV1.id  #y a la tabla de ruteo 1
}
#se crean las tablas de ruteo para la subred privada 2
resource "aws_route_table" "TR-SUBPRIV2" {
    vpc_id = aws_vpc.PROYECTOBETO.id #la asignamos a la vpc

    route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.NW-PUBLIC.id #y le creamos unas ruta hacia la nat gateway
    }
    
    tags = {
      "Name" = "TR-SUBPRIV2"
    }  
}
#creamos la asociacion entre la tabla y la subred privada
resource "aws_route_table_association" "TR-ASSOS-SUBPRIV2" {
    subnet_id = aws_subnet.PB-SUBREDPRIV2.id #la asociamos a la subred privada 2
    route_table_id = aws_route_table.TR-SUBPRIV2.id  #y a la tabla de ruteo 2
}
#hasta aqui es el tema de las redes

#grupos de seguridad
resource "aws_security_group" "SG-WEBSERVER" {
    name = "TRAFICOPERMITIDO"
    description = "TRAFICOPERMITIDO"
    vpc_id = aws_vpc.PROYECTOBETO.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    ingress {
      from_port = 8
      to_port = 0
      protocol = "icmp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all ping"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "SG-WEBSERVER"
    }
}



resource "aws_network_interface" "NIC-LINUX" {
    subnet_id = aws_subnet.PB-SUBREDPUBLIC.id
    private_ips = ["10.0.16.100"]
    security_groups = [aws_security_group.SG-WEBSERVER.id]  
}


resource "aws_network_interface" "NIC-LINUX-PRIVATE-A" {
    subnet_id = aws_subnet.PB-SUBREDPRIV1.id
    private_ips = ["10.0.144.100"]
    security_groups = [aws_security_group.SG-WEBSERVER.id]   
}

resource "aws_network_interface" "NIC-LINUX-PRIVATE-B" {
    subnet_id = aws_subnet.PB-SUBREDPRIV2.id
    private_ips = ["10.0.1.100"]
    security_groups = [aws_security_group.SG-WEBSERVER.id]
}





resource "aws_eip" "EIP-LINUX" {
    vpc = true
    network_interface = aws_network_interface.NIC-LINUX.id
    associate_with_private_ip = "10.0.16.100"
    depends_on = [
      aws_internet_gateway.IGW-PB
    ]  
}



output "SERVER-PUBLIC-IP" {
    value = aws_eip.EIP-LINUX   
}


resource "aws_instance" "EC2-LINUX" {
    ami = "ami-06b7b9ae8f52163ab"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "linux2"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LNX.id
    }

    tags = {
      "Name" = "EC2-LINUX"
    }
     
}



resource "aws_instance" "EC2-LNX-P-B" {
    ami = "ami-000b7add9cfe1e0fe"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "web-demo"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.NIC-LNX-PB-SUBREDPRIV2.id
    }

    user_data = <<-EOF
            #!/bin/bash            
            sudo systemctl enable httpd
            sudo systemctl start httpd
            EOF


    tags = {
      "Name" = "EC2-LNX-P-B"
    }
     
}


output "MY-SERVER-PRIVATE-IP" {
    value = aws_instance.EC2-LINUX.private_ip  
}


output "server_id" {
    value = aws_instance.EC2-LINUX.id  
}







resource "aws_security_group" "LOADBALANCER-SG" {
    name = "Allow_Traffic_LB"
    description = "Allow_Traffic_LB"
    vpc_id = aws_vpc.PROYECTOBETO.id

    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      "Name" = "LOADBALANCER-SG"
    }
}





resource "aws_lb" "LOADBALANCER-CLASES" {
  name = "LOADBALANCER-CLASES"
  internal = false
  ip_address_type = "ipv4"
  load_balancer_type = "application"
  subnets = [aws_subnet.PB-SUBREDPUBLIC.id, aws_subnet.PB-SUBREDPUBLIC-B.id]

  security_groups = [aws_security_group.LOADBALANCER-SG.id]

  tags = {
    "Name" = "LOADBALANCER-BETO"
  }
  
}


resource "aws_lb_target_group" "TARGET-GROUP-LB" {
  name = "TARGET-GROUP-LB"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.PROYECTOBETO.id
  
  # stickiness {
  #   type = "lb_cookie"
  # }

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 10    
  }  
}

resource "aws_lb_listener" "LISTENER-WEB-CLASES" {
  load_balancer_arn = aws_lb.LOADBALANCER-BETO.arn
  port = "80" 
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TARGET-GROUP-LB.arn
    type = "forward"
  }  
}

resource "aws_lb_target_group" "TARGET-GROUP-CLASES" {
  name = "TARGET-GROUP-CLASES"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.PROYECTOBETO.id  
}




resource "aws_lb_target_group_attachment" "ATTACH-TARGET-G1" {
  count = 2
  target_group_arn = aws_lb_target_group.TARGET-GROUP-CLASES.arn
  target_id = aws_instance.EC2-LNX-P-B.id
  # target_id = "${element(split(",", join(",", aws_instance.EC2-LINUX-PRIVATE.*.id)), count.index)}"
} 
resource "aws_lb_target_group_attachment" "ATTACH-TARGET-G2" {
  count = 2
  target_group_arn = aws_lb_target_group.TARGET-GROUP-CLASES.arn
  target_id = aws_instance.EC2-LNX-P-A.id  
}