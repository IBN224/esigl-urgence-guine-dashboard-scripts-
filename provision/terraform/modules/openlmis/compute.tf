resource "aws_instance" "app" {
  ami                    = "ami-cd0f5cb6"
  instance_type          = var.app-instance-type
  key_name               = var.app-instance-ssh-key-name
  subnet_id              = "subnet-0c7fa301d3d414ca1"
  vpc_security_group_ids = [var.vpc-security-group-id]

  tags = {
    Name        = "${var.name}-env"
    BillTo      = var.bill-to
    Type        = "Guinea"
    DeployGroup = var.app-instance-group
  }

  volume_tags = {
    BillTo = var.bill-to
    Type   = "Guinea"
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.app-volume-size
    delete_on_termination = "true"
  }
}

resource "null_resource" "deploy-docker" {
  depends_on = [aws_instance.app]


  connection {
    user = var.app-instance-ssh-user
    host = aws_instance.app.public_ip
  }

  provisioner "remote-exec" {
    inline = ["ls"]
    connection {
      type = "ssh"
      host = aws_instance.app.public_ip
      user = var.app-instance-ssh-user
    }
  }

  provisioner "local-exec" {
    command = "cd ${var.docker-ansible-dir} && mkdir -p vendor/roles && ansible-galaxy install -p vendor/roles -r requirements/galaxy.yml"
  }

  provisioner "local-exec" {
    command = <<EOF
cd ${var.docker-ansible-dir} && \
  ansible-playbook -vvvv -i inventory docker.yml \
    -e docker_dockerd_tls_port=${var.docker-tls-port} \
    -e docker_tls_aws_access_key_id=\"${var.app-tls-s3-access-key-id}\" \
    -e docker_tls_aws_secret_access_key=\"${var.app-tls-s3-secret-access-key}\" \
    -e docker_tls_dns_name=${var.app-dns-name} \
    -e ansible_ssh_user=${var.app-instance-ssh-user} \
    -e olmis_db_username=${var.olmis-db-username} \
    -e olmis_db_password=${var.olmis-db-password} \
    -e use_rds=false \
    --limit ${aws_instance.app.public_ip}
EOF
  }
}
