provider "aws" {
  region = "your_aws_region"
}

variable "schedule_expression" {
  default = "cron(0 8 ? * MON-FRI *)" # Start at 08:00 UTC on weekdays
}

variable "tag_key" {
  default = "AutoStartStop"
}

variable "tag_value" {
  default = "true"
}

resource "aws_cloudwatch_event_rule" "start_stop_rule" {
  name                = "EC2StartStopRule"
  schedule_expression = var.schedule_expression

  tags = {
    Name = "EC2StartStopRule"
  }
}

resource "aws_cloudwatch_event_target" "start_stop_target" {
  rule      = aws_cloudwatch_event_rule.start_stop_rule.name
  target_id = "StartStopEC2Instances"
  arn       = "arn:aws:lambda:your_aws_region:your_account_id:function:start_stop_ec2_lambda"
}

resource "aws_lambda_function" "start_stop_lambda" {
  filename      = "lambda_function_payload.zip"
  function_name = "start_stop_ec2_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_iam_role" "lambda_role" {
  name = "StartStopEC2LambdaRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "LambdaEC2StartStopPolicyAttachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "LambdaEC2StartStopPolicy"
  description = "Policy to start and stop EC2 instances"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "ec2:StartInstances",
          "ec2:StopInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "logs:CreateLogGroup"
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/start_stop_ec2_lambda:*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_custom_policy_attachment" {
  name       = "LambdaCustomPolicyAttachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}
