import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class EcosystemScaffold extends StatelessWidget {
  const EcosystemScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: colors.tokens.bg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!, style: theme.textTheme.displaySmall),
              actions: actions,
            ),
      body: SafeArea(
        top: title == null,
        child: Padding(
          padding: const EdgeInsets.all(EcosystemSpacing.x4),
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
