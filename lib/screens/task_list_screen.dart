import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../screens/task_form_screen.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  
  const TaskListScreen({super.key, required this.onToggleTheme});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  String _filter = 'all'; // all, completed, pending
  String? _categoryFilter; // null = todas categorias
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _setupShakeDetection(); // INICIAR SHAKE
  }

  @override
  void dispose() {
    SensorService.instance.stop(); // PARAR SHAKE
    super.dispose();
  }

  // SHAKE DETECTION
  void _setupShakeDetection() {
    SensorService.instance.startShakeDetection(() {
      _showShakeDialog();
    });
  }

  void _showShakeDialog() {
    final pendingTasks = _tasks.where((t) => !t.completed).toList();

    if (pendingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 No pending tasks!'),
          backgroundColor: Colors.pink,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.vibration, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Shake detected!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a task to complete:'),
            const SizedBox(height: 16),
            ...pendingTasks
                .take(3)
                .map(
                  (task) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.pink),
                      onPressed: () => _completeTaskByShake(task),
                    ),
                  ),
                ),
            if (pendingTasks.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${pendingTasks.length - 3} outras',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeTaskByShake(Task task) async {
    try {
      final updated = task.copyWith(
        completed: true,
        completedAt: DateTime.now(),
        completedBy: 'shake',
      );

      await DatabaseService.instance.update(updated);
      Navigator.pop(context);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${task.title}" completed via shake!'),
            backgroundColor: Colors.pink,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await DatabaseService.instance.readAll(
      categoryId: _categoryFilter,
    );
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'completed':
        return _tasks.where((t) => t.completed).toList();
      case 'pending':
        return _tasks.where((t) => !t.completed).toList();
      case 'nearby':
        return _tasks;
      default:
        return _tasks;
    }
  }

  Map<String, int> get _statistics {
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.completed).length;
    final pending = total - completed;
    final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'completionRate': completionRate,
    };
  }

  Future<void> _filterByNearby() async {
    final position = await LocationService.instance.getCurrentLocation();

    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Não foi possível obter localização'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final nearbyTasks = await DatabaseService.instance.getTasksNearLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInMeters: 1000,
    );

    setState(() {
      _tasks = nearbyTasks;
      _filter = 'nearby';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 ${nearbyTasks.length} tarefa(s) próxima(s)'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: Text('Do you really want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.delete(task.id);
      await _loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openTaskForm([Task? task]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)),
    );

    if (result == true) {
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Status Filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.pending),
                    SizedBox(width: 8),
                    Text('Pending'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Completed'),
                  ],
                ),
              ),
            ],
          ),

          // Category Filter
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.category,
              color: _categoryFilter != null ? Colors.amber : Colors.white,
            ),
            tooltip: 'Filter by category',
            onSelected: (value) async {
              setState(() => _categoryFilter = value);
              await _loadTasks();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('All Categories'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: null,
                enabled: false,
                child: Divider(),
              ),
              ...Categories.all.map((category) {
                return PopupMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(
                        Categories.getIconData(category.icon),
                        color: category.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }),
            ],
          ),
          // Botão de alternar tema (Light/Dark Mode)
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Light Mode'
                : 'Dark Mode',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),

      body: Column(
        children: [
          // Card de Estatísticas
          if (_tasks.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.pink,
                    Color(0xFFEC407A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.list,
                    'Total',
                    stats['total'].toString(),
                  ),
                  _buildStatItem(
                    Icons.pending_actions,
                    'Pending',
                    stats['pending'].toString(),
                  ),
                  _buildStatItem(
                    Icons.check_circle,
                    'Completed',
                    stats['completed'].toString(),
                  ),
                  if (stats['overdue']! > 0)
                    _buildStatItem(
                      Icons.warning,
                      'Overdue',
                      stats['overdue'].toString(),
                      isWarning: true,
                    ),
                ],
              ),
            ),

          // Lista de Tarefas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => _openTaskForm(task),
                          onToggle: () => _toggleTask(task),
                          onDelete: () => _deleteTask(task),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWarning)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          )
        else
          Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isWarning ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isWarning ? 10 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_filter) {
      case 'completed':
        message = 'No completed tasks yet';
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        message = 'No pending tasks';
        icon = Icons.pending_actions;
        break;
      default:
        message = 'No tasks created';
        icon = Icons.task_alt;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _openTaskForm(),
            icon: const Icon(Icons.add),
            label: const Text('Criar primeira tarefa'),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats() {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((t) => t.completed).length,
      'pending': _tasks.where((t) => !t.completed).length,
      'overdue': _tasks.where((t) => t.isOverdue).length,
    };
  }
}
