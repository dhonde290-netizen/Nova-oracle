# deploy_backend.ps1
$RoleName = "NovaOracleLambdaRole"
$FunctionName = "NovaOracleFunction"
$ZipFile = "function.zip"

Write-Host "Creating IAM Trust Policy..."
$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@
$trustPolicy | Set-Content -Path trust-policy.json -Encoding Ascii

Write-Host "Creating IAM Role..."
aws iam create-role --role-name $RoleName --assume-role-policy-document file://trust-policy.json

Write-Host "Attaching Policies..."
aws iam attach-role-policy --role-name $RoleName --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy --role-name $RoleName --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess

Write-Host "Waiting for role to propagate..."
Start-Sleep -Seconds 15

Write-Host "Zipping Lambda function..."
Compress-Archive -Path lambda_function.py -DestinationPath $ZipFile -Force

$roleArn = (aws iam get-role --role-name $RoleName --query "Role.Arn" --output text).Trim()

Write-Host "Creating Lambda Function..."
aws lambda delete-function --function-name $FunctionName 2>$null
aws lambda create-function `
    --function-name $FunctionName `
    --runtime python3.11 `
    --role $roleArn `
    --handler lambda_function.lambda_handler `
    --zip-file fileb://$ZipFile `
    --timeout 30

Write-Host "Creating Function URL..."
$urlInfo = aws lambda create-function-url-config `
    --function-name $FunctionName `
    --auth-type NONE `
    --cors 'AllowOrigins="*",AllowMethods="*",AllowHeaders="content-type"'

$functionUrl = ($urlInfo | ConvertFrom-Json).FunctionUrl

Write-Host "Adding resource-based policy to allow public access to the Function URL..."
aws lambda add-permission `
    --function-name $FunctionName `
    --action lambda:InvokeFunctionUrl `
    --principal "*" `
    --statement-id FunctionURLAllowPublicAccess `
    --function-url-auth-type NONE 2>$null

Write-Host "Deployment Complete!"
Write-Host "Your Function URL is: $functionUrl"
