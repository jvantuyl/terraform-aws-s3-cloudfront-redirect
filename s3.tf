resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "host_only" {
  count  = startswith(var.redirect_target, "http") ? 0 : 1
  bucket = aws_s3_bucket.main.id

  redirect_all_requests_to {
    host_name = var.redirect_target
  }
}

data "corefunc_url_parse" "url" {
  count = startswith(var.redirect_target, "http") ? 1 : 0
  url   = var.redirect_target
}

resource "aws_s3_bucket_website_configuration" "url" {
  count  = startswith(var.redirect_target, "http") ? 1 : 0
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "unused.html"
  }

  routing_rule {
    redirect {
      host_name        = data.corefunc_url_parse.url[0].host
      protocol         = data.corefunc_url_parse.url[0].scheme
      replace_key_with = "${data.corefunc_url_parse.url[0].path}${data.corefunc_url_parse.url[0].search}${data.corefunc_url_parse.url[0].hash}"
    }
  }
}

resource "aws_s3_bucket" "main" {
  provider = aws.main
  bucket   = var.fqdn

  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      "Name" = var.fqdn
    },
  )
}

data "aws_iam_policy_document" "bucket_policy" {
  provider = aws.main

  statement {
    sid = "AllowCFOriginAccess"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.fqdn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"

      values = [
        var.refer_secret,
      ]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

