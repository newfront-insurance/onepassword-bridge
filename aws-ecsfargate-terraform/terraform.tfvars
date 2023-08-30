# Required: Set a domain name for your SCIM bridge
domain_name = "scim.newfront-development.com"

# Optional: Specify a different region
aws_region = "us-west-2"

# Optional: Specify an existing VPC to use, add a common name prefix to all resources, specify the CloudWatch Logs retention period, and add tags for all supported resources.
vpc_name           = "dev"
name_prefix        = "onepass"
log_retention_days = 0
tags = {
  Name = "onepass"
}

# Uncomment the below line to use an existing wildcard certificate in AWS Certificate Manager.
wildcard_cert = true

# Uncomment the below line if you are *not* using Route 53
#using_route53 = false

# Uncomment the below line to enable Google Workspace configuration for 1Password SCIM bridge
#using_google_workspace = true
