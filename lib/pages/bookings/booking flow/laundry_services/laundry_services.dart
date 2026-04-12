import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services_date_time.dart'
    show LaundryServicestDateScreen;
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/location_picker.dart';
import 'package:omeeowash/pages/profile/profile_screen.dart';
import 'service_review.dart' show PickedLocationResult;

class LaundryServicesScreen extends StatefulWidget {
  final String? serviceType;

  const LaundryServicesScreen({super.key, this.serviceType});

  @override
  State<LaundryServicesScreen> createState() => _LaundryServicesScreenState();
}

class _LaundryServicesScreenState extends State<LaundryServicesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String serviceType = 'none';
  int? duration;
  String? expandedService;
  Set<String> selectedAddOns = {};

  static const String washFold = ' Wash & Fold  ';
  static const String ironingPressing = ' Wash & Iron  ';

  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';

  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  bool _isSearchingLocations = false;
  String? _selectedPickupAddress;

  List<PlaceSuggestion> _predictions = [];

  @override
  void initState() {
    super.initState();

    final initialType = widget.serviceType;
    if (initialType != null && initialType.trim().isNotEmpty) {
      serviceType = initialType;
      duration = _durationForService(initialType);
      expandedService = initialType;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      serviceType != 'none' &&
      duration != null &&
      (_selectedPickupAddress?.trim().isNotEmpty ?? false);

  int? _durationForService(String type) {
    switch (type) {
      case washFold:
        return 30;
      case ironingPressing:
        return 120;
      default:
        return null;
    }
  }

  Future<void> _onSelect(String type) async {
    setState(() {
      serviceType = type;
      duration = _durationForService(type);
      expandedService = type;
    });

    await _showLocationSheet();
  }

  void _goNext() {
    final selectedDuration = duration;

    if (!_canContinue || selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a service and choose a pickup location.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LaundryServicestDateScreen(
          serviceType: serviceType,
          duration: selectedDuration,
          addOns: selectedAddOns,
        ),
      ),
    );
  }

  Future<void> _showLocationSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.18),
      builder: (sheetContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _locationFocusNode.requestFocus();
          }
        });

        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.91,
            minChildSize: 0.91,
            maxChildSize: 0.91,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(sheetContext).pop(),
                            child: Lottie.asset(
                              'assets/animations/breathing_pill.json',
                              width: 50,
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 50, 12, 24),
                      sliver: SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            key: const ValueKey('searchOnly'),
                            child: _buildSearchSection(sheetContext),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _searchPlaces(String input) async {
    final query = input.trim();

    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearchingLocations = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocations = true;
    });

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&key=$_googleApiKey'
        '&components=country:gh',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Places request failed');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = (data['predictions'] as List<dynamic>? ?? [])
          .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _predictions = predictions;
        _isSearchingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _predictions = [];
        _isSearchingLocations = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch locations. Check your API key.'),
        ),
      );
    }
  }

  void _selectPrediction(PlaceSuggestion place, {BuildContext? modalContext}) {
    setState(() {
      _selectedPickupAddress = place.description;
      _locationController.text = place.description;
      _predictions = [];
    });

    _locationFocusNode.unfocus();

    if (modalContext != null && Navigator.of(modalContext).canPop()) {
      Navigator.of(modalContext).pop();
    }
  }

  Future<void> _openMapPicker({BuildContext? modalContext}) async {
    if (modalContext != null && Navigator.of(modalContext).canPop()) {
      Navigator.of(modalContext).pop();
    }

    final result = await Navigator.of(context).push<PickedLocationResult>(
      MaterialPageRoute(builder: (_) => const GoogleMapLocationPickerScreen()),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _selectedPickupAddress = result.addressLine;
        _locationController.text = result.addressLine;
        _predictions = [];
      });
    }
  }

  Widget _buildSearchSection(BuildContext modalContext) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.65,
          color: Colors.amber,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(40, 0, 0, 0),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _locationController,
                        focusNode: _locationFocusNode,
                        onChanged: _searchPlaces,
                        decoration: InputDecoration(
                          hintText: 'Pickup location',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: Transform.scale(
                            scale: 0.60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(1),
                              child: const Icon(
                                Icons.moped,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          suffixIcon: _isSearchingLocations
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : (_locationController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          _locationController.clear();
                                          setState(() {
                                            _selectedPickupAddress = null;
                                            _predictions = [];
                                          });
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                      )
                                    : null),
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFF4F8),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => _openMapPicker(modalContext: modalContext),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(40, 0, 0, 0),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(
                            child: Icon(Icons.map, color: Color(0xFFE67E22)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_predictions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF1C9D8)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _predictions[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFE36C9A),
                        ),
                        title: Text(
                          place.mainText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          place.secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectPrediction(
                          place,
                          modalContext: modalContext,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldExit = false;

  Future<void> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exit App',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to close the app?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "No",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Yes",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    setState(() {
      _shouldExit = result ?? false;
    });

    if (_shouldExit) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        key: _scaffoldKey,
        endDrawerEnableOpenDragGesture: false,
        backgroundColor: Colors.white,
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: const Drawer(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: ProfileScreen(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Hello, ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Chris',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 101, 56, 0),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECDB),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.sort,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                SearchEventsBar(
                  controller: _locationController,
                  onTap: _showLocationSheet,
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ServiceTile(
                      title: 'Wash & Fold',
                      imageAsset: 'assets/images/wash_foldd.png',
                      onTap: () => _onSelect(washFold),
                    ),
                    ServiceTile(
                      title: 'Wash & Iron',
                      imageAsset: 'assets/images/wash_ironn.png',
                      onTap: () => _onSelect(ironingPressing),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                PromoImageCarousel(
                  imagePaths: const [
                    'assets/images/promo_banner.png',
                    'assets/images/promo_banner_inverse.png',
                  ],
                  height: 140,
                  onTap: (index) {
                    debugPrint('Tapped banner $index');
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 10),

                LaundryCard(
                  name: 'Sparkle Wash',
                  imageUrl: 'https://example.com/laundry.jpg',
                  distanceKm: 2.4,
                  rating: 4.7,
                  availabilityStatus: 'available',
                  isOpenNow: true,
                  supportedServices: const ['wash_fold', 'wash_iron'],
                  basePricePerKg: 18,
                  washIronExtraPerKg: 2,
                  turnaroundText: 'Same day',
                  onTap: () {},
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};

    return PlaceSuggestion(
      description: (json['description'] ?? '') as String,
      mainText: (formatting['main_text'] ?? '') as String,
      secondaryText: (formatting['secondary_text'] ?? '') as String,
    );
  }
}

class ServiceMiniChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconCircleColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  const ServiceMiniChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.backgroundColor = const Color(0xFF1F1F1F),
    this.iconCircleColor = const Color(0xFFD7EA6A),
    this.iconColor = const Color(0xFF4A4A2A),
    this.titleColor = Colors.white,
    this.subtitleColor = const Color(0xFFB9B9B9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 18, bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: iconCircleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchEventsBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const SearchEventsBar({
    super.key,
    this.hintText = 'Pickup location...',
    this.controller,
    this.onFilterTap,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = controller?.text.trim() ?? '';
    final hasValue = text.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(40, 0, 0, 0),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.moped, size: 25),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? text : hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? Colors.black : Colors.black54,
                ),
              ),
            ),
            const Icon(Icons.search, size: 25, color: Color(0xFFE67E22)),
          ],
        ),
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback? onTap;

  const ServiceTile({
    super.key,
    required this.title,
    required this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 170,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F1F1), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2A2A),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromoImageCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final double height;
  final Duration autoPlayDuration;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final ValueChanged<int>? onTap;

  const PromoImageCarousel({
    super.key,
    required this.imagePaths,
    this.height = 180,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.onTap,
  });

  @override
  State<PromoImageCarousel> createState() => _PromoImageCarouselState();
}

class _PromoImageCarouselState extends State<PromoImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.imagePaths.length <= 1) return;

    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!_pageController.hasClients) return;

      int nextPage = _currentIndex + 1;
      if (nextPage >= widget.imagePaths.length) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(22);

    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(index),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: radius),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Image.asset(
                        widget.imagePaths[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.imagePaths.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color.fromARGB(255, 227, 166, 108)
                    : const Color.fromARGB(255, 216, 207, 197),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LaundryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double distanceKm;
  final double? rating;
  final String availabilityStatus;
  final bool isOpenNow;
  final List<String> supportedServices;
  final int basePricePerKg;
  final int washIronExtraPerKg;
  final String turnaroundText;
  final VoidCallback? onTap;

  const LaundryCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.distanceKm,
    required this.rating,
    required this.availabilityStatus,
    required this.isOpenNow,
    required this.supportedServices,
    required this.basePricePerKg,
    required this.washIronExtraPerKg,
    required this.turnaroundText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusData(availabilityStatus, isOpenNow);

    final darkOrange = const Color(0xFFE67E22);
    final softOrange = const Color(0xFFFFECDB);
    final white = Colors.white;
    final black = Colors.black;
    final borderColor = const Color(0xFFEAEAEA);
    final subtitleColor = Colors.black54;
    final closedColor = Colors.black45;
    final shadowColor = Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.trim().isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: softOrange,
                              child: Icon(
                                Icons.local_laundry_service_outlined,
                                size: 40,
                                color: darkOrange,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: softOrange,
                          child: Icon(
                            Icons.local_laundry_service_outlined,
                            size: 40,
                            color: darkOrange,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.18),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _StatusBadge(
                      label: status.label,
                      textColor: status.textColor,
                      bgColor: status.bgColor,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: supportedServices
                            .map(
                              (service) => _ServiceChip(
                                label: _serviceLabel(service),
                                bgColor: softOrange,
                                textColor: darkOrange,
                              ),
                            )
                            .toList(),
                      ),
                      _MetaItem(
                        title: 'From',
                        value: 'GH₵$basePricePerKg/kg',
                        titleColor: subtitleColor,
                        valueColor: black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isOpenNow ? 'Open now' : 'Currently closed',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isOpenNow ? darkOrange : closedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${distanceKm.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: darkOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating == null || rating == 0
                                      ? 'New'
                                      : rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusData _statusData(String availabilityStatus, bool isOpenNow) {
    if (!isOpenNow) {
      return const _StatusData(
        label: 'Closed',
        textColor: Color(0xFF6D6D6D),
        bgColor: Color(0xFFEEEEEE),
      );
    }

    switch (availabilityStatus.toLowerCase()) {
      case 'available':
        return const _StatusData(
          label: 'Available',
          textColor: Color(0xFFE67E22),
          bgColor: Color(0xFFFFE8D6),
        );
      case 'busy':
        return const _StatusData(
          label: 'Busy',
          textColor: Colors.black,
          bgColor: Color(0xFFFFD6A5),
        );
      default:
        return const _StatusData(
          label: 'Offline',
          textColor: Color(0xFF6D6D6D),
          bgColor: Color(0xFFEEEEEE),
        );
    }
  }

  String _serviceLabel(String key) {
    switch (key) {
      case 'wash_fold':
        return 'Wash & Fold';
      case 'wash_iron':
        return 'Wash & Iron';
      default:
        return key;
    }
  }
}

class _StatusData {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatusData({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _ServiceChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;

  const _MetaItem({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: valueColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
