import 'package:flutter/material.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class GiftsAndDiscountsScreen extends StatelessWidget {
  const GiftsAndDiscountsScreen({super.key});

  static const Color _backgroundColor = Color(0xFFF3F3F3);
  static const Color _primaryTextColor = Color(0xFF111111);
  static const Color _dividerColor = Color(0xFFE2E2E2);
  static const Color _disabledIconBg = Color(0xFFE4E4E4);
  static const Color _disabledIconColor = Color(0xFF9E9E9E);
  static const Color _buttonColor = Color(0xFFFF4B34);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),

                      GoBack(
                        bgColor: Theme.of(context).colorScheme.tertiary,
                        onPressed: () => Navigator.pop(context),
                      ),

                      CustomText(
                        text: 'Gifts and discounts',
                        textSize: 23,
                        textWeight: FontWeight.w800,
                        textColor: _primaryTextColor,
                      ),

                      const SizedBox(height: 26),
                      _ActionTile(
                        icon: Icons.confirmation_num_outlined,
                        title: 'Enter promo code',
                        onTap: () => _showPromoCodeSheet(context),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 78),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: _dividerColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GetDiscountScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _disabledIconBg,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.card_giftcard_outlined,
                                  color: _disabledIconColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Text(
                                'Get discount',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: _primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      bottom: 20,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/percentage_man.png',
                            height: 310,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        children: [
                          SizedBox(height: 300),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GetDiscountScreen(),
                                ),
                              );
                            },

                            child: Container(
                              height: 65,
                              width: 370,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE36C9A),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: const Text(
                                  'Share discount',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showPromoCodeSheet(BuildContext context) async {
    await showGeneralDialog<String>(
      context: context,
      barrierLabel: 'Promo code',
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.28),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const _PromoCodeDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  static const Color _primaryTextColor = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 30, color: _primaryTextColor),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: _primaryTextColor,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 28, color: _primaryTextColor),
          ],
        ),
      ),
    );
  }
}

class _PromoCodeDialog extends StatefulWidget {
  const _PromoCodeDialog();

  @override
  State<_PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends State<_PromoCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const Color _sheetColor = Color(0xFFF7F7F7);
  static const Color _dividerColor = Color(0xFFD7D7D7);
  static const Color _buttonColor = Color(0xFFFF4B34);
  static const Color _textColor = Color(0xFF111111);
  static const Color _hintColor = Color(0xFF9A9A9A);
  static const Color _cursorColor = Color(0xFF4C7CF0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _closeSheet() {
    FocusScope.of(context).unfocus();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeSheet,
              child: const SizedBox.expand(),
            ),
          ),

          Positioned(
            right: 18,
            bottom: keyboardInset + 315,
            child: SafeArea(
              child: IconButton(
                onPressed: _closeSheet,
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: Material(
                  color: _sheetColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 18,
                          left: 26,
                          right: 26,
                          bottom: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 4),
                            const Text(
                              'Promo code',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Divider(
                              thickness: 1,
                              height: 1,
                              color: _dividerColor,
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              cursorColor: _cursorColor,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: _textColor,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Your promo code',
                                hintStyle: TextStyle(
                                  fontSize: 18,
                                  color: _hintColor,
                                  fontWeight: FontWeight.w400,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.only(bottom: 10),
                                border: InputBorder.none,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: () {
                                  final code = _controller.text.trim();
                                  Navigator.of(context).pop(code);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE36C9A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Activate',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GetDiscountScreen extends StatelessWidget {
  const GetDiscountScreen({super.key});

  static const Color _bgColor = Color(0xFFF4F4F4);
  static const Color _primaryText = Color(0xFF111111);
  static const Color _secondaryText = Color(0xFF4B4B4B);
  static const Color _accent = Color(0xFFFF4B34);
  static const Color _cardBorder = Color(0xFFE4E4E4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 30, color: _primaryText),
                ),
              ),

              const SizedBox(height: 100),

              Center(
                child: Image.asset(
                  'assets/images/discount.png',
                  height: 310,
                  fit: BoxFit.contain,
                ),
              ),

              const Spacer(),

              const Text(
                'GET 50% DISCOUNT',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE36C9A),
                ),
              ),

              const SizedBox(height: 22),

              const _StepItem(
                number: '1',
                title: 'Share invite with a friend',
                subtitle:
                    'Your friend will get a 10% discount on their first ride',
              ),

              const SizedBox(height: 18),

              const _StepItem(
                number: '2',
                title: 'Get 50% off',
                subtitle:
                    'When your friend completes their first ride, you’ll get a 50% discount on your next ride',
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: share invite code
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE36C9A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),

                      Text(
                        '1000 promo codes left',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBorder),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'M7Q9ERS2',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryText,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: copy code
                      },
                      child: const Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _StepItem({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  static const Color _primaryText = Color(0xFF111111);
  static const Color _secondaryText = Color(0xFF4B4B4B);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _secondaryText,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
