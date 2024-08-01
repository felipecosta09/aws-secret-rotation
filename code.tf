# Zip the rotation lambda function
data "archive_file" "rotation_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/zip/lambda.zip"
  source_dir  = "${path.module}/code/"
}