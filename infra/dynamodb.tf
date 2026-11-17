# Esquema das tabelas da Execucao (ADR-003 do ExecucaoProducao-service). E o mesmo que a API cria
# no DynamoDB Local (DefinicaoTabelas.cs): uma mudanca de chave ou indice passa pelos dois.
# Todas em modo sob demanda (PAY_PER_REQUEST): sem capacidade provisionada para pagar parada.

# OS na Execucao: item EXECUCAO (estado atual) e itens HIST#... (historico) por OS.
# O indice status-index lista a fila por status, na ordem de dataAlteracaoStatus.
resource "aws_dynamodb_table" "ordens" {
  name                        = local.tabelas.ordens
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  range_key                   = "sk"
  deletion_protection_enabled = var.deletion_protection

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "dataAlteracaoStatus"
    type = "S"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "dataAlteracaoStatus"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  server_side_encryption {
    enabled = true
  }
}

# Pecas e insumos, com o contador de ids (pk CONTADOR). O indice tipo-index lista por tipo.
resource "aws_dynamodb_table" "estoque" {
  name                        = local.tabelas.estoque
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  deletion_protection_enabled = var.deletion_protection

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "tipo"
    type = "N"
  }

  global_secondary_index {
    name            = "tipo-index"
    hash_key        = "tipo"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  server_side_encryption {
    enabled = true
  }
}

# Catalogo de servicos da oficina.
resource "aws_dynamodb_table" "servicos" {
  name                        = local.tabelas.servicos
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "pk"
  deletion_protection_enabled = var.deletion_protection

  attribute {
    name = "pk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery
  }

  server_side_encryption {
    enabled = true
  }
}

# Mensagens da Saga ja tratadas (idempotencia), com a resposta publicada. O TTL apaga cada
# linha 7 dias depois (atributo expiraEm, em epoch), entao nao precisa de backup.
resource "aws_dynamodb_table" "mensagens" {
  name         = local.tabelas.mensagens
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  ttl {
    attribute_name = "expiraEm"
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }
}
