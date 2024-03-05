
resource "aws_organizations_delegated_administrator" "config" {
  account_id        = "${var.security_account_id}"
  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "config_multiaccount" {
  account_id        = "${var.security_account_id}"
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

# Note: The following resources need to be created here to prevent dependancy issues during initial deploy.
resource "aws_config_configuration_aggregator" "organization" {
  provider = aws.log
  depends_on = [
    aws_organizations_delegated_administrator.config,
    aws_iam_role_policy_attachment.org_config_policy_attach
  ]

  name = "aws-org-wide-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.org_config_role.arn
  }
}

resource "aws_iam_role" "org_config_role" {
  provider = aws.log

  name               = "rd-org-config-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "org_config_policy_attach" {
  provider = aws.log

  role       = aws_iam_role.org_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_s3_bucket" "config_delivery_bucket" {
  provider = aws.log

  bucket = "rd-s3-awsconfig-logs"
}

resource "aws_kms_key" "aws_config_cmk" {
  provider = aws.log

  description             = "For aws config delivery Bucket"
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
        "Sid": "AWSConfigKMSPolicy",
        "Effect": "Allow",
        "Principal": {
            "Service": "config.amazonaws.com"
        },
        "Action": [
            "kms:Decrypt",
            "kms:GenerateDataKey"
        ],
        "Resource": "myKMSKeyARN",
        "Condition": { 
            "StringEquals": {
                "AWS:SourceAccount":  [
                  "992382436297",
                  "208520030898",
                  "535674417720",
                  "066382673482",
                  "523045160836",
                  "693206277764",
                  "180196474329",
                  "252279432281",
                  "905418081527",
                  "875893639831",
                  "715996776006",
                  "371800420414",
                  "596918406459",
                  "405109427254",
                  "125333436053",
                  "875131052222",
                  "487306971511",
                  "858066369439",
                  "135925883163",
                  "513538049001",
                  "059124994643",
                  "529234120980",
                  "741151268897",
                  "602889940117",
                  "181636364823",
                  "287988820210",
                  "376301472361",
                  "891377135890",
                  "381491850234"
                ]
            }
        }
      }
    ]
}
POLICY
}

resource "aws_kms_alias" "aws_config_cmk_alias" {
  provider      = aws.log
  name          = "alias/AWSConfig"
  target_key_id = aws_kms_key.aws_config_cmk.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_delivery_bucket_server_side_encryption" {
  provider = aws.log
  bucket   = aws_s3_bucket.config_delivery_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.aws_config_cmk.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "config_delivery_bucket_policy" {
  provider = aws.log

  bucket = aws_s3_bucket.config_delivery_bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSConfigBucketPermissionsCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "config.amazonaws.com"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "${aws_s3_bucket.config_delivery_bucket.arn}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": [
            "992382436297",
            "208520030898",
            "535674417720",
            "066382673482",
            "523045160836",
            "693206277764",
            "180196474329",
            "252279432281",
            "905418081527",
            "875893639831",
            "715996776006",
            "371800420414",
            "596918406459",
            "405109427254",
            "125333436053",
            "875131052222",
            "487306971511",
            "858066369439",
            "135925883163",
            "513538049001",
            "059124994643",
            "529234120980",
            "741151268897",
            "602889940117",
            "181636364823",
            "287988820210",
            "376301472361",
            "891377135890",
            "381491850234"
          ]
        }
      }
    },
    {
      "Sid": "AWSConfigBucketExistenceCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "config.amazonaws.com"
        ]
      },
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.config_delivery_bucket.arn}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": [
            "992382436297",
            "208520030898",
            "535674417720",
            "066382673482",
            "523045160836",
            "693206277764",
            "180196474329",
            "252279432281",
            "905418081527",
            "875893639831",
            "715996776006",
            "371800420414",
            "596918406459",
            "405109427254",
            "125333436053",
            "875131052222",
            "487306971511",
            "858066369439",
            "135925883163",
            "513538049001",
            "059124994643",
            "529234120980",
            "741151268897",
            "602889940117",
            "181636364823",
            "287988820210",
            "376301472361",
            "891377135890",
            "381491850234"
          ]
        }
      }
    },
    {
      "Sid": "AWSConfigBucketDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "config.amazonaws.com"    
        ]
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.config_delivery_bucket.arn}/AWSLogs/*",
      "Condition": { 
        "StringEquals": { 
          "s3:x-amz-acl": "bucket-owner-full-control",
          "AWS:SourceAccount": [
            "992382436297",
            "208520030898",
            "535674417720",
            "066382673482",
            "523045160836",
            "693206277764",
            "180196474329",
            "252279432281",
            "905418081527",
            "875893639831",
            "715996776006",
            "371800420414",
            "596918406459",
            "405109427254",
            "125333436053",
            "875131052222",
            "487306971511",
            "858066369439",
            "135925883163",
            "513538049001",
            "059124994643",
            "529234120980",
            "741151268897",
            "602889940117",
            "181636364823",
            "287988820210",
            "376301472361",
            "891377135890",
            "381491850234"
          ]
        }
      }
    }
  ]
}
EOF

}

resource "aws_iam_policy" "config_s3_delivery" {
  provider = aws.log
  name     = "rd-aws-config-s3-delivery"
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.config_delivery_bucket.arn}",
        "${aws_s3_bucket.config_delivery_bucket.arn}/*"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "s3_config_policy_attach" {
  provider = aws.log

  role       = aws_iam_role.org_config_role.name
  policy_arn = aws_iam_policy.config_s3_delivery.arn
}
