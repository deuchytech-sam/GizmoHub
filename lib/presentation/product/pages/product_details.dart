import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/presentation/cart/pages/checkout_page.dart';
import 'package:GizmoHub/presentation/wishlist/pages/wishlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One entry point for every screen. Pass [data] if you have it so the page
/// shows instantly; it still goes live from Firestore.
void openProduct(BuildContext context, String id, [Map<String, dynamic>? data]) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailsPage(productId: id, initialData: data),
    ),
  );
}

String _naira(num n) =>
    '₦${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

void _toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

List<String> _cats(Map<String, dynamic> d) {
  final c = d['categories'] ?? d['category'];
  if (c is List) return c.map((e) => e.toString()).toList();
  return c == null ? [] : [c.toString()];
}

int _discountNum(Map<String, dynamic> d) =>
    int.tryParse((d['discount'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic>? initialData;

  /// Optional overrides. If you leave them null, the page adds the product
  /// to the cart and opens the checkout screen by itself.
  final void Function(String id, Map<String, dynamic> data, String? size)? onAddToCart;
  final void Function(String id, Map<String, dynamic> data, String? size)? onBuyNow;
  final VoidCallback? onCartTap;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    this.initialData,
    this.onAddToCart,
    this.onBuyNow,
    this.onCartTap,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _doc =
  gizmoDb.collection('product').doc(widget.productId).snapshots();
  final _pageCtrl = PageController();
  final _similarKey = GlobalKey();
  int _index = 0;
  String? _size;
  bool _expanded = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _doc,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));

            Map<String, dynamic>? data;
            if (snap.hasData) {
              data = snap.data!.exists ? snap.data!.data() : null;
            } else {
              data = widget.initialData;
              if (data == null) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
            }

            if (data == null || data['isActive'] == false) {
              return Column(children: [
                _topBar(),
                const Expanded(
                  child: Center(child: Text('This product is no longer available')),
                ),
              ]);
            }
            return _body(data);
          },
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(children: [
      IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context)),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.shopping_cart_outlined),
        onPressed: widget.onCartTap ?? () => openCart(context),
      ),
    ]),
  );

  Widget _body(Map<String, dynamic> data) {
    final scheme = Theme.of(context).colorScheme;
    final name = (data['name'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final discount = (data['discount'] ?? '').toString();
    final price = (data['price'] ?? 0) as num;
    final oldPrice = (data['oldPrice'] ?? 0) as num;
    final rating = (data['rating'] ?? 0) as num;
    final reviews = (data['reviews'] ?? 0) as num;

    // Optional fields, the page works without them.
    final images = (data['images'] is List && (data['images'] as List).isNotEmpty)
        ? (data['images'] as List).map((e) => e.toString()).toList()
        : [(data['imageUrl'] ?? '').toString()];
    final sizes = (data['sizes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final size = _size ?? (sizes.isNotEmpty ? sizes.first : null);
    final delivery = (data['delivery'] ?? '1 hour').toString();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _topBar(),

        // ── Image carousel ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 260,
              child: Stack(fit: StackFit.expand, children: [
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _netImage(images[i], scheme),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: WishlistButton(productId: widget.productId, size: 20),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: InkWell(
                        onTap: () => _pageCtrl.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white70,
                          child: Icon(Icons.chevron_right, color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (int i = 0; i < images.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: i == _index ? 8 : 5,
                  height: i == _index ? 8 : 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? AppColors.primary : Colors.grey.shade400,
                  ),
                ),
            ]),
          ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Sizes (only if the admin added them) ──
            if (sizes.isNotEmpty) ...[
              Text('Size: ${size ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in sizes)
                  InkWell(
                    onTap: () => setState(() => _size = s),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: s == size ? AppColors.primary.withAlpha(30) : null,
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
            ],

            // ── Name, rating, price ──
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(children: [
              for (int i = 1; i <= 5; i++)
                Icon(i <= rating.round() ? Icons.star : Icons.star_border,
                    size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Text(reviews.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (oldPrice > price)
                  Text(_naira(oldPrice),
                      style: const TextStyle(
                          color: Colors.grey, decoration: TextDecoration.lineThrough)),
                Text(_naira(price),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                if (discount.isNotEmpty)
                  Text(discount,
                      style: const TextStyle(
                          color: Colors.deepOrange, fontWeight: FontWeight.w600)),
              ],
            ),

            // ── Description ──
            const SizedBox(height: 16),
            const Text('Product Details',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(description,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.4)),
            if (description.length > 160)
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_expanded ? 'Show less' : 'Read more',
                      style: const TextStyle(color: AppColors.primary)),
                ),
              ),

            // ── Badges ──
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: const [
              _Badge(Icons.storefront_outlined, 'Nearest Store'),
              _Badge(Icons.workspace_premium_outlined, 'VIP'),
              _Badge(Icons.assignment_return_outlined, 'Return policy'),
            ]),

            // ── Cart / Buy ──
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('Go to cart'),
                  onPressed: () => widget.onAddToCart != null
                      ? widget.onAddToCart!(widget.productId, data, size)
                      : addAndOpenCart(context, widget.productId, size),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Buy Now'),
                  onPressed: () => widget.onBuyNow != null
                      ? widget.onBuyNow!(widget.productId, data, size)
                      : addAndOpenCart(context, widget.productId, size),
                ),
              ),
            ]),

            // ── Delivery banner ──
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Delivery in', style: TextStyle(fontSize: 12)),
                Text(delivery,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),

            // ── View Similar / Compare ──
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Similar'),
                  onPressed: () => Scrollable.ensureVisible(
                      _similarKey.currentContext!,
                      duration: const Duration(milliseconds: 300)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.compare_arrows, size: 18),
                  label: const Text('Add to Compare'),
                  onPressed: () => _toast(context, 'Compare is not set up yet'),
                ),
              ),
            ]),

            // ── Similar products ──
            const SizedBox(height: 24),
            _SimilarSection(
              key: _similarKey,
              currentId: widget.productId,
              categories: _cats(data),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _netImage(String url, ColorScheme scheme) {
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined, size: 48)),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (_, child, p) => p == null ? child : placeholder);
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]),
  );
}

// ───────────────────────────── Similar section ─────────────────────────────

enum _SimSort { none, priceLow, priceHigh, rating, discount }

class _SimilarSection extends StatefulWidget {
  final String currentId;
  final List<String> categories;
  const _SimilarSection({super.key, required this.currentId, required this.categories});

  @override
  State<_SimilarSection> createState() => _SimilarSectionState();
}

class _SimilarSectionState extends State<_SimilarSection> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
  gizmoDb.collection('product').where('isActive', isEqualTo: true).snapshots();
  _SimSort _sort = _SimSort.none;
  bool _discountOnly = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        var list = snap.data!.docs.where((d) {
          if (d.id == widget.currentId) return false;
          if (widget.categories.isEmpty) return true;
          return _cats(d.data()).any(widget.categories.contains);
        }).toList();
        if (_discountOnly) list = list.where((d) => _discountNum(d.data()) > 0).toList();

        num p(QueryDocumentSnapshot<Map<String, dynamic>> d) => (d.data()['price'] ?? 0) as num;
        num r(QueryDocumentSnapshot<Map<String, dynamic>> d) => (d.data()['rating'] ?? 0) as num;
        switch (_sort) {
          case _SimSort.priceLow:
            list.sort((a, b) => p(a).compareTo(p(b)));
          case _SimSort.priceHigh:
            list.sort((a, b) => p(b).compareTo(p(a)));
          case _SimSort.rating:
            list.sort((a, b) => r(b).compareTo(r(a)));
          case _SimSort.discount:
            list.sort((a, b) => _discountNum(b.data()).compareTo(_discountNum(a.data())));
          case _SimSort.none:
            break;
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Similar To',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(children: [
            Text('${list.length} Items',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            PopupMenuButton<_SimSort>(
              initialValue: _sort,
              onSelected: (s) => setState(() => _sort = s),
              itemBuilder: (_) => const [
                PopupMenuItem(value: _SimSort.none, child: Text('Default')),
                PopupMenuItem(value: _SimSort.priceLow, child: Text('Price: low to high')),
                PopupMenuItem(value: _SimSort.priceHigh, child: Text('Price: high to low')),
                PopupMenuItem(value: _SimSort.rating, child: Text('Top rated')),
                PopupMenuItem(value: _SimSort.discount, child: Text('Biggest discount')),
              ],
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Row(children: [
                  Text('Sort'),
                  SizedBox(width: 4),
                  Icon(Icons.swap_vert, size: 18),
                ]),
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _discountOnly = !_discountOnly),
              icon: Icon(
                  _discountOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                  size: 18),
              label: Text(_discountOnly ? 'On sale' : 'Filter'),
            ),
          ]),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No similar products yet')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (_, i) => _SimilarCard(id: list[i].id, data: list[i].data()),
            ),
        ]);
      },
    );
  }
}

class _SimilarCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const _SimilarCard({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = (data['imageUrl'] ?? '').toString();
    final price = (data['price'] ?? 0) as num;
    final oldPrice = (data['oldPrice'] ?? 0) as num;
    final rating = (data['rating'] ?? 0) as num;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined, size: 36)),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openProduct(context, id, data),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Stack(fit: StackFit.expand, children: [
              url.isEmpty
                  ? placeholder
                  : Image.network(url,
                  fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder),
              Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: WishlistButton(productId: id, size: 18),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((data['name'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(_naira(price), style: const TextStyle(fontWeight: FontWeight.w700)),
                if (oldPrice > price)
                  Text(_naira(oldPrice),
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                for (int i = 1; i <= 5; i++)
                  Icon(i <= rating.round() ? Icons.star : Icons.star_border,
                      size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${data['reviews'] ?? 0}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}