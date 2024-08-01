# Create the Secret Manager
resource "aws_secretsmanager_secret" "apikey" {
  name = "apikey-${random_string.random.id}"
  description = "My API key"
  kms_key_id = aws_kms_key.apikey.id
  tags = {
    Name = "poc-apikey-${random_string.random.id}"
  }
}

# Create the KMS Key
resource "aws_kms_key" "apikey" {
  description = "KMS CMK key"
  deletion_window_in_days = 10
  enable_key_rotation = true
  tags = {
    Name = "poc-apikey-${random_string.random.id}"
  }
}

# Alias the KMS Key
resource "aws_kms_alias" "apikey" {
  name = "alias/poc-apikey-${random_string.random.id}"
  target_key_id = aws_kms_key.apikey.id
}

# Create the KMS policy for the Lambda function
resource "aws_kms_key_policy" "kms-policy" {
  key_id = aws_kms_key.apikey.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Enable IAM User Permissions"
        Effect   = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Principal = {
          AWS = aws_iam_role.rotation_lambda_role.arn
        }
        Action   = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
        ]
        Resource = "*"
      }
    ]
  })
}

# Store the API key in the secret
resource "aws_secretsmanager_secret_version" "apikey" {
  secret_id     = aws_secretsmanager_secret.apikey.id
  secret_string = var.apikey
}

# Create the Rotation Configuration
resource "aws_secretsmanager_secret_rotation" "rotation" {
  secret_id           = aws_secretsmanager_secret.apikey.id
  rotation_lambda_arn = aws_lambda_function.rotation_lambda.arn

  rotation_rules {
    automatically_after_days = 30
  }
}