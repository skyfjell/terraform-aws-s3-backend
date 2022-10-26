module "bucket" {
  // checkov:skip=CKV2_AWS_5: Needed for autoscaling
  // checkov:skip=CKV_AWS_144: No duplication right now
  // checkov:skip=CKV_AWS_145: False positive
  // checkov:skip=CKV_AWS_56: False positive
  // checkov:skip=CKV_AWS_54: False positive
  // checkov:skip=CKV_AWS_55: False positive
  // checkov:skip=CKV_AWS_53: False positive
  // checkov:skip=CKV2_AWS_6: False positive
  source  = "skyfjell/s3/aws"
  version = "1.0.6"

  name          = local.labels.id
  labels        = local.labels
  use_prefix    = false
  name_override = true
  force_destroy = true

  server_side_encryption_configuration = {
    type  = "aws:kms"
    alias = "alias/wf-stage-s3-kms"
  }

  public_access_block = {
    block_public_policy     = true
    block_public_acls       = true
    restrict_public_buckets = true
    ignore_public_acls      = true
  }

  roles = {
    stage-rw = {
      name = aws_iam_role.this.name
      mode = "rw"
    }
  }

  config_logging = {
    enable = false
  }
}

resource "aws_kms_key" "this" {
  description             = "Dynamodb KMS key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_dynamodb_table" "this" {
  # checkov:skip=CKV2_AWS_16: Autoscaling unnecessary
  name           = local.labels.id
  read_capacity  = 2
  write_capacity = 1
  hash_key       = "LockID"

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.this.arn
  }

  attribute {
    name = "LockID"
    type = "S"
  }


  tags = local.labels.tags
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = "DynamoDbPermissions"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.this.arn
    ]
  }

  statement {
    sid = "KMSPermissions"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant"
    ]
    resources = [
      aws_kms_key.this.arn,
      module.bucket.kms_arn
    ]
  }

  statement {
    sid       = "ListKMSPermission"
    actions   = ["kms:ListAliases"]
    resources = ["*"]
  }
}


resource "aws_iam_policy" "this" {
  name   = local.labels.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "AWS"
      identifiers = local.config_users.arns
    }
  }

}

resource "aws_iam_role" "this" {
  name               = local.labels.id
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
