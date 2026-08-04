import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const kAppBarTitleStyle = TextStyle(
  fontSize: 20, 
  fontWeight: FontWeight.w700,
  color: Color(0xFF1E1B4B),
  letterSpacing: -0.5,
);

BoxDecoration kAppBarButtonDecoration({Color? borderColor}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailingAction;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailingAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64); 

  @override
  Widget build(BuildContext context) {
    // Sur la racine d'un onglet, il n'y a rien à dépiler : un pop retirerait
    // la seule page du navigateur interne (écran blanc). On masque la flèche.
    final showBack = onBack != null || context.canPop();
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 64, 
      
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(title, style: kAppBarTitleStyle),

            if (showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack ?? () { if (context.canPop()) context.pop(); },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: kAppBarButtonDecoration(),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF1E293B),
                      size: 24,
                    ),
                  ),
                ),
              ),

            Align(
              alignment: Alignment.centerRight,
              child: trailingAction ?? const SizedBox(width: 40),
            ),
          ],
        ),
      ),
    );
  }
}