import 'package:flutter/material.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String selectedMethod = 'MTN';

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF3F3F3);
    const cardColor = Color(0xFFF7F7F7);
    const primaryText = Color(0xFF111111);

    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 360;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = isSmallPhone ? 16.0 : 20.0;
            final pageTitleSize = isSmallPhone ? 24.0 : 28.0;
            final sectionTitleSize = isSmallPhone ? 19.0 : 22.0;
            final cardRadius = isSmallPhone ? 24.0 : 30.0;

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: isSmallPhone ? 18 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            GoBack(
                              bgColor: Theme.of(context).colorScheme.tertiary,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 8 : 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Text(
                          'Payment methods',
                          style: TextStyle(
                            fontSize: pageTitleSize,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 28 : 34),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Text(
                          'Cards and accounts',
                          style: TextStyle(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallPhone ? 14 : 18),

                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isSmallPhone ? 18 : 22,
                            isSmallPhone ? 16 : 18,
                            isSmallPhone ? 14 : 18,
                            isSmallPhone ? 16 : 18,
                          ),
                          child: InkWell(
                            onTap: _showAddCardSheet,
                            borderRadius: BorderRadius.circular(18),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: isSmallPhone ? 46 : 58,
                                  height: isSmallPhone ? 34 : 40,
                                  child: Transform.scale(
                                    scale: isSmallPhone ? 2.1 : 2.7,
                                    child: Image.asset(
                                      'assets/images/credit_card.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isSmallPhone ? 12 : 16),
                                Expanded(
                                  child: Text(
                                    'Add card',
                                    style: TextStyle(
                                      fontSize: isSmallPhone ? 16 : 17,
                                      fontWeight: FontWeight.w500,
                                      color: primaryText,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: isSmallPhone ? 26 : 30,
                                  color: primaryText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallPhone ? 12 : 14),

                      _SectionCard(
                        horizontalPadding: horizontalPadding,
                        radius: cardRadius,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isSmallPhone ? 18 : 22,
                            isSmallPhone ? 18 : 20,
                            isSmallPhone ? 14 : 18,
                            isSmallPhone ? 8 : 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Other methods',
                                style: TextStyle(
                                  fontSize: sectionTitleSize,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                ),
                              ),
                              SizedBox(height: isSmallPhone ? 14 : 18),
                              PaymentMethodTile(
                                title: 'Telecel Cash',
                                subtitle: 'Pay with mobile money',
                                logo: _buildTelecelCashLogo(isSmallPhone),
                                selected: selectedMethod == 'TelecelCash',
                                onTap: () => setState(
                                  () => selectedMethod = 'TelecelCash',
                                ),
                              ),
                              _TileDivider(left: isSmallPhone ? 60 : 74),
                              PaymentMethodTile(
                                title: 'Airtel Tigo',
                                subtitle: 'Pay with mobile money',
                                logo: _buildAirtelLogo(isSmallPhone),
                                selected: selectedMethod == 'Airtel',
                                onTap: () =>
                                    setState(() => selectedMethod = 'Airtel'),
                              ),
                              _TileDivider(left: isSmallPhone ? 60 : 74),
                              PaymentMethodTile(
                                title: 'MTN',
                                subtitle: 'Pay with mobile money',
                                logo: _buildMtnLogo(isSmallPhone),
                                selected: selectedMethod == 'MTN',
                                onTap: () =>
                                    setState(() => selectedMethod = 'MTN'),
                              ),
                              _TileDivider(left: isSmallPhone ? 60 : 74),
                              PaymentMethodTile(
                                title: 'Cash',
                                subtitle: null,
                                logo: _buildCashLogo(isSmallPhone),
                                selected: selectedMethod == 'Cash',
                                onTap: () =>
                                    setState(() => selectedMethod = 'Cash'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallPhone ? 12 : 14),

                      _SectionCard(
                        horizontalPadding: horizontalPadding,
                        radius: cardRadius,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isSmallPhone ? 18 : 22,
                            isSmallPhone ? 18 : 20,
                            isSmallPhone ? 14 : 18,
                            isSmallPhone ? 18 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unavailable',
                                style: TextStyle(
                                  fontSize: sectionTitleSize,
                                  fontWeight: FontWeight.w800,
                                  color: primaryText,
                                ),
                              ),
                              SizedBox(height: isSmallPhone ? 14 : 20),
                              PaymentMethodTile(
                                title: 'Apple Pay',
                                subtitle: 'Apple Pay currently unavailable',
                                logo: _buildApplePayLogo(isSmallPhone),
                                selected: false,
                                enabled: false,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddCardSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.22),
      isDismissible: true,
      enableDrag: true,
      builder: (_) => const _AddCardBottomSheet(),
    );
  }

  Widget _buildTelecelCashLogo(bool isSmallPhone) {
    return SizedBox(
      width: isSmallPhone ? 44 : 58,
      height: isSmallPhone ? 32 : 40,
      child: Image.asset('assets/images/telecel_logo.png', fit: BoxFit.contain),
    );
  }

  Widget _buildAirtelLogo(bool isSmallPhone) {
    return SizedBox(
      width: isSmallPhone ? 44 : 58,
      height: isSmallPhone ? 32 : 40,
      child: Image.asset(
        'assets/images/airteltigo_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildMtnLogo(bool isSmallPhone) {
    return SizedBox(
      width: isSmallPhone ? 44 : 58,
      height: isSmallPhone ? 32 : 40,
      child: Image.asset('assets/images/mtn_logo.png', fit: BoxFit.contain),
    );
  }

  Widget _buildCashLogo(bool isSmallPhone) {
    return SizedBox(
      width: isSmallPhone ? 44 : 58,
      height: isSmallPhone ? 32 : 40,
      child: Image.asset('assets/images/cash.png', fit: BoxFit.contain),
    );
  }

  Widget _buildApplePayLogo(bool isSmallPhone) {
    return SizedBox(
      width: isSmallPhone ? 44 : 58,
      height: isSmallPhone ? 32 : 40,
      child: Image.asset('assets/images/apple_pay.png', fit: BoxFit.contain),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final double horizontalPadding;
  final double radius;
  final Widget child;

  const _SectionCard({
    required this.horizontalPadding,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class _AddCardBottomSheet extends StatefulWidget {
  const _AddCardBottomSheet();

  @override
  State<_AddCardBottomSheet> createState() => _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends State<_AddCardBottomSheet> {
  _CardField _activeField = _CardField.cardNumber;

  String _cardNumber = '';
  String _expiry = '';
  String _cvv = '';

  bool get _canSubmit =>
      _cardNumber.replaceAll(' ', '').length >= 12 &&
      _expiry.length == 5 &&
      _cvv.length >= 3;

  void _setActiveField(_CardField field) {
    setState(() => _activeField = field);
  }

  void _onNumberTap(String digit) {
    setState(() {
      switch (_activeField) {
        case _CardField.cardNumber:
          if (_cardNumber.replaceAll(' ', '').length >= 16) return;
          final raw = _cardNumber.replaceAll(' ', '') + digit;
          _cardNumber = _formatCardNumber(raw);
          break;

        case _CardField.expiry:
          final raw = _expiry.replaceAll('/', '');
          if (raw.length >= 4) return;
          final next = raw + digit;
          _expiry = _formatExpiry(next);
          break;

        case _CardField.cvv:
          if (_cvv.length >= 4) return;
          _cvv += digit;
          break;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      switch (_activeField) {
        case _CardField.cardNumber:
          final raw = _cardNumber.replaceAll(' ', '');
          if (raw.isEmpty) return;
          _cardNumber = _formatCardNumber(raw.substring(0, raw.length - 1));
          break;

        case _CardField.expiry:
          final raw = _expiry.replaceAll('/', '');
          if (raw.isEmpty) return;
          _expiry = _formatExpiry(raw.substring(0, raw.length - 1));
          break;

        case _CardField.cvv:
          if (_cvv.isEmpty) return;
          _cvv = _cvv.substring(0, _cvv.length - 1);
          break;
      }
    });
  }

  String _formatCardNumber(String input) {
    final chars = input.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(chars[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String input) {
    if (input.isEmpty) return '';
    if (input.length <= 2) return input;
    return '${input.substring(0, 2)}/${input.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    const sheetColor = Color(0xFFF7F7F7);
    const primaryText = Color(0xFF111111);
    const secondaryText = Color(0xFF8E8E93);
    const formBg = Color(0xFFFBFBFB);
    const buttonEnabled = Color(0xFFFF8F81);
    const buttonDisabled = Color(0xFFF2B1A8);

    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 360;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isSmallPhone ? 22 : 26),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isSmallPhone ? 14 : 18,
            isSmallPhone ? 12 : 14,
            isSmallPhone ? 14 : 18,
            isSmallPhone ? 16 : 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          size: isSmallPhone ? 26 : 30,
                          color: primaryText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 46),
                          child: Text(
                            'New card',
                            style: TextStyle(
                              fontSize: isSmallPhone ? 16 : 17,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallPhone ? 14 : 18),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: formBg,
                    borderRadius: BorderRadius.circular(isSmallPhone ? 22 : 26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallPhone ? 14 : 18,
                      isSmallPhone ? 16 : 20,
                      isSmallPhone ? 14 : 18,
                      isSmallPhone ? 14 : 18,
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _setActiveField(_CardField.cardNumber),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _cardNumber.isEmpty
                                          ? 'Card number'
                                          : _cardNumber,
                                      style: TextStyle(
                                        fontSize: isSmallPhone ? 16 : 17,
                                        fontWeight: FontWeight.w400,
                                        color: _cardNumber.isEmpty
                                            ? secondaryText
                                            : primaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: isSmallPhone ? 28 : 34,
                                    height: isSmallPhone ? 28 : 34,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.document_scanner_outlined,
                                      size: isSmallPhone ? 22 : 26,
                                      color: const Color(0xFF4E425B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: _activeField == _CardField.cardNumber
                                    ? 2
                                    : 1.3,
                                color: const Color(0xFF4D3F56),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallPhone ? 18 : 22),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _setActiveField(_CardField.expiry),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _expiry.isEmpty
                                          ? 'Expiration date'
                                          : _expiry,
                                      style: TextStyle(
                                        fontSize: isSmallPhone ? 15 : 17,
                                        fontWeight: FontWeight.w400,
                                        color: _expiry.isEmpty
                                            ? secondaryText
                                            : primaryText,
                                      ),
                                    ),
                                    SizedBox(height: isSmallPhone ? 20 : 26),
                                    Container(
                                      height: _activeField == _CardField.expiry
                                          ? 2
                                          : 1,
                                      color: const Color(0xFFDADADA),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallPhone ? 10 : 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _setActiveField(_CardField.cvv),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _cvv.isEmpty
                                                ? 'CVV'
                                                : '*' * _cvv.length,
                                            style: TextStyle(
                                              fontSize: isSmallPhone ? 15 : 17,
                                              fontWeight: FontWeight.w400,
                                              color: _cvv.isEmpty
                                                  ? secondaryText
                                                  : primaryText,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.help_outline,
                                          size: isSmallPhone ? 19 : 22,
                                          color: const Color(0xFF9A8D9F),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isSmallPhone ? 20 : 26),
                                    Container(
                                      height: _activeField == _CardField.cvv
                                          ? 2
                                          : 1,
                                      color: const Color(0xFFDADADA),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallPhone ? 26 : 38),
                _NumberPad(onDigitTap: _onNumberTap, onBackspace: _onBackspace),
                SizedBox(height: isSmallPhone ? 18 : 26),
                SizedBox(
                  width: double.infinity,
                  height: isSmallPhone ? 56 : 62,
                  child: ElevatedButton(
                    onPressed: _canSubmit
                        ? () {
                            Navigator.pop(context, {
                              'cardNumber': _cardNumber,
                              'expiry': _expiry,
                              'cvv': _cvv,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: buttonDisabled,
                      backgroundColor: buttonEnabled,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isSmallPhone ? 18 : 20,
                        ),
                      ),
                    ),
                    child: Text(
                      'Add card',
                      style: TextStyle(
                        fontSize: isSmallPhone ? 17 : 18,
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
    );
  }
}

enum _CardField { cardNumber, expiry, cvv }

class _NumberPad extends StatelessWidget {
  final ValueChanged<String> onDigitTap;
  final VoidCallback onBackspace;

  const _NumberPad({required this.onDigitTap, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF3D334A);
    final isSmallPhone = MediaQuery.of(context).size.width < 360;
    final keyHeight = isSmallPhone ? 64.0 : 76.0;
    final fontSize = isSmallPhone ? 24.0 : 28.0;
    final iconSize = isSmallPhone ? 24.0 : 28.0;
    final spacing = isSmallPhone ? 6.0 : 8.0;

    Widget key(String value) {
      return InkWell(
        onTap: () => onDigitTap(value),
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          height: keyHeight,
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }

    Widget empty() => SizedBox(height: keyHeight);

    Widget backspace() {
      return InkWell(
        onTap: onBackspace,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          height: keyHeight,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: iconSize,
              color: textColor,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: key('1')),
            Expanded(child: key('2')),
            Expanded(child: key('3')),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: key('4')),
            Expanded(child: key('5')),
            Expanded(child: key('6')),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: key('7')),
            Expanded(child: key('8')),
            Expanded(child: key('9')),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: empty()),
            Expanded(child: key('0')),
            Expanded(child: backspace()),
          ],
        ),
      ],
    );
  }
}

class _TileDivider extends StatelessWidget {
  final double left;

  const _TileDivider({this.left = 74});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: left),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E4)),
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget logo;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.title,
    required this.logo,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const primaryText = Color(0xFF111111);
    const secondaryText = Color(0xFF8E8E93);
    const disabledText = Color(0xFF9E9E9E);

    final isSmallPhone = MediaQuery.of(context).size.width < 360;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 10 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            logo,
            SizedBox(width: isSmallPhone ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isSmallPhone ? 16 : 17,
                      fontWeight: FontWeight.w500,
                      color: enabled ? primaryText : disabledText,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmallPhone ? 13 : 15,
                        fontWeight: FontWeight.w400,
                        color: enabled ? secondaryText : disabledText,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: isSmallPhone ? 8 : 12),
            SelectionIndicator(selected: selected, enabled: enabled),
          ],
        ),
      ),
    );
  }
}

class SelectionIndicator extends StatelessWidget {
  final bool selected;
  final bool enabled;

  const SelectionIndicator({
    super.key,
    required this.selected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallPhone = MediaQuery.of(context).size.width < 360;
    final size = isSmallPhone ? 42.0 : 54.0;
    final iconSize = isSmallPhone ? 24.0 : 32.0;

    if (selected) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFFF5638),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: Colors.white, size: iconSize),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF0F0F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
