# Create a SNS topic 

data "aws_partition" "current" {} 
data "aws_region" "curent" {} 
data "aws_caller_identity" "current" {} 

data "aws_iam_policy_document" "sns_topic_policy" { 
  policy_id = "__default_policy_ID__"

  statement {
    actions = [ 
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
      "SQS:SendMessage",
    ]

    condition {
      test = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        "data.aws_partition.curent.partition",
      ]
    }

    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.test.arn, 
    ]
  }

}

data "aws_iam_policy_document" "main" {
  statement { 
    effect = "Allow"

    actions = [ 
      "sns:Publish",
      "sqs:SendMessage",
    ]

    resources = ["*"]
    
  }
}

resource "aws_sns_topic" "test" {
  name = "test-topic-with-policy"
}

resource "aws_sns_topic_policy" "sns_topic_test" {
  arn = aws_sns_topic.test.arn 

  policy = data.aws_iam_policy_document.sns_topic_policy.json 
  
}

# Create Lambda Function 

data "aws_iam_policy_document" "assume_role" { 
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals { 
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "main" {
  name = "SNS-TOPIC-TEST-Role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "main" {
  name = "SNS-TOPIC-TEST-Policy"
  role = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.main.json
}

data "archive_file" "lambda" { 
  type = "zip"
  source_dir = "${path.module}/lambda_function/src"
  output_path = "${path.module}/lambda_function/dist/lambda_function.zip"
}

resource "aws_lambda_function" "function" {
  function_name = "SNS-TOPIC-TEST"
  runtime = "python3.8"
  role = aws_iam_role.main.arn
  handler = "lambda_function.lambda_handler" 
  memory_size = 128 
  timeout = 60
  filename = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256 

  environment {
    variables = {
      "SLACK_URL" = var.slack_url
    }
  }

  dead_letter_config {
    target_arn = aws_sns_topic.test.arn 
  }

  depends_on = [
    aws_sns_topic.test
  ]

}



