# ====================================================================
# CLINICFLOW TENANT DEPLOYMENT: MEDSPA ALPHA
# ====================================================================
module "clinicflow_baseline" {
  source = "../../modules/clinicflow_baseline"

  client_name = "MedSpa-Alpha"
  environment = "Production"
  aws_region  = "us-east-1"
  alert_email = "conallkeenan@gmail.com"
}
