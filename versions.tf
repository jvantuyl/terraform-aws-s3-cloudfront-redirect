terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0"
      configuration_aliases = [aws.main, aws.cloudfront]
    }
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = ">= 1.3.0"
    }
  }
}
