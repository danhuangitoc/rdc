
#tfsec:ignore:aws-cloudtrail-enable-at-rest-encryption
resource "aws_cloudtrail" "org_cloudtrail" {
  name                          = "${var.org_trail_name}"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail_s3_cmk.arn
}

data "aws_region" "current_region" {}

# S3 related resources
resource "aws_kms_key" "cloudtrail_s3_cmk" {
  provider = aws.log

  description             = "For CloudTrail S3 Bucket"
  deletion_window_in_days = 30
  multi_region            = true
  enable_key_rotation     = true
  policy                  = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "Key-CloudTrail-Org-Policy",
    "Statement": [
        {
            "Sid": "EnableIAMUserPermissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.log_account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "AllowCloudTrailtoEncryptLogs",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": [
                "kms:DescribeKey",
                "kms:GenerateDataKey*",
                "kms:Decrypt"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowUseOfKey",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalOrgID": "${var.aws_org_id}"
                }
            }
        },
        {
            "Sid": "AllowAttachmentOfpersistentResources",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalOrgID": "${var.aws_org_id}"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_kms_alias" "cloudtrail_s3_cmk_alias" {
  provider      = aws.log
  name          = "alias/CloudTrail"
  target_key_id = aws_kms_key.cloudtrail_s3_cmk.key_id
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  provider = aws.log

  bucket = "${var.trail_bucket_name}"
  tags = {
    Name = "${var.trail_bucket_name}"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  provider = aws.log

  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_bucket_server_side_encryption" {
  provider = aws.log

  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_s3_cmk.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "trail_bucket_owner_control" {
  provider = aws.log
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


resource "aws_s3_bucket_acl" "cloudtrail_bucket_acl" {
  provider = aws.log
  depends_on = [aws_s3_bucket_ownership_controls.trail_bucket_owner_control]
  bucket   = aws_s3_bucket.cloudtrail_bucket.id
  acl      = "private"
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  provider = aws.log
  bucket   = aws_s3_bucket.cloudtrail_bucket.id
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.trail_bucket_name}",
            "Condition": {
              "StringEquals": {
                "aws:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current_region.name}:${var.management_account_id}:trail/${var.org_trail_name}"
              }
            }
        },
        {
          "Sid": "AWSCloudTrailWrite20150319",
          "Effect": "Allow",
          "Principal": {
              "Service": [
                  "cloudtrail.amazonaws.com"
              ]
          },
          "Action": "s3:PutObject",
          "Resource": "arn:aws:s3:::${var.trail_bucket_name}/AWSLogs/${var.management_account_id}/*",
          "Condition": {
              "StringEquals": {
                "s3:x-amz-acl": "bucket-owner-full-control",
                "aws:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current_region.name}:${var.management_account_id}:trail/${var.org_trail_name}"
              }
          }
        },

        {
            "Sid": "AWSCloudTrailOrganizationWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.trail_bucket_name}/AWSLogs/${var.aws_org_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control",
                    "aws:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current_region.name}:${var.management_account_id}:trail/${var.org_trail_name}"
                }
            }
        }
    ]
}
EOF
}

resource "aws_s3_bucket_logging" "cloudtrail_bucket_logging" {
  provider = aws.log
  bucket   = aws_s3_bucket.cloudtrail_bucket.id

  target_bucket = aws_s3_bucket.cloudtrail_access_logs_bucket.id
  target_prefix = "${aws_s3_bucket.cloudtrail_bucket.id}/"
}

resource "aws_s3_bucket" "cloudtrail_access_logs_bucket" {
  provider = aws.log

  bucket = "rd-cloudtrail-access-logs"
}

resource "aws_s3_bucket_versioning" "cloudtrail_access_logs_bucket_versioning" {
  provider = aws.log
  bucket   = aws_s3_bucket.cloudtrail_access_logs_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "trail_access_bucket_owner_control" {
  provider = aws.log
  bucket = aws_s3_bucket.cloudtrail_access_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudtrail_access_logs_bucket_acl" {
  provider = aws.log
  depends_on = [aws_s3_bucket_ownership_controls.trail_access_bucket_owner_control]
  bucket   = aws_s3_bucket.cloudtrail_access_logs_bucket.id
  acl      = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_access_logs_bucket_server_side_encryption" {
  provider = aws.log
  bucket   = aws_s3_bucket.cloudtrail_access_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

