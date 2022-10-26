output "role_arn" {
  value = aws_iam_role.this.arn
}

output "table_arn" {
  value = aws_dynamodb_table.this.arn
}

output "bucket_arn" {
  value = module.bucket.bucket.arn
}
