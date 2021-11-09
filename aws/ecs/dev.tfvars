
account_id                = "689243823134"
vpc-cidr                  = "10.0.0.0/16"
create                    = true
name                      = "learning_machines_app" 
namespace                 = "ucdscenter"
app_image                 = ""
environment               = "machine-learning-app"
stage                     = "dev"
aws_region                = "us-east-2"
azs                       = ["us-east-2a" , "us-east-2b"]
cloudwatch_log_group_name = "ecs/uc-machine-learning-app"
cloudwatch_log_stream     = "ecs"
bucket_name               = "ucdsc-lb-logs"
container_port            =  8000
name_prefix               = "ucdsc_center"
db_secret_arn             = "arn:aws:secretsmanager:us-east-2:049879149392:secret:prod/machineLearningApp/postgres-OFEBTn"
