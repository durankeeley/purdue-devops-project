resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [${replace(local.jenkins_server.name, "-", "_")}]
    ${aws_instance.jenkins_server.public_ip} ansible_user=ec2-user

    [${replace(local.monitoring_server.name, "-", "_")}]
    ${aws_instance.monitoring_server.public_ip} ansible_user=ec2-user
    EOT
  filename = "../ansible/inventory"

  depends_on = [aws_instance.jenkins_server]
}

resource "null_resource" "sshcheck_jenkins" {
  provisioner "remote-exec" {
    inline = [
      "echo 'Jenkins server is up and running! on ${aws_instance.jenkins_server.public_ip}'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_ed25519")
      host        = aws_instance.jenkins_server.public_ip
    }
  }

  depends_on = [aws_instance.jenkins_server]
}

resource "null_resource" "sshcheck_monitoring" {
  provisioner "remote-exec" {
    inline = [
      "echo 'Monitoring server is up and running! on ${aws_instance.monitoring_server.public_ip}'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_ed25519")
      host        = aws_instance.monitoring_server.public_ip
    }
  }

  depends_on = [aws_instance.monitoring_server]
}

resource "null_resource" "configure_jenkins" {
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../ansible/inventory ../ansible/config-playbook/jenkins-setup.yml --private-key ~/.ssh/id_ed25519"
  }

  depends_on = [local_file.ansible_inventory, null_resource.sshcheck_jenkins]
}

resource "null_resource" "configure_monitoring" {
    provisioner "local-exec" {
      command = <<-EOT
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i ../ansible/inventory \
        -l ec2_monitoring_server \
        ../ansible/config-playbook/monitoring-setup.yml \
        --private-key ~/.ssh/id_ed25519
      EOT
    }

  depends_on = [local_file.ansible_inventory,
                aws_instance.monitoring_server,
                null_resource.sshcheck_monitoring,
                aws_eks_cluster.main,
                aws_eks_node_group.main,
                aws_eks_access_entry.monitoring_access,
                aws_eks_access_policy_association.monitoring_admin_access,
                ]
}

# resource "null_resource" "configure_jenkins" {
#   provisioner "local-exec" {
#     command = "../go-batect_x64_84 configure-jenkins --file ../batect.yml"
#   }

#   depends_on = [local_file.ansible_inventory, null_resource.sshcheck_jenkins]
# }

# resource "null_resource" "configure_monitoring" {
#     provisioner "local-exec" {
#         command = "../go-batect_x64_84 configure-monitoring --file ../batect.yml"
#     }

#   depends_on = [local_file.ansible_inventory, null_resource.sshcheck_monitoring]
# }
