account_id                = "049879149392"
vpc-cidr                  = "10.0.0.0/16"
public_subnets_cidr       = ["10.0.4.0/24", "10.0.6.0/24"]
private_subnets_cidr      = ["10.0.8.0/24", "10.0.9.0/24"]
create                    = true
name                      = "learning-machines-app"
namespace                 = "ucdscenter"
app_image                 = "382622020541.dkr.ecr.us-east-2.amazonaws.com/worker"
environment               = "machine-learning-app"
stage                     = "dev"
aws_region                = "us-east-2"
azs                       = ["us-east-2a", "us-east-2b"]
cloudwatch_log_group_name = "ecs/uc-machine-learning-app"
cloudwatch_log_stream     = "ecs"
bucket_name               = "ucdsc-lb-logs"
container_port            = "8001"
name_prefix               = "ucdsc_center"
db_secret_arn             = "arn:aws:secretsmanager:us-east-2:049879149392:secret:prod/machineLearningApp/postgres-OFEBTn"
dev_db_secret_arn         = "arn:aws:secretsmanager:us-east-2:049879149392:secret:dev/machineLearningApp/postgres-JCfA0y"
