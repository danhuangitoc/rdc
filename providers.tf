terraform {
  required_version = ">= 1.5.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.15.0"
    }
  }
}

# The default aws provider - management account
provider "aws" {
  profile = "management_account_profile" 
  region = var.primary_region
  default_tags {
    tags = {
      owner       = "rdc"
      purpose     = "nec"
      environment   = "aunsw"
    }
  }
}

# Alias log_account
provider "aws" {
  alias  = "log"
  region = var.primary_region
  profile = "log_account_profile"  # AWS CLI profile for the log AWS account
  default_tags {
    tags ={
      owner       = "rdc"
      purpose     = "nec"
      environment   = "aunsw"
    }
  }
}

# Alias security_account
provider "aws" {
  alias  = "security"
  region = var.primary_region
  profile = "security_account_profile"  # AWS CLI profile for the log AWS account
  default_tags {
    tags ={
      owner       = "rdc"
      purpose     = "nec"
      environment   = "aunsw"
    }
  }
}
