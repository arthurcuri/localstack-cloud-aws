import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/camera_service.dart';
import '../services/cloud_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = criar novo, não-null = editar

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _priority = 'medium';
  bool _completed = false;
  bool _isLoading = false;
  String _categoryId = 'other';

  // CAMERA
  String? _photoPath; // Kept for compatibility
  List<String> _photoPaths = [];

  @override
  void initState() {
    super.initState();

    // Se estiver editando, preencher campos
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _priority = widget.task!.priority;
      _completed = widget.task!.completed;
      _categoryId = widget.task!.categoryId;
      _photoPath = widget.task!.photoPath;
      _photoPaths = List.from(widget.task!.photoPaths);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // CÂMERA METHODS
  Future<void> _showPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Escolha uma opção',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use device camera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    final photoPath = await CameraService.instance.takePicture(context);

    if (photoPath != null && mounted) {
      setState(() {
        _photoPaths.add(photoPath);
        _photoPath = photoPath; // Mantém compatibilidade
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📷 Photo captured!'),
          backgroundColor: Colors.pink,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final photoPath = await CameraService.instance.pickFromGallery(context);

    if (photoPath != null && mounted) {
      setState(() {
        _photoPaths.add(photoPath);
        _photoPath = photoPath; // Mantém compatibilidade
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
      _photoPath = _photoPaths.isNotEmpty ? _photoPaths.last : null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🗑️ Photo removed')));
  }

  void _removeAllPhotos() {
    setState(() {
      _photoPaths.clear();
      _photoPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ All photos removed')),
    );
  }

  void _viewPhoto(String photoPath, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Foto ${index + 1} de ${_photoPaths.length}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  Navigator.pop(context);
                  _removePhoto(index);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(photoPath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.task == null) {
        // Create new task
        final newTask = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          completed: _completed,
          categoryId: _categoryId,
          photoPath: _photoPath,
          photoPaths: _photoPaths,
        );
        
        // Salvar localmente
        await DatabaseService.instance.create(newTask);

        // Tentar sincronizar com a nuvem (LocalStack)
        final isBackendOnline = await CloudService.instance.checkBackendHealth();
        if (isBackendOnline) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('☁️ Uploading to cloud...'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Sincronizar tarefa (upload de TODAS as fotos + salvar no DynamoDB)
          final syncSuccess = await CloudService.instance.syncTask(
            newTask,
            imagePaths: _photoPaths, // Envia todas as fotos
          );

          if (mounted) {
            if (syncSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Task saved locally and in cloud!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Task saved locally (cloud sync failed)'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Task saved locally (offline mode)'),
                backgroundColor: Colors.pink,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Update existing task
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          completed: _completed,
          categoryId: _categoryId,
          photoPath: _photoPath,
          photoPaths: _photoPaths,
        );
        
        await DatabaseService.instance.update(updatedTask);

        // Tentar sincronizar atualização com a nuvem
        final isBackendOnline = await CloudService.instance.checkBackendHealth();
        if (isBackendOnline) {
          await CloudService.instance.saveTask(updatedTask);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Task updated successfully'),
              backgroundColor: Colors.pink,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Retorna true = sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Ex: Study Flutter',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must have at least 3 characters';
                        }
                        return null;
                      },
                      maxLength: 100,
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add more details...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 5,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: Categories.all.map((category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Row(
                            children: [
                              Icon(
                                Categories.getIconData(category.icon),
                                color: category.color,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _categoryId = value);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Priority Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'low',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.pink[200]),
                              SizedBox(width: 8),
                              Text('Low'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.pink),
                              SizedBox(width: 8),
                              Text('Medium'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.pink[700]),
                              SizedBox(width: 8),
                              Text('High'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.pink[900]),
                              SizedBox(width: 8),
                              Text('Urgent'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _priority = value);
                        }
                      },
                    ),

                    // PHOTOS SECTION
                    Row(
                      children: [
                        const Icon(Icons.photo_library, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Photos${_photoPaths.isNotEmpty ? ' (${_photoPaths.length})' : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_photoPaths.isNotEmpty)
                          TextButton.icon(
                            onPressed: _removeAllPhotos,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove All'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_photoPaths.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photoPaths.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _photoPaths.length) {
                              // Button to add more photos
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: _showPhotoOptions,
                                  child: Container(
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[400]!,
                                        width: 2,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 40,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final photoPath = _photoPaths[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _viewPhoto(photoPath, index),
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(photoPath),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                        onPressed: () => _removePhoto(index),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _showPhotoOptions,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Photos'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),

                    const Divider(height: 32),

                    // Completed Switch
                    Card(
                      child: SwitchListTile(
                        title: const Text('Task Complete'),
                        subtitle: Text(
                          _completed
                              ? 'This task is marked as completed'
                              : 'This task is not yet completed',
                        ),
                        value: _completed,
                        onChanged: (value) {
                          setState(() => _completed = value);
                        },
                        secondary: Icon(
                          _completed
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _completed ? Colors.pink : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton.icon(
                      onPressed: _saveTask,
                      icon: const Icon(Icons.save),
                      label: Text(
                        isEditing ? 'Update Task' : 'Create Task',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Cancel Button
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
