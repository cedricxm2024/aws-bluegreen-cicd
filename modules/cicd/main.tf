variable "project_name" { type = string }
variable "codebuild_role_arn" { type = string }
variable "codedeploy_role_arn" { type = string }
variable "codepipeline_role_arn" { type = string }

variable "artifact_bucket" { type = string }
variable "repo_owner" { type = string }
variable "repo_name" { type = string }
variable "branch" { type = string default = "main" }
variable "connection_arn" { type = string } # CodeStar connection ARN
variable "asg_name" { type = string }
variable "target_group_name" { type = string }

# ------------------------------
# CodeBuild Project
# ------------------------------
resource "aws_codebuild_project" "build" {
  name          = "${var.project_name}-build"
  description   = "Terraform validation and build"
  service_role  = var.codebuild_role_arn

  artifacts {
    type     = "S3"
    location = var.artifact_bucket
    packaging = "ZIP"
    path      = "build-artifacts"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/../../pipeline/buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "build"
    }
  }
}

# ------------------------------
# CodeDeploy App + Deployment Group
# ------------------------------
resource "aws_codedeploy_app" "app" {
  name             = "${var.project_name}-app"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "dg" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${var.project_name}-dg"
  service_role_arn      = var.codedeploy_role_arn
  autoscaling_groups    = [var.asg_name]

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  load_balancer_info {
    target_group_info {
      name = var.target_group_name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# ------------------------------
# CodePipeline
# ------------------------------
resource "aws_codepipeline" "pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.artifact_bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      configuration = {
        ConnectionArn       = var.connection_arn
        FullRepositoryId    = "${var.repo_owner}/${var.repo_name}"
        BranchName          = var.branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name              = "Build"
      category          = "Build"
      owner             = "AWS"
      provider          = "CodeBuild"
      input_artifacts   = ["SourceOutput"]
      output_artifacts  = ["BuildOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Approval"
    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
    }
  }

  stage {
    name = "Deploy"
    action {
      name             = "CodeDeploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      input_artifacts  = ["BuildOutput"]
      configuration = {
        ApplicationName      = aws_codedeploy_app.app.name
        DeploymentGroupName  = aws_codedeploy_deployment_group.dg.deployment_group_name
      }
    }
  }
}
resource "aws_codebuild_project" "drift_detection" {
  name          = "${var.project_name}-drift-detect"
  description   = "Detect infrastructure drift using terraform plan"
  service_role  = var.codebuild_role_arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false
    environment_variables = [
      { name = "TF_VAR_env"; value = var.env }
    ]
  }

  source {
    type      = "CODEPIPELINE" # or GITHUB if standalone
    buildspec = file("${path.module}/../../pipeline/drift_buildspec.yml")
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}-drift"
      stream_name = "drift"
    }
  }
}

