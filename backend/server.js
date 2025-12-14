const express = require('express');
const cors = require('cors');
const multer = require('multer');
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuração do AWS SDK para LocalStack
const awsConfig = {
  endpoint: process.env.AWS_ENDPOINT || 'http://localstack:4566',
  region: process.env.AWS_REGION || 'us-east-1',
  accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'test',
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'test',
  s3ForcePathStyle: true,
};

const s3 = new AWS.S3(awsConfig);
const dynamodb = new AWS.DynamoDB.DocumentClient(awsConfig);
const sqs = new AWS.SQS(awsConfig);
const sns = new AWS.SNS(awsConfig);

// Nomes dos recursos
const S3_BUCKET = process.env.S3_BUCKET_NAME || 'shopping-images';
const DYNAMODB_TABLE = process.env.DYNAMODB_TABLE_NAME || 'shopping-tasks';
const SQS_QUEUE = process.env.SQS_QUEUE_NAME || 'shopping-queue';
const SNS_TOPIC = process.env.SNS_TOPIC_NAME || 'shopping-notifications';

// Middlewares
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configuração do Multer para upload de arquivos
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

// ==================== ROTAS ====================

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Backend está funcionando!' });
});

// ==================== S3 - UPLOAD DE IMAGENS ====================

// Upload de imagem (Base64)
app.post('/api/upload/base64', async (req, res) => {
  try {
    const { image, taskId } = req.body;

    if (!image) {
      return res.status(400).json({ error: 'Imagem não fornecida' });
    }

    // Remover prefixo data:image/...;base64,
    const base64Data = image.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');

    const imageKey = `tasks/${taskId || uuidv4()}_${Date.now()}.jpg`;

    const params = {
      Bucket: S3_BUCKET,
      Key: imageKey,
      Body: buffer,
      ContentType: 'image/jpeg',
      ACL: 'public-read'
    };

    const result = await s3.upload(params).promise();

    console.log(`✅ Imagem salva no S3: ${imageKey}`);

    res.json({
      success: true,
      imageUrl: result.Location,
      imageKey: imageKey,
      bucket: S3_BUCKET
    });

  } catch (error) {
    console.error('❌ Erro no upload S3:', error);
    res.status(500).json({ error: error.message });
  }
});

// Upload de imagem (Multipart)
app.post('/api/upload/multipart', upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Nenhum arquivo enviado' });
    }

    const taskId = req.body.taskId || uuidv4();
    const imageKey = `tasks/${taskId}_${Date.now()}.jpg`;

    const params = {
      Bucket: S3_BUCKET,
      Key: imageKey,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      ACL: 'public-read'
    };

    const result = await s3.upload(params).promise();

    console.log(`✅ Imagem salva no S3: ${imageKey}`);

    res.json({
      success: true,
      imageUrl: result.Location,
      imageKey: imageKey,
      bucket: S3_BUCKET
    });

  } catch (error) {
    console.error('❌ Erro no upload S3:', error);
    res.status(500).json({ error: error.message });
  }
});

// Listar imagens do bucket
app.get('/api/images', async (req, res) => {
  try {
    const params = {
      Bucket: S3_BUCKET,
      Prefix: 'tasks/'
    };

    const data = await s3.listObjectsV2(params).promise();

    const images = data.Contents.map(item => ({
      key: item.Key,
      size: item.Size,
      lastModified: item.LastModified,
      url: `http://localhost:4566/${S3_BUCKET}/${item.Key}`
    }));

    res.json({ success: true, images, count: images.length });

  } catch (error) {
    console.error('❌ Erro ao listar imagens:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== DYNAMODB - TAREFAS ====================

// Criar/Atualizar tarefa
app.post('/api/tasks', async (req, res) => {
  try {
    const task = {
      id: req.body.id || uuidv4(),
      title: req.body.title,
      description: req.body.description,
      completed: req.body.completed || false,
      priority: req.body.priority || 'medium',
      categoryId: req.body.categoryId || 'other',
      photoPaths: req.body.photoPaths || [],
      createdAt: req.body.createdAt || new Date().toISOString(),
      completedAt: req.body.completedAt || null,
      completedBy: req.body.completedBy || null,
    };

    const params = {
      TableName: DYNAMODB_TABLE,
      Item: task
    };

    await dynamodb.put(params).promise();

    console.log(`✅ Tarefa salva no DynamoDB: ${task.id}`);

    // Enviar mensagem para SQS
    await sendToSQS({
      action: 'TASK_CREATED',
      task: task
    });

    // Publicar no SNS
    await publishToSNS({
      action: 'TASK_CREATED',
      taskId: task.id,
      title: task.title
    });

    res.json({ success: true, task });

  } catch (error) {
    console.error('❌ Erro ao salvar tarefa:', error);
    res.status(500).json({ error: error.message });
  }
});

// Listar todas as tarefas
app.get('/api/tasks', async (req, res) => {
  try {
    const params = {
      TableName: DYNAMODB_TABLE
    };

    const data = await dynamodb.scan(params).promise();

    res.json({ success: true, tasks: data.Items, count: data.Count });

  } catch (error) {
    console.error('❌ Erro ao listar tarefas:', error);
    res.status(500).json({ error: error.message });
  }
});

// Obter tarefa por ID
app.get('/api/tasks/:id', async (req, res) => {
  try {
    const params = {
      TableName: DYNAMODB_TABLE,
      Key: { id: req.params.id }
    };

    const data = await dynamodb.get(params).promise();

    if (!data.Item) {
      return res.status(404).json({ error: 'Tarefa não encontrada' });
    }

    res.json({ success: true, task: data.Item });

  } catch (error) {
    console.error('❌ Erro ao buscar tarefa:', error);
    res.status(500).json({ error: error.message });
  }
});

// Deletar tarefa
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const params = {
      TableName: DYNAMODB_TABLE,
      Key: { id: req.params.id }
    };

    await dynamodb.delete(params).promise();

    console.log(`✅ Tarefa deletada do DynamoDB: ${req.params.id}`);

    res.json({ success: true, message: 'Tarefa deletada' });

  } catch (error) {
    console.error('❌ Erro ao deletar tarefa:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== SQS - FILA ====================

// Função auxiliar para enviar mensagem ao SQS
async function sendToSQS(message) {
  try {
    const queueUrlResult = await sqs.getQueueUrl({ QueueName: SQS_QUEUE }).promise();
    const queueUrl = queueUrlResult.QueueUrl;

    const params = {
      QueueUrl: queueUrl,
      MessageBody: JSON.stringify(message),
      MessageAttributes: {
        'Action': {
          DataType: 'String',
          StringValue: message.action
        }
      }
    };

    await sqs.sendMessage(params).promise();
    console.log(`✅ Mensagem enviada para SQS: ${message.action}`);

  } catch (error) {
    console.error('❌ Erro ao enviar mensagem SQS:', error);
  }
}

// Receber mensagens do SQS
app.get('/api/queue/messages', async (req, res) => {
  try {
    const queueUrlResult = await sqs.getQueueUrl({ QueueName: SQS_QUEUE }).promise();
    const queueUrl = queueUrlResult.QueueUrl;

    const params = {
      QueueUrl: queueUrl,
      MaxNumberOfMessages: 10,
      WaitTimeSeconds: 1
    };

    const data = await sqs.receiveMessage(params).promise();

    const messages = (data.Messages || []).map(msg => ({
      id: msg.MessageId,
      body: JSON.parse(msg.Body),
      receiptHandle: msg.ReceiptHandle
    }));

    res.json({ success: true, messages, count: messages.length });

  } catch (error) {
    console.error('❌ Erro ao receber mensagens SQS:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== SNS - NOTIFICAÇÕES ====================

// Função auxiliar para publicar no SNS
async function publishToSNS(message) {
  try {
    const topicsResult = await sns.listTopics().promise();
    const topic = topicsResult.Topics.find(t => t.TopicArn.includes(SNS_TOPIC));

    if (!topic) {
      console.error('❌ Tópico SNS não encontrado');
      return;
    }

    const params = {
      TopicArn: topic.TopicArn,
      Message: JSON.stringify(message),
      Subject: `Notificação: ${message.action}`
    };

    await sns.publish(params).promise();
    console.log(`✅ Mensagem publicada no SNS: ${message.action}`);

  } catch (error) {
    console.error('❌ Erro ao publicar no SNS:', error);
  }
}

// Publicar notificação manualmente
app.post('/api/notifications', async (req, res) => {
  try {
    await publishToSNS(req.body);
    res.json({ success: true, message: 'Notificação enviada' });

  } catch (error) {
    console.error('❌ Erro ao enviar notificação:', error);
    res.status(500).json({ error: error.message });
  }
});

// ==================== SERVIDOR ====================

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Backend rodando na porta ${PORT}`);
  console.log(`📦 S3 Bucket: ${S3_BUCKET}`);
  console.log(`🗄️  DynamoDB Table: ${DYNAMODB_TABLE}`);
  console.log(`📮 SQS Queue: ${SQS_QUEUE}`);
  console.log(`📢 SNS Topic: ${SNS_TOPIC}`);
  console.log(`🔗 AWS Endpoint: ${awsConfig.endpoint}`);
});

module.exports = app;
