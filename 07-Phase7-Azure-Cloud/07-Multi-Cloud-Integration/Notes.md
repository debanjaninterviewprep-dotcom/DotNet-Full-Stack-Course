# Topic 7: Multi-Cloud Integration Scenarios

> Most real-world systems aren't single-cloud. Acquisitions, vendor lock-in fears, regulatory data placement, and "best service for the job" all push companies into AWS + Azure + GCP simultaneously. This topic covers what *multi-cloud* actually means in practice, the four common integration patterns, and how to wire TaskFlow's Azure stack to a service hosted elsewhere — without doubling your operational pain.

---

## 1. Multi-Cloud vs Hybrid vs Cross-Cloud — Define Your Terms

| Term | What it means | TaskFlow example |
|---|---|---|
| **Multi-cloud** | Workloads on **multiple public clouds** (Azure + AWS) | API on Azure, ML model on AWS SageMaker |
| **Hybrid cloud** | A mix of public cloud + **on-prem datacenter** | Azure API ↔ on-prem SQL Server |
| **Cross-cloud** | A *single* workload spanning multiple clouds | Same app, multiple regions, multiple clouds |
| **Multi-region** | Multiple regions of the **same** cloud | Azure East US + Azure West Europe |

Most teams claim "multi-cloud" when they mean "multiple unrelated workloads on different clouds". Real **cross-cloud** is rare and expensive — choose only when forced.

> **Default stance:** prefer **multi-region** within one cloud over cross-cloud whenever possible. The operational cost of cross-cloud is real and often dwarfs the resilience or vendor-lock-in upside.

---

## 2. Why Multi-Cloud Happens (Be Honest)

Good reasons:

1. **Acquisitions** — you bought a company on AWS; you can't migrate Day 1.
2. **Best-in-class** — a specific service is unmatched (BigQuery for ML, Azure OpenAI, AWS Lambda@Edge).
3. **Data sovereignty** — regulator requires data in a region only one cloud has.
4. **Customer mandates** — enterprise customers demand "we deploy to your cloud".

Bad reasons (often disguised as good):

- "Avoid vendor lock-in" — you'll lock into Kubernetes, Postgres, Terraform anyway.
- "Negotiating leverage" — the cost to actually migrate is far higher than the discount.
- "Resilience" — same-cloud multi-region is usually enough; cross-cloud DR is rarely tested.

---

## 3. The Four Integration Patterns

### 3.1 Service-to-Service via HTTPS

The simplest pattern. Service in Cloud A calls a public HTTPS endpoint of a service in Cloud B, authenticated via OAuth/OIDC.

```
[ Azure Function ] ──HTTPS──► [ AWS API Gateway ] ──► [ Lambda ]
                  ◄── JWT ◄── (Cognito / OIDC IdP)
```

Use when: low-volume, latency-tolerant, public-internet-acceptable.

### 3.2 Cross-Cloud Messaging Bridge

A **broker** in one cloud accepts events; a relay copies them to the other cloud's broker.

```
[ Azure Service Bus ] ──► [ relay func ] ──► [ AWS SQS ]
```

Use when: async work, event-driven choreography across clouds.

### 3.3 Federated Identity

Both clouds trust a single IdP (Microsoft Entra, Okta, AWS IAM Identity Center). Workloads in either cloud get short-lived tokens via OIDC federation.

- **GitHub Actions → Azure**: Workload Identity Federation (covered in Topic 1).
- **GitHub Actions → AWS**: OIDC role assumption.
- **Azure → AWS**: AWS IAM trusts Entra issuer; Azure workload assumes an IAM role.

This eliminates static cross-cloud secrets — the killer pain of multi-cloud.

### 3.4 Cross-Cloud Network Connectivity

When you need private IP-to-IP between clouds:

| Option | What it is | Use for |
|---|---|---|
| **Public peering** (default) | Traffic over internet, mTLS at app layer | Most multi-cloud |
| **Site-to-Site VPN** | IPSec tunnels Azure VNet ↔ AWS VPC | Hybrid / regulated |
| **Megaport / Equinix Fabric** | Private circuit at a colo | Big enterprises, predictable latency |
| **Cloud provider partnerships** | Azure ExpressRoute + AWS Direct Connect via colo | Same as above |

---

## 4. Authentication Across Clouds: The OIDC Federation Pattern

The end-state pattern you should aim for:

```
1. Azure workload (Function App with MI) requests an Entra token.
2. Azure presents the token to AWS STS via AssumeRoleWithWebIdentity.
3. AWS verifies the issuer (`https://login.microsoftonline.com/<tenant>`),
   the audience, and a custom subject claim.
4. AWS returns short-lived credentials (15 min - 12 hour).
5. Azure workload calls AWS APIs.
```

No long-lived AWS access keys leave AWS. No Azure secrets leave Azure. Just signed JWTs.

### Configuring AWS to trust Entra

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<account>:oidc-provider/login.microsoftonline.com/<tenantId>/v2.0"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "login.microsoftonline.com/<tenantId>/v2.0:aud": "<aws-audience>",
        "login.microsoftonline.com/<tenantId>/v2.0:sub": "<your-mi-object-id>"
      }
    }
  }]
}
```

### Calling AWS from Azure

```csharp
var credential = new DefaultAzureCredential();
var token = await credential.GetTokenAsync(
    new TokenRequestContext(new[] { "<aws-audience>" }),
    CancellationToken.None);

var sts = new AmazonSecurityTokenServiceClient(new AnonymousAWSCredentials());
var resp = await sts.AssumeRoleWithWebIdentityAsync(new()
{
    RoleArn = "<aws-role-arn>",
    RoleSessionName = "azure-taskflow",
    WebIdentityToken = token.Token,
    DurationSeconds = 3600,
});

var s3 = new AmazonS3Client(resp.Credentials);
await s3.PutObjectAsync(new PutObjectRequest { /* ... */ });
```

---

## 5. Cross-Cloud Data Replication

| Pattern | Use case | Tool examples |
|---|---|---|
| **DB log-based replication** | Postgres on Azure → Postgres on AWS | Debezium → Kafka → Sink |
| **Object storage sync** | Blob → S3 backup | `azcopy`, `rclone`, custom Functions |
| **Change-feed mirror** | Cosmos DB → DynamoDB | Change feed Function App → DynamoDB SDK |
| **Periodic export** | Daily snapshot to other cloud | Cron job, parquet files |

> **Eventual consistency is the default.** Anything billing-critical that *must* be in two clouds simultaneously is a special case requiring serious engineering (sagas, two-phase commits, vendor lock-in to Atomic services).

---

## 6. Observability Across Clouds

Don't end up with three different monitoring tools. Pick one of:

1. **Azure Monitor + AWS CloudWatch + GCP Cloud Logging**, federated to a SIEM (Splunk, Datadog).
2. **One vendor tool** (Datadog, New Relic, Dynatrace) with agents in every cloud.
3. **OpenTelemetry** + a shared backend (Tempo, Jaeger, Honeycomb). Increasingly the standard.

For TaskFlow course: instrument with **OpenTelemetry**, send to App Insights for now, but the same traces could go anywhere.

---

## 7. Cost & Egress Pitfalls

The **#1 surprise** in multi-cloud is **egress** (data leaving one cloud) cost:

- Azure → public internet: ~$0.087/GB.
- AWS → public internet: ~$0.09/GB.
- Cross-region within a cloud: $0.02/GB.

A daily 100 GB sync between clouds = ~$300/month. Architect to:

- Keep chatty workloads colocated.
- Compress and batch.
- Use private peering / Direct Connect partnerships if scale justifies.
- Keep storage where it's most-read, do writes in either cloud.

---

## 8. Deployment & IaC

Don't manage two cloud-native IaC stacks (ARM/Bicep + CloudFormation). Pick:

- **Terraform** — provider-per-cloud, single state per environment.
- **Pulumi** — same, with general-purpose languages.
- **Crossplane** — Kubernetes-style, declares cloud resources from cluster.

Keep modules cloud-agnostic at the boundary; cloud-specific underneath.

---

## 9. TaskFlow Multi-Cloud Scenario

Imagine TaskFlow needs:

- Backend API: **Azure App Service** (already built).
- Document AI / OCR: **AWS Textract** (best-in-class).
- ML model serving: **GCP Vertex AI** (acquired company).

Architecture:

```
[ TaskFlow Web ]
       ▼
[ Azure APIM ]
       ▼
[ Azure App Service ]
       ├── (sync) → AWS API Gateway → Textract  (OIDC AssumeRole)
       └── (async) → Service Bus → Relay Func → SQS → Lambda → Vertex AI
                                                 (events for ML enrichment)
```

Authentication: Entra → AWS STS via federation; Entra → GCP Workload Identity Federation similar.

---

## 10. Anti-Patterns

| ❌ Don't | ✅ Do |
|---|---|
| Sync chatty traffic across clouds | Aggregate / batch / colocate |
| Use long-lived static credentials between clouds | OIDC federation, short-lived tokens |
| Replicate state-of-record into 3 clouds | Pick a primary; the others read-only |
| Build the entire stack twice "for portability" | Cloud-specific until it hurts |
| Skip end-to-end DR drills | Test failover at least quarterly |

---

## 11. Decision Framework

Before reaching for cross-cloud:

1. Can we do this **multi-region in one cloud**?
2. Is the second-cloud feature truly unique, or is there a usable equivalent?
3. What is the **annual egress cost** at projected scale?
4. Do we have **federated identity** ready, or are we creating long-lived secrets?
5. Who owns the runbook for cross-cloud incidents?

If 3 of 5 answers are concerning, simplify to single-cloud + multi-region.

---

## Further Reading

- [Microsoft: Multi-cloud strategy](https://learn.microsoft.com/azure/cloud-adoption-framework/strategy/cloud-deployment-models)
- [Federate Entra to AWS via OIDC](https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation)
- [Workload Identity Federation to GCP](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Egress costs comparison](https://aws.amazon.com/blogs/aws/aws-data-transfer-prices-reduced/)
- [CNCF state of multi-cloud](https://www.cncf.io/research/)
