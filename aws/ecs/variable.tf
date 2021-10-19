terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  default     = ""
  description = "The AWS region to deploy module into"
}

variable "vpc_id" {
  description = "Docker image of the application"
  default     = ""
}

variable "app_image" {
  description = "Docker image of the application"
  default     = ""
}

variable "fargate_cpu" {
  type        = number 
  description = "The cpu for the fargate container"
  default     = 64
}

variable "fargate_memory" {
  type        = number 
  description = "The memory for the fargate container"
  default     = 128
}

variable "container_port" {
  type        = number 
  description = "container port for the application"
  default     = 3000
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name`"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = ""
}

variable "bucket_name" {
  description = "Number of ALB log bucket"
  default     = ""
}

variable "name" {
  type        = string
  default     = ""
  description = "The name of the ecs cluster"
}

variable "enabled" {
  type        = bool
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources"
  default     = true
}

variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "container_name" {
  description = "Optional name for the container to be used instead of name_prefix."
  default     = ""
  type        = string
}

variable "task_container_memory_reservation" {
  description = "The soft limit (in MiB) of memory to reserve for the container."
  default     = null
  type        = number
}

variable "task_container_command" {
  description = "The command that is passed to the container."
  default     = []
  type        = list(string)
}

variable "task_container_working_directory" {
  description = "The working directory to run commands inside the container."
  default     = ""
  type        = string
}

variable "task_container_environment" {
  description = "The environment variables to pass to a container."
  default     = {}
  type        = map(string)
}

variable "task_container_secrets" {
  description = "The secrets variables to pass to a container."
  default     = null
  type        = list(map(string))
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name required to enabled logDriver in container definitions for ecs task."
  type        = string
  default     = ""
}

variable "cloudwatch_log_stream" {
  description = "CloudWatch log stream name"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "repository_credentials" {
  default     = ""
  description = "name or ARN of a secrets manager secret (arn:aws:secretsmanager:region:aws_account_id:secret:secret_name)"
  type        = string
}

variable "repository_credentials_kms_key" {
  default     = "alias/aws/secretsmanager"
  description = "key id, key ARN, alias name or alias ARN of the key that encrypted the repository credentials"
  type        = string
}

variable "create_repository_credentials_iam_policy" {
  default     = false
  description = "Set to true if you are specifying `repository_credentials` variable, it will attach IAM policy with necessary permissions to task role."
}

variable "placement_constraints" {
  type        = list
  description = "(Optional) A set of placement constraints rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10. This is a list of maps, where each map should contain \"type\" and \"expression\""
  default     = []
}

variable "proxy_configuration" {
  type        = list
  description = "(Optional) The proxy configuration details for the App Mesh proxy. This is a list of maps, where each map should contain \"container_name\", \"properties\" and \"type\""
  default     = []
}

variable "volume" {
  description = "(Optional) A set of volume blocks that containers in your task may use. This is a list of maps, where each map should contain \"name\", \"host_path\", \"docker_volume_configuration\" and \"efs_volume_configuration\". Full set of options can be found at https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html"
  default     = []
}

variable "task_health_check" {
  type        = object({ command = list(string), interval = number, timeout = number, retries = number, startPeriod = number })
  description = "An optional healthcheck definition for the task"
  default     = null
}

variable "task_start_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before giving up on resolving dependencies for a container. If this parameter is not specified, the default value of 3 minutes is used (fargate)."
  default     = null
}

variable "task_stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own. The max stop timeout value is 120 seconds and if the parameter is not specified, the default value of 30 seconds is used."
  default     = null
}

variable "task_mount_points" {
  description = "The mount points for data volumes in your container. Each object inside the list requires \"sourceVolume\", \"containerPath\" and \"readOnly\". For more information see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html "
  type        = list(object({ sourceVolume = string, containerPath = string, readOnly = bool }))
  default     = null
}

variable "prevent_destroy" {
  type        = bool
  description = "S3 bucket lifecycle prevent destroy"
  default     = true
}

variable "bucket_prefix" {
  type        = string
  description = "S3 bucket prefix"
  default     = "db-treat"
}

variable "s3_bucket_versioning" {
  type        = bool
  description = "S3 bucket versioning enabled?"
  default     = true
}

variable "environment" {
  type        = string
  description = "The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`)"
  default     = ""
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. uclib)"
  default     = ""
}

variable "stage" {
  type        = string
  default     = ""
  description = "The development stage (i.e. `dev`, `stg`, `prd`)"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "health_check_path" {
  type        = string
  description = "Path to check if the service is healthy , e.g \"/status\""
  default     = "/health"
}

variable "db_secret_arn" {
  type        = string
  description = "ARN to the Secret in Secret Manager for RDS"
  default = ""
}

variable "rmkey_secret_arn" {
  type        = string
  description = "ARN to the Secret in Secret Manager for Rails Master Key"
  default = ""
}

variable "admin_secret_arn" {
  type        = string
  description = "ARN to the Secret in Secret Manager for Admin Credentials"
  default = ""
}

locals {
 
  environment_prefix = join(var.delimiter, compact([var.namespace, var.environment]))
  stage_prefix       = join(var.delimiter, compact([local.environment_prefix, var.stage]))
  module_prefix      = join(var.delimiter, compact([local.stage_prefix, var.name]))
  #tags              = merge( var.namespace ,var.environment ,var.stage)
}
