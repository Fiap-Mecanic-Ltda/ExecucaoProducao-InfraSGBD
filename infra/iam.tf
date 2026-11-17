# Permissao minima da API nas suas tabelas (e nos indices delas). A policy e anexada a role dos
# nos do k3s pelo ExecucaoProducao-InfraKubernete, que le o ARN pelo output policy_arn: os pods
# usam as credenciais da instancia, sem access key em Secret.
data "aws_iam_policy_document" "acesso_tabelas" {
  statement {
    sid = "TabelasDaExecucao"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:DescribeTable",
    ]
    resources = flatten([
      for tabela in [
        aws_dynamodb_table.ordens,
        aws_dynamodb_table.estoque,
        aws_dynamodb_table.servicos,
        aws_dynamodb_table.mensagens,
      ] : [tabela.arn, "${tabela.arn}/index/*"]
    ])
  }
}

resource "aws_iam_policy" "acesso_tabelas" {
  name        = "${local.name_prefix}-dynamodb"
  description = "Leitura e escrita da API da Execucao nas tabelas ${var.table_prefix}-*"
  policy      = data.aws_iam_policy_document.acesso_tabelas.json
}
