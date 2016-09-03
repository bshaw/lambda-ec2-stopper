# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file
# except in compliance with the License. A copy of the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is distributed on an "AS IS"
# BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under the License.
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

# Lambda Role with Required Policy
resource "aws_iam_role_policy" "lambda-ec2-stopper" {
    name = "lambda-ec2-stopper"
    role = "${aws_iam_role.lambda-ec2-stopper.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:StopInstances"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda-ec2-stopper" {
    name = "lambda-ec2-stopper"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
output "lambda-ec2-stopper_role_arn" {
  value = "${aws_iam_role.lambda-ec2-stopper.name}"
}

# Lambda Function
resource "aws_lambda_function" "ec2-stopper" {
    filename = "lambda-ec2-stopper.zip"
    function_name = "ec2-stopper"
    role = "${aws_iam_role.lambda-ec2-stopper.arn}"
    handler = "main.lambda_handler"
    description = "Automatically stops ec2 instances without a specific tag"
    memory_size = 128
    runtime = "python2.7"
    timeout = 300
    source_code_hash = "${base64encode(sha256(file("lambda-ec2-stopper.zip")))}"
}

# CloudWatch Event Rule and Event Target
resource "aws_cloudwatch_event_rule" "ec2-stopper" {
    name = "lambda-ec2-stopper"
    description = "Fires daily at 18:00 UTC"
    schedule_expression = "cron(0 18 * * ? *)"
}

resource "aws_cloudwatch_event_target" "ec2-stopper" {
    rule = "${aws_cloudwatch_event_rule.ec2-stopper.name}"
    target_id = "ec2-stopper"
    arn = "${aws_lambda_function.ec2-stopper.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_ec2-stopper" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.ec2-stopper.arn}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.ec2-stopper.arn}"
}
