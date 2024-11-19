provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "default" {
  key_name   = "my-key-pair"
  public_key = file("./websrv01.pub") # replace with public key path to use
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTPS traffic"

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP traffic for redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316" 
  instance_type = "t2.micro"
  key_name      = aws_key_pair.default.key_name
  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    yum install -y httpd mod_ssl

    # Create a self-signed certificate for demonstration
    mkdir /etc/ssl/private
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /etc/ssl/private/selfsigned.key \
      -out /etc/ssl/private/selfsigned.crt \
      -subj "/C=US/ST=State/L=City/O=Company/OU=Org/CN=example.com"

    # Configure Apache for HTTPS and redirect HTTP to HTTPS
    cat <<EOF > /etc/httpd/conf.d/ssl.conf
    <VirtualHost *:443>
      DocumentRoot "/var/www/html"
      SSLEngine on
      SSLCertificateFile /etc/ssl/private/selfsigned.crt
      SSLCertificateKeyFile /etc/ssl/private/selfsigned.key
    </VirtualHost>

    <VirtualHost *:80>
      RewriteEngine On
      RewriteCond %{HTTPS} off
      RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
    </VirtualHost>
    EOF

    # Create a Hello World web page
    echo "Hello World!" > /var/www/html/index.html

    # Start Apache
    systemctl enable httpd
    systemctl start httpd
  EOT

  tags = {
    Name = "hello-world-web"
  }
}

output "instance_public_dns" {
  value = aws_instance.web.public_dns
  description = "Public DNS of the EC2 instance"
}