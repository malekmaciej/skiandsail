provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    encrypt = true
    bucket  = "skiandsail-tf-state"
    key     = "terraform.tfstate"
    region  = "eu-central-1"
  }
}