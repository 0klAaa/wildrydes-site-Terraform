########################################
# OUTPUTS : ce que je veux récupérer
########################################

output "cognito_user_pool_id" {
  description = "ID du User Pool Cognito WildRydes"
  value       = aws_cognito_user_pool.wildrydes.id
}

output "cognito_user_pool_client_id" {
  description = "ID du client d'application Web WildRydes"
  value       = aws_cognito_user_pool_client.web_app.id
}

output "api_invoke_url" {
  description = "URL d'invocation de l'API WildRydes"
  value       = "https://${aws_api_gateway_rest_api.wildrydes.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "amplify_default_domain" {
  description = "Domaine par défaut Amplify"
  value       = aws_amplify_app.wildrydes.default_domain
}