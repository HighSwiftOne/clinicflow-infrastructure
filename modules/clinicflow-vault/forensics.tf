# ============================================
# AMAZON DETECTIVE – INVESTIGATION GRAPH
# ============================================
resource "aws_detective_graph" "clinicflow" {
  # No configuration required – enables Detective in the current region
  # Detective automatically creates the necessary service-linked role

  tags = {
    Environment = "Production"
    Service     = "Detective"
    HIPAA       = "Forensics"
  }
}