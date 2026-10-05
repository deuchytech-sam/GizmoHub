// lib/presentation/wishlist/wishlist_page.dart

import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/data/repositories/wishlist/wishlist_repository.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

String _naira(num n) =>
    '₦${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

void _toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

// ───────────────────────────── Data helpers ─────────────────────────────

final _wishlistRepository = WishlistRepository();

// ───────────────────────────── Heart button ─────────────────────────────
// Unchanged: use it in ProductCard / product details.

class WishlistButton extends StatefulWidget {
  final String productId;
  final double size;
  const WishlistButton({super.key, required this.productId, this.size = 24});

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  late final Stream<Set<String>> _stream = _wishlistRepository.watchIds();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: _stream,
      builder: (context, snap) {
        final saved = snap.data?.contains(widget.productId) ?? false;
        return IconButton(
          iconSize: widget.size,
          visualDensity: VisualDensity.compact,
          tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
          icon: Icon(
            saved ? Icons.favorite : Icons.favorite_border,
            color: saved ? Colors.red : null,
          ),
          onPressed: () async {
            if (FirebaseAuth.instance.currentUser == null) {
              _toast(context, 'Log in to use your wishlist');
              return;
            }
            try {
              await _wishlistRepository.setSaved(
                widget.productId,
                saved: !saved,
              );
            } on FirebaseException catch (e) {
              if (context.mounted) {
                _toast(context, e.message ?? 'Could not update wishlist');
              }
            }
          },
        );
      },
    );
  }
}

// ───────────────────────────── Wishlist page ─────────────────────────────

enum _Sort { none, priceLow, priceHigh, rating, discount }

int _discountNum(Map<String, dynamic> d) =>
    int.tryParse(
      (d['discount'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), ''),
    ) ??
    0;

List<String> _cats(Map<String, dynamic> d) {
  final c = d['categories'] ?? d['category'];
  if (c is List) return c.map((e) => e.toString()).toList();
  return c == null ? [] : [c.toString()];
}

class WishlistPage extends StatefulWidget {
  final void Function(String id, Map<String, dynamic> data)? onProductTap;
  const WishlistPage({super.key, this.onProductTap});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late final Stream<Set<String>> _ids = _wishlistRepository.watchIds();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _products = gizmoDb
      .collection('product')
      .where('isActive', isEqualTo: true)
      .snapshots();

  String _query = '';
  String? _category;
  _Sort _sort = _Sort.none;

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist'), centerTitle: true),
      body: loggedIn ? _content() : _loginPrompt(),
    );
  }

  Widget _loginPrompt() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_border, size: 56),
          const SizedBox(height: 12),
          const Text('Log in to see your wishlist'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignInPage()),
            ),
            child: const Text('Log in'),
          ),
        ],
      ),
    ),
  );

  Widget _message(IconData icon, String title, String sub) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(sub, textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));

  Widget _content() {
    return StreamBuilder<Set<String>>(
      stream: _ids,
      builder: (context, idSnap) {
        if (idSnap.hasError) return Center(child: Text('${idSnap.error}'));
        if (!idSnap.hasData) return _loader();
        final ids = idSnap.data!;
        if (ids.isEmpty) {
          return _message(
            Icons.favorite_border,
            'Your wishlist is empty',
            'Tap the heart on any product to save it here.',
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _products,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            if (!snap.hasData) return _loader();

            // Saved AND still available (admin hasn't deactivated/deleted it)
            final saved = snap.data!.docs
                .where((d) => ids.contains(d.id))
                .toList();
            final unavailable = ids.length - saved.length;
            if (saved.isEmpty) {
              return _message(
                Icons.favorite_border,
                'Your wishlist is empty',
                unavailable > 0
                    ? '$unavailable saved item(s) are currently unavailable.'
                    : 'Tap the heart on any product to save it here.',
              );
            }

            final categories =
                saved.expand((d) => _cats(d.data())).toSet().toList()..sort();
            final docs = _apply(saved);

            return Column(
              children: [
                _searchBar(),
                _toolbar(docs.length, categories),
                Expanded(
                  child: docs.isEmpty
                      ? _message(
                          Icons.search_off,
                          'No matches',
                          'Try a different search or filter.',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.64,
                              ),
                          itemCount: docs.length,
                          itemBuilder: (_, i) => _WishlistCard(
                            id: docs[i].id,
                            data: docs[i].data(),
                            onTap: widget.onProductTap,
                            onRemove: () => _remove(docs[i].id, docs[i].data()),
                          ),
                        ),
                ),
                if (unavailable > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '$unavailable saved item(s) are currently unavailable',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _apply(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> input,
  ) {
    var list = input.where((d) {
      final m = d.data();
      final matchesQ =
          _query.isEmpty ||
          (m['name'] ?? '').toString().toLowerCase().contains(
            _query.toLowerCase(),
          );
      final matchesC = _category == null || _cats(m).contains(_category);
      return matchesQ && matchesC;
    }).toList();

    num p(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
        (d.data()['price'] ?? 0) as num;
    num r(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
        (d.data()['rating'] ?? 0) as num;

    switch (_sort) {
      case _Sort.priceLow:
        list.sort((a, b) => p(a).compareTo(p(b)));
      case _Sort.priceHigh:
        list.sort((a, b) => p(b).compareTo(p(a)));
      case _Sort.rating:
        list.sort((a, b) => r(b).compareTo(r(a)));
      case _Sort.discount:
        list.sort(
          (a, b) => _discountNum(b.data()).compareTo(_discountNum(a.data())),
        );
      case _Sort.none:
        break;
    }
    return list;
  }

  Widget _searchBar() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search in wishlist...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withAlpha(120),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _toolbar(int count, List<String> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'Item' : 'Items'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          PopupMenuButton<_Sort>(
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.none, child: Text('Default')),
              PopupMenuItem(
                value: _Sort.priceLow,
                child: Text('Price: low to high'),
              ),
              PopupMenuItem(
                value: _Sort.priceHigh,
                child: Text('Price: high to low'),
              ),
              PopupMenuItem(value: _Sort.rating, child: Text('Top rated')),
              PopupMenuItem(
                value: _Sort.discount,
                child: Text('Biggest discount'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Text('Sort'),
                  SizedBox(width: 4),
                  Icon(Icons.swap_vert, size: 18),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: categories.isEmpty
                ? null
                : () => _filterSheet(categories),
            icon: const Icon(Icons.filter_alt_outlined, size: 18),
            label: Text(_category ?? 'Filter'),
          ),
        ],
      ),
    );
  }

  void _filterSheet(List<String> categories) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All categories'),
              trailing: _category == null ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _category = null);
                Navigator.pop(context);
              },
            ),
            for (final c in categories)
              ListTile(
                title: Text(c),
                trailing: _category == c ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() => _category = c);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(String id, Map<String, dynamic> data) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _wishlistRepository.setSaved(id, saved: false);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('${data['name'] ?? 'Item'} removed'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () => _wishlistRepository.setSaved(id, saved: true),
            ),
          ),
        );
    } on FirebaseException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not update wishlist')),
      );
    }
  }
}

class _WishlistCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final void Function(String id, Map<String, dynamic> data)? onTap;
  final VoidCallback onRemove;
  const _WishlistCard({
    required this.id,
    required this.data,
    this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = (data['name'] ?? '').toString();
    final url = (data['imageUrl'] ?? '').toString();
    final discount = (data['discount'] ?? '').toString();
    final price = (data['price'] ?? 0) as num;
    final oldPrice = (data['oldPrice'] ?? 0) as num;
    final rating = (data['rating'] ?? 0) as num;
    final reviews = (data['reviews'] ?? 0).toString();

    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_outlined, size: 40)),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(id, data),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  url.isEmpty
                      ? placeholder
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => placeholder,
                          loadingBuilder: (_, child, p) =>
                              p == null ? child : placeholder,
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  if (discount.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discount,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        _naira(price),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (oldPrice > price)
                        Text(
                          _naira(oldPrice),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (int i = 1; i <= 5; i++)
                        Icon(
                          i <= rating.round() ? Icons.star : Icons.star_border,
                          size: 13,
                          color: Colors.amber,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        reviews,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
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
}
