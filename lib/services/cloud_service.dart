import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class CloudService {
  static final CloudService instance = CloudService._init();
  CloudService._init();

  // URL base do backend (ajuste conforme necessário)
  static const String baseUrl = 'http://localhost:3000/api';

  // ==================== S3 - Upload de Imagens ====================

  /// Upload de imagem para S3 usando Base64
  Future<Map<String, dynamic>?> uploadImageBase64(
    String imagePath,
    String taskId,
  ) async {
    try {
      // Ler o arquivo e converter para Base64
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final response = await http.post(
        Uri.parse('$baseUrl/upload/base64'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'taskId': taskId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Imagem enviada para S3: ${data['imageKey']}');
        return data;
      } else {
        print('❌ Erro no upload: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  /// Listar todas as imagens do S3
  Future<List<Map<String, dynamic>>> listImages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/images'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['images'] ?? []);
      } else {
        print('❌ Erro ao listar imagens: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao listar imagens: $e');
      return [];
    }
  }

  // ==================== DynamoDB - Tarefas ====================

  /// Salvar tarefa no DynamoDB
  Future<bool> saveTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toMap()),
      );

      if (response.statusCode == 200) {
        print('✅ Tarefa salva no DynamoDB: ${task.id}');
        return true;
      } else {
        print('❌ Erro ao salvar tarefa: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao salvar tarefa: $e');
      return false;
    }
  }

  /// Listar todas as tarefas do DynamoDB
  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tasksJson = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
        return tasksJson.map((json) => Task.fromMap(json)).toList();
      } else {
        print('❌ Erro ao listar tarefas: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao listar tarefas: $e');
      return [];
    }
  }

  /// Obter tarefa por ID
  Future<Task?> getTaskById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks/$id'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Task.fromMap(data['task']);
      } else {
        print('❌ Erro ao buscar tarefa: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar tarefa: $e');
      return null;
    }
  }

  /// Deletar tarefa do DynamoDB
  Future<bool> deleteTask(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));

      if (response.statusCode == 200) {
        print('✅ Tarefa deletada do DynamoDB: $id');
        return true;
      } else {
        print('❌ Erro ao deletar tarefa: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao deletar tarefa: $e');
      return false;
    }
  }

  // ==================== SQS - Mensagens ====================

  /// Obter mensagens da fila SQS
  Future<List<Map<String, dynamic>>> getQueueMessages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/queue/messages'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['messages'] ?? []);
      } else {
        print('❌ Erro ao obter mensagens: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao obter mensagens: $e');
      return [];
    }
  }

  // ==================== SNS - Notificações ====================

  /// Publicar notificação no SNS
  Future<bool> publishNotification(Map<String, dynamic> notification) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notification),
      );

      if (response.statusCode == 200) {
        print('✅ Notificação publicada no SNS');
        return true;
      } else {
        print('❌ Erro ao publicar notificação: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao publicar notificação: $e');
      return false;
    }
  }

  // ==================== Funções Auxiliares ====================

  /// Verificar se o backend está acessível
  Future<bool> checkBackendHealth() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend não acessível: $e');
      return false;
    }
  }

  /// Sincronizar tarefa: salva localmente e na nuvem
  /// Faz upload de todas as fotos locais para S3
  Future<bool> syncTask(Task task, {List<String>? imagePaths}) async {
    try {
      List<String> s3Urls = [];

      // 1. Se houver fotos, fazer upload de TODAS para S3
      if (imagePaths != null && imagePaths.isNotEmpty) {
        print('📤 Iniciando upload de ${imagePaths.length} foto(s) para S3...');
        
        for (int i = 0; i < imagePaths.length; i++) {
          final imagePath = imagePaths[i];
          if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
            print('📤 Uploading foto ${i + 1}/${imagePaths.length}: $imagePath');
            
            final uploadResult = await uploadImageBase64(imagePath, task.id);
            if (uploadResult != null) {
              s3Urls.add(uploadResult['imageUrl']);
              print('✅ Foto ${i + 1} enviada: ${uploadResult['imageKey']}');
            } else {
              print('⚠️ Falha no upload da foto ${i + 1}');
            }
          }
        }

        // Atualizar tarefa com URLs do S3
        if (s3Urls.isNotEmpty) {
          task = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            completed: task.completed,
            priority: task.priority,
            createdAt: task.createdAt,
            categoryId: task.categoryId,
            photoPaths: s3Urls, // URLs do S3 em vez de paths locais
            completedAt: task.completedAt,
            completedBy: task.completedBy,
          );
          print('✅ ${s3Urls.length} foto(s) salva(s) no S3!');
        }
      }

      // 2. Salvar tarefa no DynamoDB (isso também envia para SQS e SNS)
      return await saveTask(task);
    } catch (e) {
      print('❌ Erro ao sincronizar tarefa: $e');
      return false;
    }
  }
}
