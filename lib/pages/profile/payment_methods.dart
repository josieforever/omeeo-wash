import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 24,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 26),
                child: Text(
                  'Payment methods',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 26),
                child: Text(
                  'Cards and accounts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Container(
                decoration: const BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 18, 18, 18),
                  child: InkWell(
                    onTap: _showAddCardSheet,
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 58,
                          height: 40,
                          child: Transform.scale(
                            scale: 2.7,
                            child: Image.asset('assets/images/credit_card.png'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Add card',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: primaryText,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 30,
                          color: primaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 20, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Other methods',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 18),
                      PaymentMethodTile(
                        title: 'Telecel Cash',
                        subtitle: 'Pay with mobile money',
                        logo: _buildTelecelCashLogo(),
                        selected: selectedMethod == 'TelecelCash',
                        onTap: () =>
                            setState(() => selectedMethod = 'TelecelCash'),
                      ),
                      const _TileDivider(),
                      PaymentMethodTile(
                        title: 'Airtel Tigo',
                        subtitle: 'Pay with mobile money',
                        logo: _buildAirtelLogo(),
                        selected: selectedMethod == 'Airtel',
                        onTap: () => setState(() => selectedMethod = 'Airtel'),
                      ),
                      const _TileDivider(),
                      PaymentMethodTile(
                        title: 'MTN',
                        subtitle: 'Pay with mobile money',
                        logo: _buildMtnLogo(),
                        selected: selectedMethod == 'MTN',
                        onTap: () => setState(() => selectedMethod = 'MTN'),
                      ),
                      const _TileDivider(),
                      PaymentMethodTile(
                        title: 'Cash',
                        subtitle: null,
                        logo: _buildCashLogo(),
                        selected: selectedMethod == 'Cash',
                        onTap: () => setState(() => selectedMethod = 'Cash'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 20, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unavailable',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      PaymentMethodTile(
                        title: 'Apple Pay',
                        subtitle: 'Apple Pay currently unavailable',
                        logo: _buildApplePayLogo(),
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

  Widget _buildTelecelCashLogo() {
    return SizedBox(
      width: 58,
      height: 40,
      child: Image.asset('assets/images/telecel_logo.png'),
    );
  }

  Widget _buildAirtelLogo() {
    return SizedBox(
      width: 58,
      height: 40,
      child: Image.asset('assets/images/airteltigo_logo.png'),
    );
  }

  Widget _buildMtnLogo() {
    return SizedBox(
      width: 58,
      height: 40,
      child: Image.asset('assets/images/mtn_logo.png'),
    );
  }

  Widget _buildCashLogo() {
    return SizedBox(
      width: 58,
      height: 40,
      child: Image.asset('assets/images/cash.png'),
    );
  }

  Widget _buildApplePayLogo() {
    return SizedBox(
      width: 58,
      height: 40,
      child: Image.asset('assets/images/apple_pay.png'),
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

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: sheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close, size: 30, color: primaryText),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 46),
                        child: Text(
                          'New card',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: formBg,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      color: _cardNumber.isEmpty
                                          ? secondaryText
                                          : primaryText,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.document_scanner_outlined,
                                    size: 26,
                                    color: Color(0xFF4E425B),
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

                      const SizedBox(height: 22),

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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      color: _expiry.isEmpty
                                          ? secondaryText
                                          : primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 26),
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
                          const SizedBox(width: 12),
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
                                            fontSize: 17,
                                            fontWeight: FontWeight.w400,
                                            color: _cvv.isEmpty
                                                ? secondaryText
                                                : primaryText,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.help_outline,
                                        size: 22,
                                        color: Color(0xFF9A8D9F),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 26),
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

              const SizedBox(height: 38),

              _NumberPad(onDigitTap: _onNumberTap, onBackspace: _onBackspace),

              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 62,
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Add card',
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

    Widget key(String value) {
      return InkWell(
        onTap: () => onDigitTap(value),
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          height: 76,
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }

    Widget empty() => const SizedBox(height: 76);

    Widget backspace() {
      return InkWell(
        onTap: onBackspace,
        borderRadius: BorderRadius.circular(40),
        child: const SizedBox(
          height: 76,
          child: Center(
            child: Icon(Icons.backspace_outlined, size: 28, color: textColor),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: key('4')),
            Expanded(child: key('5')),
            Expanded(child: key('6')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: key('7')),
            Expanded(child: key('8')),
            Expanded(child: key('9')),
          ],
        ),
        const SizedBox(height: 8),
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
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 74),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE4E4E4)),
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

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            logo,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: enabled ? primaryText : disabledText,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: enabled ? secondaryText : disabledText,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
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
    if (selected) {
      return Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: Color(0xFFFF5638),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 32),
      );
    }

    return Container(
      width: 54,
      height: 54,
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
