locals {
  name_prefix     = "${var.project_name}-${var.environment}-${var.service_name}"
  ssm_path_prefix = "/${var.project_name}/${var.environment}/${var.service_name}"

  # Nomes finais: execucao-ordens, execucao-estoque, execucao-servicos, execucao-mensagens.
  tabelas = {
    ordens    = "${var.table_prefix}-ordens"
    estoque   = "${var.table_prefix}-estoque"
    servicos  = "${var.table_prefix}-servicos"
    mensagens = "${var.table_prefix}-mensagens"
  }
}
