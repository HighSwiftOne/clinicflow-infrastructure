# ====================================================================
# DYNAMIC SANDBOX PKI (PUBLIC KEY INFRASTRUCTURE)
# ====================================================================

# 1. Generate a secure RSA private key
resource "tls_private_key" "sandbox_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# 2. Create a self-signed certificate for the local network boundary
resource "tls_self_signed_cert" "sandbox_cert" {
  private_key_pem = tls_private_key.sandbox_key.private_key_pem

  subject {
    common_name  = "sandbox.clinicflow.internal"
    organization = "ClinicFlow Infrastructure"
  }

  validity_period_hours = 8760 # 1 Year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# 3. Import the dynamic certificate directly into AWS ACM
resource "aws_acm_certificate" "sandbox_cert" {
  private_key      = tls_private_key.sandbox_key.private_key_pem
  certificate_body = tls_self_signed_cert.sandbox_cert.cert_pem

  tags = {
    Environment = "Sandbox"
    Security    = "Automated-Internal-PKI"
  }
}