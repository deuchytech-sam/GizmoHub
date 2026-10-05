import 'dart:async';

import 'package:GizmoHub/common/widgets/appbar/basic_appbar.dart';
import 'package:GizmoHub/common/widgets/deal_of_the_day/deal_of_the_day.dart';
import 'package:GizmoHub/core/configs/assets/app_images.dart';
import 'package:GizmoHub/core/configs/assets/app_vectors.dart';
import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/di/service_locator.dart';
import 'package:GizmoHub/data/models/promo/promo_model.dart';
import 'package:GizmoHub/presentation/category/category.dart';
import 'package:GizmoHub/presentation/home/bloc/promo_cubit.dart';
import 'package:GizmoHub/presentation/home/bloc/promo_state.dart';
import 'package:GizmoHub/presentation/home/widgets/option_sheet.dart';
import 'package:GizmoHub/presentation/product/bloc/product_cubit.dart';
import 'package:GizmoHub/presentation/product/pages/product_card.dart';
import 'package:GizmoHub/presentation/product/pages/product_details.dart';
import 'package:GizmoHub/presentation/profile/profile_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _productListHeight = 290;

  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final PageController _pageController = PageController();
  final ScrollController _productScrollController = ScrollController();

  bool _speechInitialized = false;
  bool _isListening = false;

  Timer? _promoTimer;
  int _currentPromo = 0;

  void _startPromoTimer(BuildContext providerContext) {
    if (_promoTimer != null) return;
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final promos = providerContext.read<PromoCubit>().state.promo;
      if (promos.length <= 1) return;

      _currentPromo = (_currentPromo + 1) % promos.length;

      _pageController.animateToPage(
        _currentPromo,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    _pageController.dispose();
    _promoTimer?.cancel();
    _productScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return BlocProvider(
      create: (_) => sl<PromoCubit>()..loadPromo(),
      child: Builder(
        builder: (context) {
          _startPromoTimer(context);

          return Scaffold(
            appBar: BasicAppBar(
              leading: IconButton(
                onPressed: () => showOptionsSheet(context),
                icon: SvgPicture.asset(
                  AppVectors.option,
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(onSurface, BlendMode.srcIn),
                ),
              ),
              title: SvgPicture.asset(AppVectors.logoText, height: 130),
              action: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
                icon: const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage(AppImages.profileImg),
                ),
              ),
            ),
            body: _homeContent(),
          );
        },
      ),
    );
  }

  Widget _homeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [
            _searchBar(context),
            const SizedBox(height: 20),
            _featuredHeader(),
            const SizedBox(height: 20),
            const Categories(),
            const SizedBox(height: 20),
            _promoSection(),
            const SizedBox(height: 20),
            const DealOfTheDayCard(),
            const SizedBox(height: 20),
            _productSection(),
            const SizedBox(height: 24),
            _specialOffers(),
            const SizedBox(height: 20),
            _adSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _specialOffers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Image.asset(AppImages.offer, width: 75, height: 75),
          Column(
            children: [
              const Text(
                'Special Offers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'We make sure you get the offer \n you need at best prices',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adSection() {
    return Container(
      padding: EdgeInsetsGeometry.all(10),
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(AppImages.adSection, width: 150, height: 150),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Asus Rog Gaming',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'ASUS ROG Strix G17 2023 \n 17.3” QHD 240Hz \n Gaming Laptop, \n Ryzen 9-7845HX, \n RTX 4060, \n 16GB RAM, 1TB SSD',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text(
                  'Check Deal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featuredHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'All Featured',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        _menuButton(
          label: 'Sort',
          icon: Icons.swap_vert_rounded,
          items: const [
            PopupMenuItem(value: 'featured', child: Text('Featured')),
            PopupMenuItem(
              value: 'low-to-high',
              child: Text('Price: low to high'),
            ),
            PopupMenuItem(
              value: 'high-to-low',
              child: Text('Price: high to low'),
            ),
          ],
        ),
        const SizedBox(width: 14),
        _menuButton(
          label: 'Filter',
          icon: Icons.filter_alt_outlined,
          items: [
            PopupMenuItem(value: 'all', child: Text('All products')),
            PopupMenuItem(value: 'in-stock', child: Text('In stock')),
            PopupMenuItem(value: 'new', child: Text('New arrivals')),
            ...context.read<ProductCubit>().categories.map(
              (category) =>
                  PopupMenuItem(value: category, child: Text(category)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _productSection() {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox(
            height: _productListHeight,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state.errorMessage != null) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.read<ProductCubit>().getProducts();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final products = context.read<ProductCubit>().visibleProducts;
        if (products.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(child: Text('No matching products')),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: _productListHeight,
              child: ListView.separated(
                controller: _productScrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: products.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(width: 10);
                },
                itemBuilder: (context, index) {
                  final product = products[index];

                  return ProductCard(
                    product: product,
                    onTap: () {
                      openProduct(context, product.id);
                    },
                  );
                },
              ),
            ),

            Positioned(
              right: -5,
              top: (_productListHeight / 2) - 22,
              child: GestureDetector(
                onTap: () {
                  if (!_productScrollController.hasClients) {
                    return;
                  }

                  _productScrollController.animateTo(
                    _productScrollController.offset + 220,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _searchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 1),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: context.read<ProductCubit>().setQuery,
        decoration: InputDecoration(
          hintText: 'Search any Product...',
          hintStyle: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 28,
          ),
          suffixIcon: IconButton(
            tooltip: _isListening ? 'Stop voice search' : 'Search by voice',
            onPressed: _toggleVoiceSearch,
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 28,
            ),
          ),
          fillColor: Colors.transparent,
          filled: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _menuButton({
    required String label,
    required IconData icon,
    required List<PopupMenuEntry<String>> items,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 46),
      onSelected: (selection) => _handleMenuSelection(selection),
      itemBuilder: (_) => items,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Icon(icon, size: 23),
          ],
        ),
      ),
    );
  }

  Widget _promoSection() {
    return BlocBuilder<PromoCubit, PromoState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (state.promo.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: state.promo.length,
                onPageChanged: (index) {
                  setState(() => _currentPromo = index);
                },
                itemBuilder: (context, index) {
                  return _banner(state.promo[index]);
                },
              ),
            ),
            if (state.promo.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(state.promo.length, (index) {
                  final isActive = index == _currentPromo;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 7,
                    width: isActive ? 18 : 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _banner(PromoModel promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF343434)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -15,
            child: Image.network(
              promo.imageUrl,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔥 LIMITED OFFER 🔥',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                promo.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                promo.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 55,
                width: 130,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    promo.buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      return;
    }

    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _isListening = false);
            _showMessage('Voice search is unavailable. Please try again.');
          }
        },
      );
    }

    if (!_speechInitialized) {
      _showMessage('Voice search is not available on this device.');
      return;
    }

    await _speech.listen(
      onResult: (result) {
        _searchController.value = TextEditingValue(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(
            offset: result.recognizedWords.length,
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isListening = true);
    }
  }

  void _handleMenuSelection(String selection) {
    final cubit = context.read<ProductCubit>();
    const sorts = {
      'featured',
      'low-to-high',
      'high-to-low',
      'top-rated',
      'discount',
    };
    if (sorts.contains(selection)) {
      cubit.setSort(selection);
    } else if (selection == 'all' ||
        selection == 'in-stock' ||
        selection == 'new') {
      cubit
        ..setAvailability(selection)
        ..setCategory(null);
    } else {
      cubit
        ..setAvailability('all')
        ..setCategory(selection);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
