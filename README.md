<div align="center">

# ⚡ Serverless URL Shortener

**A production-ready, fully serverless URL shortener built on AWS — managed entirely with Terraform.**

[![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?style=flat-square&logo=node.js&logoColor=white)](https://nodejs.org)
[![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?style=flat-square&logo=terraform&logoColor=white)](https://terraform.io)
[![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-FF9900?style=flat-square&logo=awslambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![DynamoDB](https://img.shields.io/badge/DynamoDB-On--Demand-4053D6?style=flat-square&logo=amazondynamodb&logoColor=white)](https://aws.amazon.com/dynamodb/)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e?style=flat-square)](LICENSE)

</div>

---

## 📐 Architecture

![Architecture](screenshot/architecture.png)
                            
## 🖥️ Frontend

![Frontend — URL input form](screenshot/index1.png)

![Frontend — shortened URL result](screenshot/index2.png)

![Destination redirect](screenshot/destination.png)

---

## 📊 Monitoring Dashboard

![CloudWatch — invocations and errors](screenshot/metrics1.png)

![CloudWatch — p50 / p99 latency](screenshot/metrics2.png)

> **Dashboard:**
> ['Dashboard'](screenshot/index2.png)

Metrics tracked: **click count** · **Lambda invocations** · **errors** · **p50 / p99 latency** · **API 4xx / 5xx**

---

## 🛠️ Stack

| Layer | Service |
|-------|---------|
| Database | DynamoDB (on-demand) |
| Compute | AWS Lambda (Node.js 20) |
| API | API Gateway HTTP API v2 |
| Frontend | S3 + CloudFront (OAC) |
| Analytics | DynamoDB Streams + Lambda |
| Monitoring | CloudWatch Alarms + Dashboard |
| Security | API Gateway throttling + WAF |
| IaC | Terraform |

---

## 📁 Project Structure

```
url-shortener/
├── infra/                       # All Terraform configuration
│   ├── main.tf                  # Provider and backend
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── dynamo.tf                # DynamoDB table + streams
│   ├── iam.tf                   # IAM roles and policies
│   ├── lambda.tf                # Lambda function definitions
│   ├── apigateway.tf            # API Gateway + throttling
│   ├── s3.tf                    # S3 bucket + CloudFront
│   ├── cloudwatch.tf            # Alarms + dashboard
│   └── waf.tf                   # WAF WebACL
├── lambdas/
│   ├── shorten/                 # POST /shorten handler
│   │   └── index.mjs
│   ├── redirect/                # GET /{shortId} handler
│   │   └── index.mjs
│   └── analytics/               # DynamoDB Stream processor
│       └── index.mjs
├── frontend/
│   └── index.html               # Static UI
└── README.md
```

---

## ✅ Prerequisites

| Tool | Minimum version |
|------|----------------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | v1.7+ |
| [AWS CLI](https://aws.amazon.com/cli/) | v2, configured with credentials |
| Node.js | v18+ |

---

## 🚀 Deploy

### 1. Clone the repo

```bash
git clone <your-repo-url>
cd url-shortener
```

### 2. Configure variables

```bash
cp infra/terraform.tfvars.example infra/terraform.tfvars
# Edit terraform.tfvars with your region and settings
```

### 3. Package Lambda functions

```bash
cd lambdas/shorten   && zip -r shorten.zip   index.mjs && cd ../..
cd lambdas/redirect  && zip -r redirect.zip  index.mjs && cd ../..
cd lambdas/analytics && zip -r analytics.zip index.mjs && cd ../..
```

### 4. Deploy with Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 5. Get your endpoints

```bash
terraform output api_url
terraform output cloudfront_url
```

---

## 🔌 API

### Shorten a URL

```bash
curl -X POST <api_url>/shorten \
  -H "Content-Type: application/json" \
  -d '{"originalUrl": "https://example.com/long/path", "userId": "user123"}'
```

**Response:**

```json
{
  "shortUrl":    "https://short.example.com/xK9mPq",
  "shortId":     "xK9mPq",
  "originalUrl": "https://example.com/long/path",
  "createdAt":   "2026-04-28T10:00:00.000Z"
}
```

### Follow a short URL

```bash
curl -v <api_url>/xK9mPq
# → HTTP 302  Location: https://example.com/long/path
```

---

## 🔒 Security

| Layer | Detail |
|-------|--------|
| API Gateway throttling | 20 req/s sustained · 50 req/s burst |
| WAF rate limiting | 100 requests / 5 min per IP |
| WAF managed rules | SQLi, XSS, known bad inputs |
| S3 | Private bucket · accessible only via CloudFront OAC |
| DynamoDB | Encrypted at rest · point-in-time recovery enabled |
| Lambda IAM | Least-privilege — only exact DynamoDB actions needed |

---

## 🗑️ Tear Down

```bash
cd infra
terraform destroy
```

> ⚠️ This permanently removes **all** AWS resources created by Terraform.

---

<div align="center">

Built with ❤️ on AWS + Terraform &nbsp;·&nbsp; [Open an issue](../../issues) &nbsp;·&nbsp; [Pull requests welcome](../../pulls)

</div>