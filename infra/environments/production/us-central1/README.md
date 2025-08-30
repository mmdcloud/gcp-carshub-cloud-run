# CarHub Production Infrastructure - US Central 1

This directory contains the production infrastructure configuration for CarHub deployed in the us-central1 region.

## Production-Ready Features

### Security
- ✅ Cloud Armor WAF with XSS and SQL injection protection
- ✅ Rate limiting (100 requests/minute per IP)
- ✅ HTTPS/SSL encryption with managed certificates
- ✅ HTTP to HTTPS redirect
- ✅ Secrets stored in Secret Manager (no hardcoded credentials)
- ✅ Service accounts with least privilege access

### High Availability & Reliability
- ✅ Multi-zone deployment
- ✅ Auto-scaling Cloud Run services (2-5 instances)
- ✅ Regional Cloud SQL with automated backups
- ✅ Deletion protection on critical resources
- ✅ VPC with private subnets for database

### Monitoring & Observability
- ✅ Uptime checks for frontend and backend
- ✅ Custom metrics for HTTP errors and database issues
- ✅ Alerting policies with email notifications
- ✅ Structured logging

### Infrastructure Management
- ✅ Remote state backend in GCS
- ✅ Version-controlled infrastructure
- ✅ Environment-specific configurations

## Prerequisites

1. **GCP Project Setup**
   - Create a GCP project
   - Enable billing
   - Set up authentication (service account or gcloud auth)

2. **Domain Setup**
   - Own a domain name
   - Configure DNS to point to the load balancer IP

3. **Terraform State Bucket**
   ```bash
   gsutil mb gs://carshub-terraform-state-prod
   gsutil versioning set on gs://carshub-terraform-state-prod
   ```

4. **Vault Setup** (for database credentials)
   - Configure HashiCorp Vault
   - Store database credentials at `secret/sql`

## Deployment Steps

1. **Configure Variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Plan Deployment**
   ```bash
   terraform plan
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

## Required Variables

- `project_id`: Your GCP project ID
- `domain_name`: Your domain name for SSL certificate
- `notification_channel_email`: Email for alerts

## Security Considerations

- Database credentials are stored in Vault and Secret Manager
- All traffic is encrypted with HTTPS
- WAF protection against common attacks
- Private networking for database access
- Service accounts follow principle of least privilege

## Monitoring

The infrastructure includes:
- Uptime monitoring for frontend and backend
- Error rate monitoring (4xx, 5xx errors)
- Database connection monitoring
- Email alerts for critical issues

## Backup & Recovery

- Cloud SQL automated backups (30 days retention)
- Point-in-time recovery available
- Infrastructure state backed up in GCS
- Multi-region deployment capability

## Cost Optimization

- Auto-scaling based on demand
- Appropriate instance sizes for production workload
- Storage lifecycle policies for media files
- Regional resources to minimize data transfer costs