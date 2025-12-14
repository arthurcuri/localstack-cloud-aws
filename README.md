# Task Manager - Cloud Simulation com LocalStack

![LocalStack](ls.png)

Sistema de gerenciamento de tarefas com simulação de serviços AWS (S3, DynamoDB, SQS, SNS) usando LocalStack para desenvolvimento e testes locais sem custos de cloud.

## Arquitetura de Cloud Simulation

O sistema utiliza LocalStack para simular serviços AWS localmente:

- **S3**: Bucket `shopping-images` para armazenamento de fotos
- **DynamoDB**: Tabela `shopping-tasks` para metadados
- **SQS**: Fila `shopping-queue` para processamento assíncrono
- **SNS**: Tópico `shopping-notifications` para eventos

## Tecnologias Utilizadas

- **Flutter**: Framework mobile/desktop cross-platform
- **Node.js**: Backend API REST
- **Express**: Framework web
- **LocalStack**: Simulação de serviços AWS
- **AWS SDK**: Cliente AWS para Node.js
- **Docker**: Containerização de LocalStack e Backend
- **SQLite**: Database local no app Flutter


## Pré-requisitos

- Docker e Docker Compose
- Flutter SDK (versão 3.0 ou superior)
- Node.js (versão 18 ou superior)
- AWS CLI (para validação)
- Git

## Instalação e Execução

### 1. Configurar AWS CLI

```bash
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set output json
```

### 2. Iniciar Infraestrutura

```bash
docker-compose up -d
```

### 3. Executar App Flutter

```bash
flutter pub get
flutter run -d linux
```

## Demonstração

### Roteiro de Demonstração

1. **Setup**: Execute `docker-compose up -d` e aguarde 15 segundos
2. **Validação**: Verifique recursos com `aws --endpoint-url=http://localhost:4566 s3 ls`
3. **App**: Execute `flutter run -d linux`
4. **Teste**: Crie uma tarefa com foto
5. **Evidências**:
   - Verifique imagem no S3: `curl http://localhost:3000/api/images | jq`
   - Verifique task no DynamoDB: `curl http://localhost:3000/api/tasks | jq`
   - Backend health check: `curl http://localhost:3000/health`

## Endpoints da API

### Health Check
- `GET /health` - Status do backend

### Upload
- `POST /api/upload/base64` - Upload de imagem Base64

### Tarefas
- `POST /api/tasks` - Criar tarefa
- `GET /api/tasks` - Listar todas as tarefas
- `GET /api/tasks/:id` - Buscar tarefa por ID

### S3
- `GET /api/images` - Listar imagens no bucket
- `GET /api/images/:key` - Obter URL de imagem

### SQS
- `GET /api/queue/messages` - Receber mensagens da fila

### SNS
- `POST /api/notifications` - Publicar notificação

## Comandos Úteis

```bash
# Verificar recursos LocalStack
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
aws --endpoint-url=http://localhost:4566 sqs list-queues
aws --endpoint-url=http://localhost:4566 sns list-topics

# Logs dos containers
docker logs -f localstack-main
docker logs -f shopping-backend

# Parar tudo
docker-compose down

# Reset completo
docker-compose down -v && rm -rf localstack-data

# Limpar portas ocupadas
sudo lsof -ti:4566,3000 | xargs kill -9
```

## Verificação no LocalStack

### Via AWS CLI

```bash
# Listar objetos S3
aws --endpoint-url=http://localhost:4566 s3 ls s3://shopping-images/tasks/

# Scan DynamoDB
aws --endpoint-url=http://localhost:4566 dynamodb scan --table-name shopping-tasks

# Receber mensagens SQS
aws --endpoint-url=http://localhost:4566 sqs receive-message \
    --queue-url http://localhost:4566/000000000000/shopping-queue
```