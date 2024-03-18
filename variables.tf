locals {
  s3_origin_id_civetta2024_domain   = "${var.civetta2024_domain}-origin"
  s3_domain_name_civetta2024_domain = "${var.civetta2024_domain}.s3-website-${var.region}.amazonaws.com"
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    "gitrepo" = "https://github.com/malekmaciej/skinandsail"
    "owner"   = "malekmaciej"
  }
}

variable "civetta2024_domain" {
  description = "Domain name for Civetta 2024 gallery"
  type        = string
  default     = "civetta2024.skiandsail.org"
}

variable "region" {
  type        = string
  description = "Region where S3 bucket located"
  default     = "eu-central-1"
}

variable "zone_id" {
  type        = string
  description = "The ID of the hosted zone to contain this record. Required when validating via Route53"
  default     = "Z013811527XF22UY5WHIE"
}