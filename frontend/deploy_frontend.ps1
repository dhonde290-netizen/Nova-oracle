# deploy_frontend.ps1
$RandomString = -join ((97..122) | Get-Random -Count 6 | % {[char]$_})
$BucketName = "nova-oracle-website-$RandomString"

Write-Host "Creating S3 Bucket: $BucketName in ap-south-1"
# In ap-south-1, LocationConstraint is required.
aws s3api create-bucket --bucket $BucketName --region ap-south-1 --create-bucket-configuration LocationConstraint=ap-south-1

Write-Host "Disabling Block Public Access..."
aws s3api put-public-access-block --bucket $BucketName --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

Write-Host "Waiting for public access block to propagate..."
Start-Sleep -Seconds 5

Write-Host "Applying Public Read Policy..."
$bucketPolicy = @"
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::$BucketName/*"
            ]
        }
    ]
}
"@
$bucketPolicy | Set-Content -Path bucket-policy.json -Encoding Ascii
aws s3api put-bucket-policy --bucket $BucketName --policy file://bucket-policy.json

Write-Host "Configuring Static Website Hosting..."
aws s3 website s3://$BucketName/ --index-document index.html --error-document index.html

Write-Host "Uploading Frontend Files..."
aws s3 sync . s3://$BucketName/ --exclude "deploy_frontend.ps1" --exclude "bucket-policy.json"

$websiteUrl = "http://$BucketName.s3-website.ap-south-1.amazonaws.com"
Write-Host "Deployment Complete!"
Write-Host "Your website is live at: $websiteUrl"
