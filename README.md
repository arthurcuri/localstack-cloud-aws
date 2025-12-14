# Task Manager - Cloud Simulation com LocalStack

![LocalStack](ls.png)

Sistema de gerenciamento de tarefas com simulação de serviços AWS (S3, DynamoDB, SQS, SNS) usando LocalStack para desenvolvimento e testes locais sem custos de cloud.

## Funcionalidades

- **Gerenciamento de Tarefas**: Criação de tarefas com descrição e categorias
- **Captura de Fotos**: Integração com câmera para anexar imagens às tarefas
- **Armazenamento S3**: Upload de fotos para bucket S3 simulado localmente
- **Persistência DynamoDB**: Metadados de tarefas salvos em tabela NoSQL
- **Mensageria SQS**: Fila de processamento de tarefas
- **Notificações SNS**: Publicação de eventos de criação de tarefas
- **Offline-First**: SQLite local com sincronização para cloud

## Arquitetura de Cloud Simulation

O sistema utiliza LocalStack para simular serviços AWS localmente:

- **S3**: Bucket `shopping-images` para armazenamento de fotos
- **DynamoDB**: Tabela `shopping-tasks` para metadados
- **SQS**: Fila `shopping-queue` para processamento assíncrono
- **SNS**: Tópico `shopping-notifications` para eventos

### Fluxo de Upload

1. Usuário tira foto no app Flutter
2. Imagem convertida para Base64
3. Backend recebe POST com imagem
4. Foto salva no S3 (LocalStack)
5. Metadados salvos no DynamoDB
6. Mensagem enviada para SQS
7. Notificação publicada no SNS

## Tecnologias Utilizadas

- **Flutter**: Framework mobile/desktop cross-platform
- **Node.js**: Backend API REST
- **Express**: Framework web
- **LocalStack**: Simulação de serviços AWS
- **AWS SDK**: Cliente AWS para Node.js
- **Docker**: Containerização de LocalStack e Backend
- **SQLite**: Database local no app Flutter

## Estrutura da Aplicação

```
localstack/
├── docker-compose.yml          # Orquestração de containers
├── localstack-init/
│   └── init-resources.sh       # Script de inicialização AWS
├── backend/
│   ├── server.js               # API REST (porta 3000)
│   ├── Dockerfile              # Container do backend
│   └── package.json            # Dependências Node.js
├── lib/
│   ├── main.dart               # Entrada do app Flutter
│   ├── services/
│   │   ├── cloud_service.dart  # Integração com AWS
│   │   ├── database_service.dart
│   │   ├── camera_service.dart
│   │   └── notification_service.dart
│   ├── screens/
│   │   ├── task_list_screen.dart
│   │   ├── task_form_screen.dart
│   │   └── camera_screen.dart
│   └── models/
│       ├── task.dart
│       └── category.dart
└── docs/
    ├── DEMO_GUIDE.md           # Guia de demonstração
    ├── README_LOCALSTACK.md    # Documentação técnica
    └── QUICK_COMMANDS.md       # Comandos rápidos
```

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
# Opção 1: Script automático (RECOMENDADO)
./start-demo.sh

# Opção 2: Manual
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

### Logs Esperados

**Backend (LocalStack):**
```
Imagem salva no S3: tasks/[UUID]_[timestamp].jpg
Task salva no DynamoDB: [TASK_ID]
Mensagem enviada para SQS
Notificação publicada no SNS
```

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

### Via REST API

```bash
# Estatísticas
curl http://localhost:3000/api/images | jq '.count'
curl http://localhost:3000/api/tasks | jq '.count'
curl http://localhost:3000/api/queue/messages | jq '.count'
```

## Monitoramento em Tempo Real

```bash
# Terminal 1: Logs LocalStack
docker logs -f localstack-main

# Terminal 2: Logs Backend
docker logs -f shopping-backend

# Terminal 3: Imagens S3 (atualiza a cada 2s)
watch -n 2 'aws --endpoint-url=http://localhost:4566 s3 ls s3://shopping-images/tasks/'

# Terminal 4: Tarefas DynamoDB
watch -n 2 'curl -s http://localhost:3000/api/tasks | jq ".count"'
```

## Desenvolvimento

```bash
# Rebuild backend
docker-compose build backend
docker-compose up -d

# Reiniciar serviços
docker-compose restart

# Limpar cache Flutter
flutter clean && flutter pub get

# Recriar recursos AWS manualmente
./localstack-init/init-resources.sh
```
