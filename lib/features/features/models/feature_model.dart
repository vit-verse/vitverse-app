import 'package:flutter/material.dart';

/// Represents a feature in the VIT Connect app
class Feature {
  final String id;
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final String route;
  final FeatureSource source;
  final FeatureCategory category;

  const Feature({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    required this.source,
    required this.category,
  });

  Feature copyWith({
    String? id,
    String? key,
    String? title,
    String? description,
    IconData? icon,
    String? route,
    FeatureSource? source,
    FeatureCategory? category,
  }) {
    return Feature(
      id: id ?? this.id,
      key: key ?? this.key,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      route: route ?? this.route,
      source: source ?? this.source,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'title': title,
      'description': description,
      'route': route,
      'source': source.name,
      'category': category.name,
    };
  }

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'] as String,
      key: json['key'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: Icons.star, // Default icon, should be mapped properly
      route: json['route'] as String,
      source: FeatureSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => FeatureSource.vtop,
      ),
      category: FeatureCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FeatureCategory.academic,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Feature && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Feature source (VTOP or VIT Connect in-app)
enum FeatureSource { vtop, vitconnect }

/// Feature category for organizing features
enum FeatureCategory {
  academic,
  faculty,
  finance,
  club,
  academics,
  social,
  utilities,
  other,
}
