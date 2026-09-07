# ClinicFlow: Cloud Operations & Security Proof of Concept

![Terraform](https://img.shields.io/badge/terraform-HCL-purple) ![AWS](https://img.shields.io/badge/AWS-Architecture-orange) ![Compliance](https://img.shields.io/badge/compliance-HIPAA_Aligned-blue) ![Status](https://img.shields.io/badge/Status-Technical_Demo-yellow)

> **⚠️ Project Status: Technical Demonstration**
> This repository is a proof-of-concept built to demonstrate cloud operations, infrastructure-as-code (IaC), and compliance principles. It is a portfolio asset, not a production-ready environment, and is **not** configured to process live Protected Health Information (PHI). 

ClinicFlow is an enterprise-grade AWS architecture engineered entirely via Infrastructure as Code (IaC) using Terraform. I built this to deeply understand the architecture, security constraints, and operational realities of compliance-driven cloud environments. 

Instead of treating cloud security as a manual checklist, this project demonstrates how to enforce compliance as an immutable, software-defined state.

## 🏗️ System Architecture

```text
+-----------------------------------------------------------------------+
|                              AWS Cloud                                |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |                            VPC                                  |  |
|  |  +-------------------------+       +-------------------------+  |  |
|  |  |      Public Subnet      |       |     Private Subnet      |  |  |
|  |  |  [ Internet Gateway ]   |       |   [ ECS Fargate ]       |  |  |
|  |  |           |             |       |          |              |  |  |
|  |  |  [ App Load Balancer ]--+-------+-> [ RDS PostgreSQL ]    |  |  |
|  |  |           |             |       |                         |  |  |
|  |  |     [ NAT Gateway ]     |       |                         |  |  |
|  |  +-------------------------+       +-------------------------+  |  |
|  +-----------------------------------------------------------------+  |
|                                                                       |
|  +-----------------------------------------------------------------+  |
|  |               Security & Automated Remediation                  |  |
|  |  [ CloudTrail ] ---> [ GuardDuty ] ---> [ EventBridge ]         |  |
|  |                                                |                |  |
|  |  [ KMS Encryption ]  [ S3 WORM Vault ] <--- [ Lambda Healer ]   |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
