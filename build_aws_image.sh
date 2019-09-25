#!/bin/bash
export PACKER_TEMPLATE="./aws_base/aws_base_centos7.json"
export AWS_REGION=$1
export AWS_INSTANCE_TYPE=$2
export USERNAME=`whoami`
vpc_filters="Name=cidr,Values=172.31.0.0/16"
subnet_filters="Name=cidr,Values=172.31.0.0/20"

# VALIDATING YOU ARE NOT RUNNING THIS AS THE ROOT USER
  if [[ $EUID == 0 ]]; then
   echo "THIS SCRIPT SHOULD NOT BE RAN AS ROOT" 
   exit 1
  fi

# CHECKING FOR USER HELP FLAGS ON COMMAND LINE
  if [[ "$AWS_REGION" == "-h" ]] || [[ "$AWS_REGION" == "-?" ]] || [[ "$AWS_REGION" == "--help" ]] || [[ -z "$AWS_REGION" ]] 
  then
    echo "$0 [AWS_REGION] [AWS_INSTANCE_TYPE]"
    exit 1
  fi

# VALIDATING PROPER AWS_REGION SET FROM CLI
  if [[ "$AWS_REGION" != "us-east-2" ]] &&
     [[ "$AWS_REGION" != "us-east-1" ]] &&
     [[ "$AWS_REGION" != "us-west-1" ]] &&
     [[ "$AWS_REGION" != "us-west-2" ]] &&
     [[ "$AWS_REGION" != "ap-east-1" ]] &&
     [[ "$AWS_REGION" != "ap-south-1" ]] &&
     [[ "$AWS_REGION" != "ap-northeast-3" ]] &&
     [[ "$AWS_REGION" != "ap-northeast-2" ]] &&
     [[ "$AWS_REGION" != "ap-southeast-1" ]] &&
     [[ "$AWS_REGION" != "ap-southeast-2" ]] &&
     [[ "$AWS_REGION" != "ap-northeast-1" ]] &&
     [[ "$AWS_REGION" != "ca-central-1" ]] &&
     [[ "$AWS_REGION" != "cn-north-1" ]] &&
     [[ "$AWS_REGION" != "cn-northwest-1" ]] &&
     [[ "$AWS_REGION" != "eu-central-1" ]] &&
     [[ "$AWS_REGION" != "eu-west-1" ]] &&
     [[ "$AWS_REGION" != "eu-west-2" ]] &&
     [[ "$AWS_REGION" != "eu-west-3" ]] &&
     [[ "$AWS_REGION" != "eu-north-1" ]] &&
     [[ "$AWS_REGION" != "sa-east-1" ]] &&
     [[ "$AWS_REGION" != "us-gov-east-1" ]] &&
     [[ "$AWS_REGION" != "us-gov-west-1" ]]
  then
    echo "PLEASE SET A PROPER AWS REGION"
    exit 1
  fi

# CHECKING FOR AWSCLI TOOLS
  which aws &> /dev/null
  if [[ $? != 0 ]];
  then
    echo "AWS CLI TOOLS NOT FOUND, ATTEMPTING TO INSTALL"
    which yum
    if [[ $? == 0 ]];
    then
      sudo yum -y install awscli
    else
    which apt-get
      if [[ $? == 0 ]];
      then
        sudo apt-get update && apt-get -y install awscli
      fi
    fi
    which aws &> /dev/null
    if [[ $? != 0 ]];
    then
      echo "CANNOT INSTALL AWS CLI AUTOMATICALLY, PLEASE INSTALL BY HAND"
      exit 1
    fi
  fi

# CHECKING FOR PACKER CLI TOOLS

  which packer &> /dev/null
  if [[ $? != 0 ]];
  then
    echo "HASHICORP PACKER MISSING, PLEASE DOWNLOAD FROM https://www.packer.io/downloads.html"
  else
    packer &> /dev/null

    if [[ $? != 127 ]];
    then
      echo "HASHICORP PACKER MISSING, PLEASE DOWNLOAD FROM https://www.packer.io/downloads.html"
    fi
  fi

# CHECKING IF AWS CREDENTIALS FILE EXIST
  echo "TESTING FOR AWS CREDENTIALS CONNECTIVITY"
  aws sts get-caller-identity
  if [[ $? != 0 ]];
  then
    echo "AWS CREDENTIALS NOT SET, ATTEMPTING TO SET AUTOMATICALLY"

  # CHECKING FOR AWS_PROFILE, IF NOT FOUND SET AWS_PROFILE TO DEFAULT
    if [[ -z $AWS_PROFILE ]] && [[ -z $AWS_ACCESS_KEY_ID ]] && [[ -z $AWS_SECRET_ACCESS_KEY ]];
    then
      export AWS_PROFILE='default';
    fi

  # CHECK FOR AWS ACCESS KEY ID, IF NOT FOUND ATTEMPT TO FETCH USING AWSCLI TOOLS
    if [[ -z $AWS_ACCESS_KEY_ID ]];
    then
      export AWS_ACCESS_KEY_ID=`aws --profile $AWS_PROFILE configure get aws_access_key_id`
      if [[ -z $AWS_ACCESS_KEY_ID ]];
      then
        echo "AWS_ACCESS_KEY_ID UNABLE TO BE FETCHED, PLEASE SET ENVIRONMENT VARIABLE MANUALLY, OR CREATE A AWS CREDENTIALS FILE"
        exit 1
      else
      # CHECK FOR AWS SECRET ACCESS KEY, IF NOT FOUND ATTEMPT TO FETCH USING AWSCLI TOOLS
        if [[ -z $AWS_SECRET_ACCESS_KEY ]];
        then
          export AWS_SECRET_ACCESS_KEY=`aws --profile $AWS_PROFILE configure get aws_secret_access_key`
          if [[ -z $AWS_SECRET_ACCESS_KEY ]];
          then
            echo "AWS_SECRET_ACCESS_KEY UNABLE TO BE FETCHED, PLEASE SET ENVIRONMENT VARIABLE MANUALLY, OR CREATE A AWS CREDENTIALS FILE"
            exit 1
          fi
        fi
      fi
    fi
  fi

# CHECKING FOR AWS INSTANCE TYPE, IF NOT SET DEFAULT TO M5.LARGE
  if [ -z $AWS_INSTANCE_TYPE ];
  then
    export AWS_INSTANCE_TYPE="m5.large"
  fi

# FETCH VPC ID
  export AWS_VPC_ID=$(aws --region ${AWS_REGION} ec2 describe-vpcs --filters ${vpc_filters} --query "Vpcs[*].VpcId" --output text)

  if [ -z "$AWS_VPC_ID" ];
  then
    echo "NO VPC FOUND"
    exit 1
  fi

# DETERMIN A PUBLIC SUBNET TO USE
  export AWS_SUBNET_ID=$(for subnet in `aws --region ${AWS_REGION} ec2 describe-subnets --filters Name=vpc-id,Values=${AWS_VPC_ID} --filters ${subnet_filters} --query "Subnets[*].SubnetId" --output text`; do echo $subnet; done | shuf | head -n 1)

# START PACKER BUILD PROCESS
  time packer build ${PACKER_TEMPLATE}

  if [ $? -ne 0 ];
  then
    echo "Packer failed!"
    exit $EXIT_CODE
  fi
