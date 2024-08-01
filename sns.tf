
# Creat a SNS topic
resource "aws_sns_topic" "sns_topic" {
  name = "sns-apikey-${random_string.random.id}"
  kms_master_key_id = aws_kms_key.apikey.arn
}

# Create a policy for the SNS topic
resource "aws_sns_topic_policy" "sns_topic_policy" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "sns-policy",
    Statement = [
      {
        Sid       = "AllowLambdaToPublish",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action    = "sns:Publish",
        Resource  = aws_sns_topic.sns_topic.arn,
      },
    ],
  })
}

