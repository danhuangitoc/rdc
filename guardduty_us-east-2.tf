
# Enable AWS Org Wide Guard Duty in region us-east-2

provider "aws" {
  region = "us-east-2"
  alias  = "us-east-2_security"
  profile = "security_account_profile"  # AWS CLI profile for the security AWS account
}

provider "aws" {
  region = "us-east-2"
  alias  = "us-east-2_management"
  profile = "management_account_profile"  # AWS CLI profile for the management AWS account
}

#  Enable GuardDuty on the management account
resource "aws_guardduty_detector" "us_east_2_enable_main_account" {
  provider = aws.us-east-2_management
  enable = true
}

#  Delegate GuardDuty to the security account
resource "aws_guardduty_organization_admin_account" "us_east_2_security_account_admin_delegate" {
  provider   = aws.us-east-2_management
  depends_on = [aws_guardduty_detector.us_east_2_security_detector]
  admin_account_id = var.security_account_id
}

resource "aws_guardduty_detector" "us_east_2_security_detector" {
  provider  = aws.us-east-2_security
  enable    = true
  finding_publishing_frequency = var.gd_finding_publishing_frequency
  datasources {
    s3_logs {
      enable = false
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = false
        }
      }
    }
  }
}

resource "aws_guardduty_organization_configuration" "us_east_2_org_wide_guardduty_config" {
  provider   = aws.us-east-2_security
  depends_on = [aws_guardduty_organization_admin_account.us_east_2_security_account_admin_delegate]

  auto_enable_organization_members = "ALL"
  detector_id = aws_guardduty_detector.us_east_2_security_detector.id

  datasources {
    s3_logs {
      auto_enable = false
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          auto_enable = false
        }
      }
    }
  }
}

# GuardDuty members in the Delegated admin account for existing accounts
resource "aws_guardduty_member" "us_east_2_members" {
  provider   = aws.us-east-2_security
  depends_on = [aws_guardduty_organization_configuration.us_east_2_org_wide_guardduty_config]

  count = length(var.gd_member_accounts)
  
  detector_id = aws_guardduty_detector.us_east_2_security_detector.id
  invite      = true

  account_id                 = var.gd_member_accounts[count.index].id
  disable_email_notification = true
  email                      = var.gd_member_accounts[count.index].email

}
