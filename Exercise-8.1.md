# **Exercise 8.1 — Least-Privilege IAM Module**

**Course:** Optimizaciones y Desempeño — Cloud Deployment Automation  
**Session:** 8 — June 11, 2026  
**Time allowed:** 30 minutes  
**Submission:** Initialize a new repository called oyd-exercise-8-1 and commit/push everything into it. Submit the repository URL only.

# Context

A media-processing service runs a web server on EC2 and a background worker on Lambda. Both components currently use wildcard IAM policies — a security gap inherited from early development. Your task is to replace them with a least-privilege IAM module that enforces exactly the permissions each component needs and nothing more.

The service has two components:

* app-server — an EC2 instance that reads and writes media files to an S3 bucket  
* job-processor — a Lambda function that consumes jobs from an SQS queue and writes processed results to the same S3 bucket under a /results/ prefix

The following starter code defines the S3 bucket and SQS queue. Copy it as-is into your repository — do not modify these resources.

### main.tf

terraform {  
  required\_providers {  
    aws \= {  
      source  \= "hashicorp/aws"  
      version \= "\~\> 5.0"  
    }  
  }  
}

provider "aws" {  
  region \= "us-east-1"  
}

resource "aws\_s3\_bucket" "media" {  
  bucket \= "${var.project}-${var.environment}-media"  
}

resource "aws\_sqs\_queue" "jobs" {  
  name \= "${var.project}-${var.environment}-jobs"  
}

### variables.tf

variable "project" {  
  type \= string  
}

variable "environment" {  
  type    \= string  
  default \= "dev"  
}

### versions.tf

terraform {  
  required\_version \= "\>= 1.6"  
}

# Setup

## Prerequisites

* Terraform \>= 1.6 installed (terraform version to verify)  
* AWS credentials configured with permissions to create IAM roles, policies, S3 buckets, and SQS queues  
* A dev.tfvars file with at minimum: project \= "\<yourname\>-media"

## Repository structure

oyd-exercise-8-1/  
├── main.tf  
├── variables.tf  
├── versions.tf  
├── dev.tfvars  
├── infra/  
│   └── modules/  
│       └── iam/  
│           ├── main.tf  
│           ├── variables.tf  
│           └── outputs.tf  
└── evidence/  
    └── apply.txt

# Tasks

## Task 1 — Create infra/modules/iam/

Write the IAM module. The module must define the following variables, resources, and outputs.

Required variables (infra/modules/iam/variables.tf):

* project — string  
* environment — string  
* s3\_bucket\_arn — string, ARN of the media S3 bucket  
* sqs\_queue\_arn — string, ARN of the jobs SQS queue

Required resources (infra/modules/iam/main.tf):

* aws\_iam\_role.app\_server — trust principal: ec2.amazonaws.com  
* aws\_iam\_policy.app\_server — allows s3:GetObject, s3:PutObject, s3:DeleteObject, s3:ListBucket on the bucket ARN and its objects (two Resource entries)  
* aws\_iam\_role\_policy\_attachment.app\_server  
* aws\_iam\_instance\_profile.app\_server — required to attach the role to an EC2 instance  
* aws\_iam\_role.job\_processor — trust principal: lambda.amazonaws.com  
* aws\_iam\_policy.job\_processor — allows sqs:ReceiveMessage, sqs:DeleteMessage, sqs:GetQueueAttributes on the queue ARN; s3:PutObject on ${s3\_bucket\_arn}/results/\*  
* aws\_iam\_role\_policy\_attachment.job\_processor

Required outputs (infra/modules/iam/outputs.tf):

* app\_server\_role\_arn  
* app\_server\_instance\_profile\_name  
* job\_processor\_role\_arn

## Task 2 — Wire the module in root main.tf

Add a module "iam" block in root main.tf that calls ./infra/modules/iam and passes:

* project and environment from root variables  
* s3\_bucket\_arn \= aws\_s3\_bucket.media.arn  
* sqs\_queue\_arn \= aws\_sqs\_queue.jobs.arn

Expose the three module outputs at the root level.

## 

## Task 3 — Apply and capture evidence

Run the following commands and save the apply output:

terraform fmt \-recursive  
terraform init  
terraform validate  
terraform plan -var-file=dev.tfvars -out=plan.tfplan | tee evidence/plan.txt

The apply output must show at least 7 resources added. Commit evidence/apply.txt to the repository.

# Acceptance Criteria

* terraform validate passes with no errors  
* terraform apply adds at least 7 resources: 2 roles, 2 policies, 2 attachments, 1 instance profile  
* app\_server role trust principal is ec2.amazonaws.com  
* job\_processor role trust principal is lambda.amazonaws.com  
* No Action \= "\*" or Resource \= "\*" in either permissions policy (CloudWatch Logs wildcard is acceptable if included)  
* job\_processor S3 write is scoped to the /results/\* path prefix, not the whole bucket  
* aws\_iam\_instance\_profile exists for the app\_server role only  
* All three outputs (app\_server\_role\_arn, app\_server\_instance\_profile\_name, job\_processor\_role\_arn) are defined and non-empty after apply  
* evidence/apply.txt is committed and shows successful resource creation

