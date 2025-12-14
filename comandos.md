# Comandos Rápidos

```
https://app.localstack.cloud/inst/default/resources
```

## Configuração Inicial

```bash
aws configure set aws_access_key_id test && aws configure set aws_secret_access_key test && aws configure set region us-east-1 && aws configure set output json
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

## Verificações

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