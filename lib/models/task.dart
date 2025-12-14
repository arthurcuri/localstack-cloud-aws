import 'dart:convert';
import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime createdAt;
  final String categoryId;

  // CAMERA
  final String? photoPath; // Kept for compatibility
  final List<String> photoPaths; // New photo list

  // SENSORES
  final DateTime? completedAt;
  final String? completedBy; // 'manual', 'shake'

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.priority = 'medium',
    DateTime? createdAt,
    this.categoryId = 'other',
    this.photoPath,
    List<String>? photoPaths,
    this.completedAt,
    this.completedBy,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       photoPaths = photoPaths ?? (photoPath != null ? [photoPath] : []);

  // Getters auxiliares
  bool get hasPhoto => photoPaths.isNotEmpty;
  bool get wasCompletedByShake => completedBy == 'shake';
  int get photoCount => photoPaths.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'categoryId': categoryId,
      'photoPath': photoPath,
      'photoPaths': jsonEncode(photoPaths),
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // Processa photoPaths: tenta ler da nova coluna, senão usa photoPath antigo
    List<String> photoPaths = [];
    if (map['photoPaths'] != null && map['photoPaths'] is String) {
      try {
        final decoded = jsonDecode(map['photoPaths']);
        photoPaths = List<String>.from(decoded);
      } catch (e) {
        // Se falhar, tenta usar photoPath antigo
        if (map['photoPath'] != null &&
            (map['photoPath'] as String).isNotEmpty) {
          photoPaths = [map['photoPath'] as String];
        }
      }
    } else if (map['photoPath'] != null &&
        (map['photoPath'] as String).isNotEmpty) {
      // Compatibilidade com versão antiga
      photoPaths = [map['photoPath'] as String];
    }

    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      completed: map['completed'] == 1,
      priority: map['priority'] ?? 'medium',
      createdAt: DateTime.parse(map['createdAt']),
      categoryId: map['categoryId'] ?? 'other',
      photoPath: map['photoPath'] as String?,
      photoPaths: photoPaths,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      completedBy: map['completedBy'] as String?,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    bool? completed,
    String? priority,
    String? categoryId,
    String? photoPath,
    List<String>? photoPaths,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      categoryId: categoryId ?? this.categoryId,
      photoPath: photoPath ?? this.photoPath,
      photoPaths: photoPaths ?? this.photoPaths,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }
}
