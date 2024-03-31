resource "aws_s3_bucket" "intercax_bucket" {
  bucket = "daniel-intercax"

  tags = {
    Name        = "intercax-bucket"
    Environment = "dev"
  }
}



resource "aws_s3_bucket_versioning" "intercax_bucket_versioning" {
  bucket = aws_s3_bucket.intercax_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}



resource "aws_iam_user" "space_fetch_git_user" {
  name = "space_fetch_git_user"
}

resource "aws_iam_user_policy" "space_fetch_git_user_s3" {
  name = "S3PutAccessPolicy"
  user = aws_iam_user.space_fetch_git_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "s3:PutObject",
        Effect = "Allow",
        Resource = "${aws_s3_bucket.intercax_bucket.arn}/*",
      },
    ],
  })
}


resource "aws_iam_role" "space_fetch_lambda_role" {
  name = "iam_space_fetch_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })

  inline_policy {
    name   = "S3PutAccessPolicy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = "s3:PutObject",
          Effect = "Allow",
          Resource = "${aws_s3_bucket.intercax_bucket.arn}/*",
        },
      ],
    })
  }
}


resource "aws_lambda_function" "space_fetch" {
  function_name = "space_fetch"

  s3_bucket = aws_s3_bucket.intercax_bucket.id
  s3_key    = "lambdas/space-fetch-${var.space_fetch_version}.zip"

  handler = "fetch_data.lambda_handler"
  runtime = "python3.10"
  role    = aws_iam_role.space_fetch_lambda_role.arn

  environment {
    variables = {
      file_name    = var.file_name
      bucket_name  = aws_s3_bucket.intercax_bucket.id
      path_name    = var.path_name
      object_name  = var.object_name
    }
  }
}


# resource "aws_scheduler_schedule" "cron_space_fetch" {
#   name       = "cron_space_fetch"
#   group_name = "default"

#   flexible_time_window {
#     mode = "OFF"
#   }

#   schedule_expression = "rate(1 days)"

#   target {
#     arn      = aws_lambda_function.lambda_space_fetch.arn
#     role_arn = aws_iam_role.iam_space_fetch_lambda
#   }
# }