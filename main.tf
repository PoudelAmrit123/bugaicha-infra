### VPC ####
module "vpc" {
  source                 = "./modules/vpc"
  vpc_name               = "bugai-cha"
  enable_nat_gateway     = var.enable_nat_gateway
  has_private_subnet     = var.has_private_subnet
  has_public_subnet      = var.has_public_subnet
  cidr_block             = var.vpc_cidr
  destination_cidr_block = var.destination_cidr_block
  public_subnet          = var.public_subnet
  private_subnet         = var.private_subnet
  vpc_project            = var.vpc_project
  enable_igw             = var.enable_igw

  enable_nat_instance = var.enable_nat_instance

}

## DynamoDB ##
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name   = "bugAiCha"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ticket_id"

  attributes = [
    { name = "ticket_id", type = "S" }
  ]

  point_in_time_recovery_enabled = true
  server_side_encryption_enabled = true
  stream_enabled                 = true
  stream_view_type               = "NEW_AND_OLD_IMAGES"

  ttl_enabled        = true
  ttl_attribute_name = "expires_at"

  tags = {
    Name    = "bugAiCha-metadata"
    Project = "bugAicha"
  }
}

# Lambda ##
# module "lambda" {
#   source = "./modules/lambda"

#   function_name          = "bugAiCha-function"
#   role_name              = "bugAiCha-lambda-role"
#   runtime                = "python3.11"
#   handler                = "index.handler"
#   timeout                = 500
#   memory_size            = 128
#   enable_dynamodb_policy = true


#   environment_variables = {
#     DYNAMODB_TABLE = module.dynamodb.table_name
#     ENVIRONMENT    = "dev"
#   }

#   vpc_config = {
#     vpc_id     = module.vpc.vpc_id
#     subnet_ids         = module.vpc.private_subnet_ids
#   }

#   tags = {
#     Name    = "bugAiCha-lambda"
#     Project = "bugAicha"
#   }
# }

## ECR ###

module "bugaicha-frontend" {
  source = "./modules/ecr"
  ecr_repository_name = "bugaicha-frontend-app"

}

module "bugaicha-backend" {
   source = "./modules/ecr"
   ecr_repository_name = "bugaicha-backend-app"     
}

### EC2 ####
# module "ec2" {
#   source                      = "./modules/ec2"
#   ami_id                      = "ami-0bdd88bd06d16ba03"
#   name                        = "ec2-instance"
#   subnet_id                   = module.vpc.public_subnet_ids[0]
#   associate_public_ip_address = true
#   # user_data =  file("userdata.sh")
#   vpc_id   = module.vpc.vpc_id
#   key_name = "bugaicha-key"
# }

 ## SQS ## 
 module "sqs" {
    source = "./modules/sqs"

    name                      = "bugaicha"
    create_dlq                = true
    max_receive_count         = 3

    tags = {
      Team        = "bugAiCha"
      
    }
  }

# ##### ECS #### 
#  module "ecs" {
#     source = "./modules/ecs"
#     ecs_cluster_name =  "ecs-am-cluster"
#     vpc_id =  module.vpc.vpc_id
#     subnet_id =  module.vpc.public_subnet_ids
#     target_group_arns = module.alb.lb_target_group_arns 

#     services = {
#     frontend = {
#       ecs_service_name             = "frontend-service"                   
#       ecs_desiredCount             = 1
#       launch_type                  = "EC2"
#       enable_alb                   = true
#       enable_public_ip_ecs_service = false                    
#       ecsService_subnets           = module.vpc.public_subnet_ids
#       container_name               = "frontend"
#       container_port               = 80

#     }

#     backend = {
#       ecs_service_name             = "backend-service"
#       ecs_desiredCount             = 1
#       launch_type                  = "EC2"
#       enable_alb                   = false
#       enable_public_ip_ecs_service = false
#       ecsService_subnets           = module.vpc.public_subnet_ids
#       container_name               = "backend"
#       container_port               = 80
#     }
#   }

#    task = {
#     frontend = {
#       containerPort       = 80
#       launch_type         = "EC2"
#       cpu                 = "256"
#       memory              = "512"
#       network_mode        = "awsvpc"
#       image               = module.ecr-frontend.ecr_repository_uri
#       hostPort            = 80
#       family_name         = "frontend-family"  

#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#           name          = "frontend"
#         }
#       ]

#         environment = [
#               { name = "ENVIRONMENT", value = "dev" },
#               { name = "name", value = "test" }
#             ]
#     }

#     backend = {
#       containerPort       = 80
#       launch_type         = "EC2"
#       cpu                 = "256"
#       memory              = "512"
#       network_mode        = "awsvpc" 
#       image               = module.ecr-backend.ecr_repository_uri
#       hostPort            = 80
#       family_name         = "backend-family"

#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#           name          = "backend"
#         }
#       ]
# environment = [
#       { name = "ENVIRONMENT", value = "dev" },
#       { name = "name", value = "test" }
#     ]
#     }
#   }


#  }




#### RDS #### 
#  module "rds" {
#     source = "./modules/rds"

#     multi_az_family =  var.multi_az_family 
#     mutli_parameters =    var.mutli_parameters

#     engine               = var.rds_engine
#     major_engine_version = var.major_engine_version

#     subnet_ids =  module.vpc.private_subnet_ids
#     vpc_id =  module.vpc.vpc_id

#     parameter_name         = var.parameter_name
#     parameter_family       = var.parameter_family
#     parameters = var.parameters

#     db_option = var.db_option
#     db_instance_config = var.db_instance_config  

#  }


### S3 ##### 
# module "s3-metadata" {
#   source = "./modules/s3"

#   bucket_name          = "bugAiCha-metadata"
#   create_bucket_policy = true
#   enable_website       = true

#   bucket_policy_input = {
#     bucket_arns = ["arn:aws:s3:::bugAiCha-metadata"]

#     statement = [
#       {
#         Effect = "Allow"

#         Principal = "*"

#         Action = [
#           "s3:GetObject"
#         ]

#         Resource = [
#           "arn:aws:s3:::bugAiCha-metadata/*"
#         ]
#       }
#     ]
#   }
# }

# module "s3-result" {
#   source = "./modules/s3"

#   bucket_name          = "bugAiCha-result"
#   create_bucket_policy = true
#   enable_website       = true

#   bucket_policy_input = {
#     bucket_arns = ["arn:aws:s3:::bugAiCha-result"]

#     statement = [
#       {
#         Effect = "Allow"

#         Principal = "*"

#         Action = [
#           "s3:GetObject"
#         ]

#         Resource = [
#           "arn:aws:s3:::bugAiCha-result/*"
#         ]
#       }
#     ]
#   }
# }
