# Contrato com o deploy (ExecucaoProducao-InfraKubernete): o prefixo das tabelas e a regiao ficam
# no SSM, no prefixo do servico, e viram DynamoDb__PrefixoTabelas e DynamoDb__Regiao no pod.
resource "aws_ssm_parameter" "prefixo_tabelas" {
  name  = "${local.ssm_path_prefix}/dynamodb-prefixo-tabelas"
  type  = "String"
  value = var.table_prefix
}

resource "aws_ssm_parameter" "regiao" {
  name  = "${local.ssm_path_prefix}/dynamodb-regiao"
  type  = "String"
  value = var.aws_region
}
