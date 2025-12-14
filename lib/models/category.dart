import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon': icon, 'color': color.value};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: Color(map['color']),
    );
  }
}

// Predefined categories
class Categories {
  static const work = Category(
    id: 'work',
    name: 'Work',
    icon: 'work',
    color: Color(0xFF2196F3), // Blue
  );

  static const personal = Category(
    id: 'personal',
    name: 'Personal',
    icon: 'person',
    color: Color(0xFF4CAF50), // Green
  );

  static const study = Category(
    id: 'study',
    name: 'Study',
    icon: 'school',
    color: Color(0xFF9C27B0), // Purple
  );

  static const health = Category(
    id: 'health',
    name: 'Health',
    icon: 'favorite',
    color: Color(0xFFE91E63), // Pink
  );

  static const shopping = Category(
    id: 'shopping',
    name: 'Shopping',
    icon: 'shopping_cart',
    color: Color(0xFFFF9800), // Orange
  );

  static const finance = Category(
    id: 'finance',
    name: 'Finance',
    icon: 'attach_money',
    color: Color(0xFF4CAF50), // Dark green
  );

  static const home = Category(
    id: 'home',
    name: 'Home',
    icon: 'home',
    color: Color(0xFF795548), // Brown
  );

  static const other = Category(
    id: 'other',
    name: 'Other',
    icon: 'more_horiz',
    color: Color(0xFF607D8B), // Blue gray
  );

  static const List<Category> all = [
    work,
    personal,
    study,
    health,
    shopping,
    finance,
    home,
    other,
  ];

  static Category getById(String id) {
    return all.firstWhere((cat) => cat.id == id, orElse: () => other);
  }

  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'person':
        return Icons.person;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'attach_money':
        return Icons.attach_money;
      case 'home':
        return Icons.home;
      case 'more_horiz':
      default:
        return Icons.more_horiz;
    }
  }
}
