#!/bin/bash
# Deploy frontend to S3 and invalidate CloudFront cache
# Usage: ./scripts/deploy-frontend.sh

set -e

echo "=== Deploying IoT Dashboard Frontend ==="

# Get Terraform outputs
cd terraform
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
cd ..

echo "Bucket: $BUCKET_NAME"

# Sync frontend files to S3
echo "Uploading files to S3..."
aws s3 sync frontend/ "s3://$BUCKET_NAME/" \
  --delete \
  --exclude "*.md" \
  --cache-control "public, max-age=3600" \
  --content-type "text/html" --exclude "*" --include "*.html"

aws s3 sync frontend/ "s3://$BUCKET_NAME/" \
  --delete \
  --exclude "*.html" \
  --exclude "*.md"

# Invalidate CloudFront if distribution exists
if [ -n "$DISTRIBUTION_ID" ]; then
  echo "Invalidating CloudFront cache..."
  aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" > /dev/null
  echo "CloudFront invalidation created"
fi

echo ""
echo "=== Deployment Complete ==="
echo "Dashboard URL: $(cd terraform && terraform output -raw dashboard_url)"
