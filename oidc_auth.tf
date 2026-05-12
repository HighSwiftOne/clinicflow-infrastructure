# This tells AWS to trust GitHub's identity certificates
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # The thumbprint for GitHub's certificate
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# This is the "Bouncer" role GitHub will assume
resource "aws_iam_role" "github_actions_role" {
  name = "ClinicFlow-GitHub-Actions-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:HighSwiftOne/clinicflow-infrastructure:*"
          }
        }
      }
    ]
  })
}

# Give the bouncer permission to manage the vault
resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}