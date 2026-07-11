import 'package:flutter/material.dart';

/// En dessous de cette largeur, l'app bascule en navigation mobile
/// (menu tiroir) et les panneaux cote-a-cote passent en pile verticale.
const double kMobileBreakpoint = 700;

bool isMobileWidth(BuildContext context) =>
    MediaQuery.of(context).size.width < kMobileBreakpoint;

/// Affiche [children] cote a cote (largeur egale) sur ecran large, ou
/// empiles en pleine largeur sur mobile. Evite qu'un panneau pense pour
/// le desktop se retrouve ecrase dans un ecran etroit (texte coupe
/// lettre par lettre, cartes qui se chevauchent).
class ResponsivePanels extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment desktopCrossAxisAlignment;

  const ResponsivePanels({
    super.key,
    required this.children,
    this.spacing = 12,
    this.desktopCrossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobileWidth(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: desktopCrossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}
