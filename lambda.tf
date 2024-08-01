# Create the Lambda Function to Rotate the Secret
resource "aws_lambda_function" "rotation_lambda" {
  filename         = data.archive_file.rotation_lambda_zip.output_path
  function_name    = "rotation-lambda-${random_string.random.id}"
  description      = "A lambda function to rotate the secret"
  architectures    = ["arm64"]
  role             = aws_iam_role.rotation_lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  source_code_hash = data.archive_file.rotation_lambda_zip.output_base64sha256
  environment {
    variables = {
      SECRET_NAME = aws_secretsmanager_secret.apikey.name
      TOPIC_ARN   = aws_sns_topic.sns_topic.arn
    }
  }
}

# Allow the Lambda Function to Access the Secret
resource "aws_lambda_permission" "allow_secretsmanager" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.apikey.arn
}

# Create the IAM Role for the Lambda Function
resource "aws_iam_role" "rotation_lambda_role" {
  name = "lambda-role-${random_string.random.id}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create the IAM Policy for the Lambda Function
resource "aws_iam_policy" "rotation_lambda_policy" {
  name = "lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      },
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:PutSecretValue"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.apikey.arn
      },
      {
        Action = [
        "kms:Decrypt",
        "kms:Encrypt"
        ]
        Effect = "Allow"
        Resource = aws_kms_key.apikey.arn
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = aws_sns_topic.sns_topic.arn
      }
    ]
  })
}

# Attach the IAM Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "rotation_lambda_policy_attach" {
  role       = aws_iam_role.rotation_lambda_role.name
  policy_arn = aws_iam_policy.rotation_lambda_policy.arn
}

# Allow the Lambda Function to Publish to the SNS Topic
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_topic.arn
}
