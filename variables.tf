variable "primary_region" {
  type        = string
  description = "Primary AWS Region to deploy resources into"
  default     = "ap-southeast-2"
}

variable "trail_bucket_name" {
  type        = string
  description = "S3 bucket name for cloudtrail log"
  default     = "rd-s3-cloudtrial-logs"
}

variable "org_trail_name" {
  type        = string
  description = "organization trail name"
  default     = "rd-cloudtrail-orgtrail"
}

variable "management_account_id" {
  type        = string
  description = "management account id"
  default     = "992382436297"
}

variable "security_account_id" {
  type        = string
  description = "Security account id"
  default     = "891377135890"
}

variable "log_account_id" {
  type        = string
  description = "Log account id"
  default     = "381491850234"
}

variable "aws_org_id" {
  type        = string
  description = "AWS organization  id"
  default     = "o-c83gxy0i7x"
}

variable "gd_finding_publishing_frequency" {
  type        = string
  description = "GuardDuty pulish event frequency"
  default     = "SIX_HOURS"
}

variable "gd_member_accounts" {
  type = list(object({
    id  = string
    email = string
  }))
  default = [
    {
      id  = "381491850234"
      email = "root-account.aws+logarchive@richdataco.com"
    }
  ]
}

variable "guardduty_notification_email" {
  type        = string
  description = "Email address to receive GuardDuty findings"
  default     = "security.aws@richdataco.com"
}