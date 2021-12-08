# S3 remote state 
terraform {
  backend "s3" {
    bucket         = "ucdsc-remote-tf"
    key            = "project/learning_machine"
    region         = "us-east-2"
    dynamodb_table = "ucdscenter_lma_dynamodb"

  }
}
