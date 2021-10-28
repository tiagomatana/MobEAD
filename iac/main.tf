provider "aws" {
    profile = "default"
    region = "sa-east-1"
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" { #PlK7PY5!=$K.kdBDW!5LYRg=Lm%kSSer
  name = "test_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": ["ec2.amazonaws.com", "ssm.amazonaws.com"]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach" {
  role = aws_iam_role.role.name
  policy_arn = aws_iam_policy.decrypt.arn
}

resource "aws_iam_policy" "start" {
  name = "test_policy"
  path = "/"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:StartSession"
            ],
            "Resource": [
                "${aws_instance.webserver.arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:TerminateSession",
                "ssm:ResumeSession"
            ],
            "Resource": [
                "arn:aws:ssm:*:*:session/*"
            ]
        }
    ]
})
}

resource "aws_iam_policy" "decrypt" {
    name = "decrypt"
    path = "/"
    policy = jsonencode({
            "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "*"
        }
    ]
})
}

resource "aws_ssm_activation" "foo" {
  name               = "test_ssm_activation"
  description        = "Test"
  iam_role           = aws_iam_role.role.id
  registration_limit = "5"
  depends_on         = [aws_iam_role_policy_attachment.test_attach]
}

data "aws_ami" "windows" {
    most_recent = true
 
    filter {
        name = "name"
        values = ["Windows_Server-2019-English-Full-Base-*"]
    }

    owners = [ "amazon" ]
}

resource "aws_key_pair" "pubkey" {
    key_name = "tiago-windows"
    public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "webserver" {
    ami = "ami-0b13c507c1f3d8a2f" #data.aws_ami.windows.image_id #"ami-06ab8fe950abb04f5" #"ami-0b13c507c1f3d8a2f"
    instance_type = "t2.micro"
    security_groups = [ aws_security_group.sg-webserver.name ]
    key_name = "mobead-tiago"
    iam_instance_profile = aws_iam_instance_profile.test_profile.name
    
}

resource "aws_security_group" "sg-webserver" {
    name = "Allow ports"
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    } 

}

resource "aws_eip" "elasticip" {
    instance = aws_instance.webserver.id
}

output "eip" {
    value = aws_eip.elasticip.public_ip
}

output "windows" {
    value = data.aws_ami.windows.image_id
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [aws_instance.webserver]

  create_duration = "120s"
}
resource "null_resource" "hosts" {
    provisioner "local-exec" {
        command = "echo '${aws_eip.elasticip.public_ip}' > ./hosts"
    }

    depends_on = [
      time_sleep.wait_120_seconds
    ]
}

# resource "null_resource" "playbook" {
#     provisioner "local-exec" {
#         command = "ansible-playbook -i hosts install_iis.yaml"
#     }

#     depends_on = [
#       null_resource.hosts
#     ]
# }

output "arn" {
    value = aws_instance.webserver.arn
}