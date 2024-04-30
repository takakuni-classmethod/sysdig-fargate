resource "aws_s3_bucket" "flowlog" {
  bucket = "${var.prefix}-flowlog-${data.aws_caller_identity.self.account_id}"

  force_destroy = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
resource "aws_s3_bucket_ownership_controls" "flowlog" {
  bucket = aws_s3_bucket.flowlog.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
resource "aws_s3_bucket_policy" "flowlog" {
  bucket = aws_s3_bucket.flowlog.id

  policy = templatefile("${path.module}/policy_document/bucket_flowlog.json", {
    bucket_arn = aws_s3_bucket.flowlog.arn
    account_id = data.aws_caller_identity.self.account_id
    region     = data.aws_region.current.name
  })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "flowlog" {
  bucket = aws_s3_bucket.flowlog.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "flowlog" {
  bucket = aws_s3_bucket.flowlog.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true

  depends_on = [
    aws_s3_bucket_policy.flowlog,
    aws_s3_bucket_ownership_controls.flowlog
  ]
}
