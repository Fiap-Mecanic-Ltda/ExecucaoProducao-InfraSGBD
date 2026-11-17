output "tabelas" {
  description = "Nome de cada tabela."
  value = {
    ordens    = aws_dynamodb_table.ordens.name
    estoque   = aws_dynamodb_table.estoque.name
    servicos  = aws_dynamodb_table.servicos.name
    mensagens = aws_dynamodb_table.mensagens.name
  }
}

output "policy_arn" {
  description = "Policy de acesso as tabelas, anexada a role dos nos do k3s pelo ExecucaoProducao-InfraKubernete."
  value       = aws_iam_policy.acesso_tabelas.arn
}

output "ssm_path_prefix" {
  value = local.ssm_path_prefix
}
