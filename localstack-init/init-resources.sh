#!/bin/bash

echo "🚀 Inicializando recursos do LocalStack..."

# Configurar AWS CLI para LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
ENDPOINT_URL=http://localhost:4566

# Criar bucket S3
echo "📦 Criando bucket S3: shopping-images"
awslocal s3 mb s3://shopping-images 2>/dev/null || echo "✓ Bucket já existe"
awslocal s3api put-bucket-acl --bucket shopping-images --acl public-read

# Criar tabela DynamoDB
echo "🗄️  Criando tabela DynamoDB: shopping-tasks"
awslocal dynamodb create-table \
    --table-name shopping-tasks \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
        AttributeName=createdAt,AttributeType=S \
    --key-schema \
        AttributeName=id,KeyType=HASH \
    --global-secondary-indexes \
        "[{
            \"IndexName\": \"createdAt-index\",
            \"KeySchema\": [{\"AttributeName\":\"createdAt\",\"KeyType\":\"HASH\"}],
            \"Projection\":{\"ProjectionType\":\"ALL\"},
            \"ProvisionedThroughput\":{\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}
        }]" \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    2>/dev/null || echo "✓ Tabela já existe"

# Criar fila SQS
echo "📮 Criando fila SQS: shopping-queue"
awslocal sqs create-queue --queue-name shopping-queue 2>/dev/null || echo "✓ Fila já existe"

# Criar tópico SNS
echo "📢 Criando tópico SNS: shopping-notifications"
awslocal sns create-topic --name shopping-notifications 2>/dev/null || echo "✓ Tópico já existe"

# Obter ARN do tópico e URL da fila para criar subscrição
TOPIC_ARN=$(awslocal sns list-topics --query "Topics[?contains(TopicArn, 'shopping-notifications')].TopicArn" --output text)
QUEUE_URL=$(awslocal sqs get-queue-url --queue-name shopping-queue --query 'QueueUrl' --output text)
QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url $QUEUE_URL --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

# Inscrever a fila no tópico SNS
echo "🔗 Conectando SNS ao SQS"
awslocal sns subscribe \
    --topic-arn $TOPIC_ARN \
    --protocol sqs \
    --notification-endpoint $QUEUE_ARN \
    2>/dev/null || echo "✓ Subscrição já existe"

# Listar recursos criados
echo ""
echo "✅ Recursos criados com sucesso!"
echo ""
echo "📦 Buckets S3:"
awslocal s3 ls

echo ""
echo "🗄️  Tabelas DynamoDB:"
awslocal dynamodb list-tables

echo ""
echo "📮 Filas SQS:"
awslocal sqs list-queues

echo ""
echo "📢 Tópicos SNS:"
awslocal sns list-topics

echo ""
echo "🎉 LocalStack está pronto para uso!"
