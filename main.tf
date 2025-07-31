provider "aws" {
  region     = "us-east-2"
}

resource "aws_elastic_beanstalk_application" "testapp" {
  name        = "test"
  description = "Sample Test Application"
}

resource "aws_iam_role" "role" {
  name = "test_role_new"
  path = "/"

  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                "Service": "ec2.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
    EOF
}

resource "aws_iam_instance_profile" "subject_profile" {
  name = "test_role_new"
  role = aws_iam_role.role.name
}


resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier",
  ])

  role       = aws_iam_role.role.name
  policy_arn = each.value
}

resource "aws_s3_object" "app_zip" {
  bucket = "elasticbeanstalk-us-east-2-504649076991"
  key    = "node-app.zip"
  source = "./node-app.zip"
  etag   = filemd5("./node-app.zip")
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.testapp.name
  description = "First version"

  bucket = aws_s3_object.app_zip.bucket
  key    = aws_s3_object.app_zip.key
  
}

resource "aws_elastic_beanstalk_environment" "testenv" {
  name                = "testenvironment"
  application         = aws_elastic_beanstalk_application.testapp.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.6.0 running Node.js 22"
  version_label = aws_elastic_beanstalk_application_version.app_version.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.subject_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "MONGO_URI"
    value     = "mongodb+srv://Ahmad:pass123@cluster0.tf6bj.mongodb.net/pagination-node"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200"
  }

  setting {
  namespace = "aws:elasticbeanstalk:environment:process:default"
  name      = "HealthCheckPath"
  value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = 1
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = 2
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
}
