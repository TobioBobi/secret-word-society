import 'package:dicebear_core/dicebear_core.dart' as dicebear;
import 'package:dicebear_styles/cutouts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../game/player_avatar.dart';
import '../game/player_photo.dart';
import 'photo_image.dart';
import 'cutout.dart';
import 'party_theme.dart';

/// One style definition; no network, role, or name enters the renderer.
class PlayerAvatarView extends StatelessWidget {
  const PlayerAvatarView({
    super.key,
    required this.avatar,
    this.size = 48,
    this.photo,
  });

  final PlayerAvatar avatar;
  final PlayerPhoto? photo;
  final double size;
  static final _style = dicebear.Style.parse(cutouts);
  // Expando avoids retaining appearances after their session is discarded.
  static final _svg = Expando<String>();

  static String svgFor(PlayerAvatar avatar) =>
      _svg[avatar] ??= dicebear.Avatar(_style, {'seed': avatar.seed}).svg;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          color: PartyColors.text,
          shape: PaperBorder(),
          shadows: [
            BoxShadow(color: PartyColors.paperShadow, offset: Offset(2, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: photo == null
                ? SvgPicture.string(svgFor(avatar))
                : PhotoImage(bytes: photo!.bytes),
          ),
        ),
      ),
    ),
  );
}
