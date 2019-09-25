# biis-packer-base

## Description

Packer scripts for building an AWS base image.  Strips off marketplace tags.

## Requirements
* Packer
* Access Keys to the environment in question (such as AWS secret keys)

## Installation
It is required that you have packer pre-installed before executing the script, packer can be downloaded from the below URL:
https://www.packer.io/downloads.html

It is also required that awscli tools be installed, the script will attempt to install them for you if not found.

Clone this repository to your local machine:
```
git clone https://github.com/shaun-rutherford/packer_base_image.git
```

## Usage
The aws_base build script requires one argument but accepts two.
Required: AWS_REGION (example, us-west-1)
Optional: AWS_INSTANCE_TYPE (example, cx5.large)

example:
bash build_aws_image.sh us-west-1 c5.xlarge

## Available Commands
```
Usage: build_aws_image.sh [AWS_REGION] [AWS_INSTANCE_TYPE]
```
