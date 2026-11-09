# ExecucaoProducao-InfraSGBD — Tabelas DynamoDB da Execução

Terraform das **tabelas DynamoDB próprias do microsserviço de Execução e Produção** (Fase 4), da
policy IAM de acesso a elas e dos parâmetros SSM que o deploy injeta no pod.

Cada microsserviço tem o seu banco (*database per service*): nenhum outro serviço acessa estas
tabelas. A Execução conversa com o OS Service só pela Saga (RabbitMQ), nunca por banco
compartilhado. A escolha do DynamoDB (NoSQL) está no ADR-003 do ExecucaoProducao-service.

## Os três repositórios da Execução

| # | Repositório | Conteúdo | CI/CD |
|---|---|---|---|
| 1 | [ExecucaoProducao-service](https://github.com/Fiap-Mecanic-Ltda/ExecucaoProducao-service) | API .NET 9 da Execução + participante da Saga | build, testes, cobertura e push da imagem no ECR |
| 2 | [ExecucaoProducao-InfraKubernete](https://github.com/Fiap-Mecanic-Ltda/ExecucaoProducao-InfraKubernete) | ECR, IAM/OIDC, rota no ALB + manifestos `k8s/` | `terraform plan/apply` + deploy no k3s |
| 3 | **ExecucaoProducao-InfraSGBD** (este) | Terraform das tabelas DynamoDB | `terraform plan/apply` |

## Tabelas

Todas em `PAY_PER_REQUEST` (nada provisionado parado) e com criptografia em repouso. O esquema é
o mesmo que a API cria no DynamoDB Local (`DefinicaoTabelas.cs`): mudança de chave ou índice passa
pelos dois repositórios.

| Tabela | Chave | Índice | Conteúdo |
|---|---|---|---|
| `execucao-ordens` | `pk` + `sk` | `status-index` (`status`, `dataAlteracaoStatus`) | OS na Execução: item `EXECUCAO` (estado atual) e itens `HIST#...` (histórico) |
| `execucao-estoque` | `pk` | `tipo-index` (`tipo`, numérico) | Peças e insumos, mais o contador de ids |
| `execucao-servicos` | `pk` | — | Catálogo de serviços |
| `execucao-mensagens` | `pk` | — | Idempotência da Saga (`{Tipo}#{correlationId}#{osId}#{dataHora}`), com TTL de 7 dias em `expiraEm` |

As tabelas de negócio têm backup contínuo (PITR). A de mensagens é temporária e fica sem.
`deletion_protection` vem desligado para permitir `terraform destroy` entre apresentações.

## Como este stack conversa com os outros

```text
ExecucaoProducao-InfraSGBD (state prod/execucao-sgbd/terraform.tfstate)
   │  cria: 4 tabelas execucao-*, policy mechanicltda-prod-execucao-dynamodb
   │  publica: /mechanicltda/prod/execucao/dynamodb-prefixo-tabelas
   │           /mechanicltda/prod/execucao/dynamodb-regiao
   ▼  output policy_arn
ExecucaoProducao-InfraKubernete
   │  anexa a policy à role dos nós do k3s
   ▼  lê os parâmetros do SSM no deploy
pods da Execução: DynamoDb__PrefixoTabelas e DynamoDb__Regiao
```

- **Não depende de rede**: DynamoDB é serviço gerenciado, sem VPC, subnet ou security group. Este
  stack pode ser aplicado antes ou depois do InfraKubernete.
- **Sem senha**: os pods usam as credenciais da instância (role dos nós), sem access key em Secret.
- A policy dá só o necessário (CRUD, Query, Scan e Batch) nas quatro tabelas e nos seus índices.

## Estrutura

```text
ExecucaoProducao-InfraSGBD/
├── infra/
│   ├── versions.tf              # backend S3 (chave prod/execucao-sgbd/terraform.tfstate) e provider
│   ├── data.tf                  # locals: prefixos e nomes das tabelas
│   ├── variables.tf             # project/environment/service, prefixo, PITR e deletion protection
│   ├── dynamodb.tf              # as quatro tabelas
│   ├── iam.tf                   # policy de acesso às tabelas
│   ├── ssm.tf                   # prefixo das tabelas e região no Parameter Store
│   └── outputs.tf               # nomes das tabelas, policy_arn e prefixo do SSM
└── .github/workflows/terraform.yml
```

## Rodando localmente

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars   # opcional: todos os valores têm default
terraform init
terraform plan
```

Para desenvolvimento não é preciso AWS: o `docker-compose` do ExecucaoProducao-service sobe o
DynamoDB Local e a API cria as tabelas sozinha.

## Secrets necessários no repositório GitHub

(Settings → Secrets and variables → Actions)

| Nome | Tipo | Uso |
|---|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Secret | Chave do `terraform-deployer` |
| `PUBLICAR_AWS` | Variable | Trava de publicação (veja abaixo) |

Não há `TF_VAR_*` secreto: todos os valores saem dos defaults de `infra/variables.tf`. Sem as
credenciais, o workflow roda só `fmt` e `validate`, sem falhar o PR. O Environment `production`
precisa existir para o job de `apply`.

## Fluxo de trabalho no Git

Mudanças entram por branch `feature/...` com Pull Request para **`homologacao`**, e a `main`
recebe a `homologacao` por Pull Request. Nada é commitado direto nas duas.

| Branch | O que roda (quando `infra/**` muda) |
|---|---|
| PR para `homologacao` ou `main` | `plan` |
| push em `homologacao` | `plan` — não há ambiente de homologação na AWS |
| push em `main` | `plan` e `apply` no Environment `production` (só com a trava liberada) |

**Trava de publicação:** o `apply` (automático ou manual) só roda com a Repository Variable
`PUBLICAR_AWS=true`. Sem ela, a `main` roda apenas o `plan` e nada é criado na AWS.

O `apply` manual (`workflow_dispatch`) só roda a partir da `main`. Configure revisores obrigatórios
no Environment `production`: recriar uma tabela apaga os dados dela.

## Custo

Em modo sob demanda, tabelas sem tráfego custam praticamente zero (só o armazenamento e o PITR).
Para zerar entre apresentações, rode `terraform destroy`: a API não recria as tabelas na AWS, então
aplique de novo antes do próximo deploy.
