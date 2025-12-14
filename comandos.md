# Comandos Rápidos - LocalStack

## Configuração Inicial

```bash
# Configurar AWS CLI com credenciais fake para LocalStack
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set output json

# Ou em uma linha:
aws configure set aws_access_key_id test && aws configure set aws_secret_access_key test && aws configure set region us-east-1 && aws configure set output json
```

## ⚡ Início Rápido

```bash
# Opção 1: Script automático (RECOMENDADO)
./start-demo.sh

# Opção 2: Manual
docker-compose up -d
sleep 15
flutter run -d linux
```

## Docker

```bash
# Subir
docker-compose up -d

# Ver logs
docker logs -f localstack-main
docker logs -f shopping-backend

# Status
docker ps

# Parar
docker-compose down

# Reset completo
docker-compose down -v && rm -rf localstack-data
```

## 🔍 Verificações

```bash
# Health check
curl http://localhost:3000/health

# Listar recursos
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
aws --endpoint-url=http://localhost:4566 sqs list-queues
aws --endpoint-url=http://localhost:4566 sns list-topics
```

## S3

```bash
# Listar buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Listar objetos
aws --endpoint-url=http://localhost:4566 s3 ls s3://shopping-images/tasks/

# Via API
curl http://localhost:3000/api/images | jq

# Navegador
open http://localhost:4566/shopping-images/?list-type=2
```

## DynamoDB

```bash
# Listar tabelas
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# Scan completo
aws --endpoint-url=http://localhost:4566 dynamodb scan \
    --table-name shopping-tasks | jq

# Via API
curl http://localhost:3000/api/tasks | jq

# Contar tarefas
curl http://localhost:3000/api/tasks | jq '.count'
```

## SQS

```bash
# Listar filas
aws --endpoint-url=http://localhost:4566 sqs list-queues

# Receber mensagens (via API)
curl http://localhost:3000/api/queue/messages | jq
```

## SNS

```bash
# Listar tópicos
aws --endpoint-url=http://localhost:4566 sns list-topics

# Publicar notificação (via API)
curl -X POST http://localhost:3000/api/notifications \
  -H "Content-Type: application/json" \
  -d '{"action":"TEST","message":"Teste"}'
```


## Flutter

```bash
# Instalar dependências
flutter pub get

# Rodar
flutter run -d linux

# Limpar e rebuild
flutter clean && flutter pub get && flutter run -d linux
```

## Monitoramento

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

## Troubleshooting

```bash
# Verificar portas em uso
sudo lsof -i :4566
sudo lsof -i :3000

# Reiniciar tudo
docker-compose restart

# Ver rede Docker
docker network inspect localstack_localstack-network

# Recriar bucket manualmente
aws --endpoint-url=http://localhost:4566 s3 mb s3://shopping-images
aws --endpoint-url=http://localhost:4566 s3api put-bucket-acl \
    --bucket shopping-images --acl public-read
```

## Estatísticas

```bash
# Total de recursos
echo "Imagens S3: $(curl -s http://localhost:3000/api/images | jq '.count')"
echo "Tarefas DynamoDB: $(curl -s http://localhost:3000/api/tasks | jq '.count')"
echo "Mensagens SQS: $(curl -s http://localhost:3000/api/queue/messages | jq '.count')"
```