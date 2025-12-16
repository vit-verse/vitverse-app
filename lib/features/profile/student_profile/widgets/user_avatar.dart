import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import '../../../../core/services/avatar_cache_service.dart';
import '../../../../core/utils/avatar_utils.dart';

/// Displays cached avatar, random avatar, or generates one if none exists
class UserAvatar extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const UserAvatar({
    super.key,
    this.size = 60,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _avatarId;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    String? id = await AvatarCacheService.getAvatar();

    if (id == null || id.isEmpty) {
      id = AvatarUtils.generateRandomIds(1).first;
    }

    if (mounted) {
      setState(() => _avatarId = id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_avatarId == null || _avatarId!.isEmpty) {
      return CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: widget.backgroundColor,
        child: Icon(
          Icons.person,
          size: widget.size * 0.6,
          color: widget.iconColor,
        ),
      );
    }

    return ClipOval(
      child: RandomAvatar(_avatarId!, width: widget.size, height: widget.size),
    );
  }
}
