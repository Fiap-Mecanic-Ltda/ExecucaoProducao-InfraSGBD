variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "mechanicltda"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "service_name" {
  type        = string
  description = "Sufixo do microsservico no prefixo do SSM e nos nomes de IAM."
  default     = "execucao"
}

variable "table_prefix" {
  type        = string
  description = "Prefixo das tabelas (DynamoDb:PrefixoTabelas na API). Tem de bater com o ADR-003 do ExecucaoProducao-service."
  default     = "execucao"
}

variable "point_in_time_recovery" {
  type        = bool
  description = "Backup continuo (PITR) das tabelas de negocio. A tabela de mensagens e temporaria e fica sem."
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Impede apagar as tabelas de negocio pelo console ou por um destroy acidental. Desligue antes de um terraform destroy."
  default     = false
}
