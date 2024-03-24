terraform {
  backend "s3" {
    bucket = "uberclonek8s" # Replace with your actual S3 bucket name
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
