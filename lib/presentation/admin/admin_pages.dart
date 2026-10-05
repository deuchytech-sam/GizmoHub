// lib/admin/admin_pages.dart
//
// GizmoHub admin module (Firebase Auth + Cloud Firestore).
// pubspec.yaml needs: firebase_core, firebase_auth, cloud_firestore, firebase_storage, image_picker
//
// Open it from anywhere with:  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGate()));
//
// Firestore collections used:
//   admins/{uid}      -> empty doc (create by hand in the console for each admin)
//   product/{id}      -> name, description, price, oldPrice, discount, rating, reviews,
//                        imageUrl, categories, isActive
//   promos/{id}       -> title, subtitle, buttonText, imageUrl, isActive
//   orders/{id}       -> created by the customer checkout:
//                        userId, userEmail, phone, address, items[{productId, name, imageUrl, price, qty, size}],
//                        subtotal, discount, couponCode, deliveryFee, total, createdAt,
//                        paymentStatus: 'awaiting_confirmation' | 'confirmed' | 'rejected'
//                        deliveryStatus: 'pending' | 'delivered' | 'cancelled'
//   settings/payment  -> bankName, accountName, accountNumber, deliveryFee
//   coupons/{CODE}    -> isActive, percent | amount

import 'package:GizmoHub/core/configs/theme/app_colors.dart';
import 'package:GizmoHub/core/database/gizmo_db.dart';
import 'package:GizmoHub/presentation/admin/admin_order_page.dart';
import 'package:GizmoHub/presentation/admin/payment_settings_page.dart';
import 'package:GizmoHub/presentation/auth/pages/sign_in.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

final _db = gizmoDb;

String naira(num n) =>
    '₦${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

void _toast(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

/// Signs out and sends the user to the sign-in page, clearing the back stack.
Future<void> _signOutToLogin(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const SignInPage()),
    (route) => false,
  );
}

// ───────────────────────── Gate: login + admin check ─────────────────────────

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final user = snap.data;
        if (user == null) return const AdminLoginPage();
        return FutureBuilder<DocumentSnapshot>(
          future: _db.collection('admins').doc(user.uid).get(),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            if (adminSnap.data?.exists == true) return const AdminDashboard();
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('This account is not an admin.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _signOutToLogin(context),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GizmoHub Admin')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) => _login(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Text('Log in'),
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

// ───────────────────────────── Dashboard shell ─────────────────────────────

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    const titles = ['Products', 'Promos', 'Orders', 'Payments'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_i]),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOutToLogin(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _i,
        children: const [
          _ProductsTab(),
          _PromosTab(),
          AdminOrdersView(),
          _PaymentsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            label: 'Promos',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Payments',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Shared bits ───────────────────────────────

Future<bool> _confirm(BuildContext c, String msg) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      title: const Text('Are you sure?'),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
  return r ?? false;
}

Widget _thumb(String? url) => ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: SizedBox(
    width: 48,
    height: 48,
    child: (url == null || url.isEmpty)
        ? const ColoredBox(
            color: Colors.black12,
            child: Icon(Icons.image_outlined),
          )
        : Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Colors.black12,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
  ),
);

Widget _field(
  TextEditingController c,
  String label, {
  bool number = false,
  int lines = 1,
  bool required = true,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: c,
    maxLines: lines,
    keyboardType: number ? TextInputType.number : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (v) =>
        (required && (v == null || v.trim().isEmpty)) ? 'Required' : null,
  ),
);

// ─────────────────────────────── Products ───────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('product').orderBy('name').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No products yet'));
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final p = d.data();
              return ListTile(
                leading: _thumb(p['imageUrl']),
                title: Text(p['name'] ?? ''),
                subtitle: Text(
                  '${naira(p['price'] ?? 0)} • ${p['categories'] ?? ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: p['isActive'] ?? true,
                      onChanged: (v) => d.reference.update({'isActive': v}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        if (await _confirm(
                          context,
                          'Delete "${p['name']}" permanently?',
                        )) {
                          await d.reference.delete();
                          if (context.mounted) {
                            _toast(context, 'Product removed');
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showProductForm(BuildContext context) {
  final key = GlobalKey<FormState>();
  final name = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();
  final oldPrice = TextEditingController();
  final discount = TextEditingController();
  final category = TextEditingController();
  final image = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(ctx).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'New product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _field(name, 'Name'),
              _field(desc, 'Description', lines: 3),
              _field(price, 'Price (₦)', number: true),
              _field(oldPrice, 'Old price (₦)', number: true, required: false),
              _field(discount, 'Discount label e.g. 20%', required: false),
              _field(category, 'Category'),
              _ImageUploadField(controller: image, folder: 'products'),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!key.currentState!.validate()) return;
                    final p = num.parse(price.text.trim());
                    await _db.collection('product').add({
                      'name': name.text.trim(),
                      'description': desc.text.trim(),
                      'price': p,
                      'oldPrice': num.tryParse(oldPrice.text.trim()) ?? p,
                      'discount': discount.text.trim(),
                      'rating': 0,
                      'reviews': 0,
                      'imageUrl': image.text.trim(),
                      'categories': category.text.trim(),
                      'stockQuantity': 1,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isActive': true,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save product'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────── Promos ───────────────────────────────────

class _PromosTab extends StatelessWidget {
  const _PromosTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromoForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add promo'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('promos').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No promos yet'));
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i];
              final p = d.data();
              return ListTile(
                leading: _thumb(p['imageUrl']),
                title: Text(p['title'] ?? ''),
                subtitle: Text('${p['subtitle'] ?? ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: p['isActive'] ?? true,
                      // promos use the same isActive field
                      onChanged: (v) => d.reference.update({'isActive': v}),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        if (await _confirm(context, 'Delete this promo?')) {
                          await d.reference.delete();
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showPromoForm(BuildContext context) {
  final key = GlobalKey<FormState>();
  final title = TextEditingController();
  final subtitle = TextEditingController();
  final buttonText = TextEditingController(text: 'Shop Now');
  final image = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(ctx).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'New promo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _field(title, 'Title e.g. Weekend Sale'),
              _field(subtitle, 'Details e.g. Up to 30% off phones'),
              _field(buttonText, 'Button text e.g. Shop Now'),
              _ImageUploadField(controller: image, folder: 'promos'),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!key.currentState!.validate()) return;
                    await _db.collection('promos').add({
                      'title': title.text.trim(),
                      'subtitle': subtitle.text.trim(),
                      'buttonText': buttonText.text.trim(),
                      'imageUrl': image.text.trim(),
                      'isActive': true,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save promo'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ────────────────────────────────── Payments ──────────────────────────────────
// Orders live in AdminOrdersView (admin_orders_page.dart). This tab shows the
// money side and links to the bank details customers pay into.

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('orders').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final all = snap.data!.docs;

        final paid =
            all.where((d) => d.data()['paymentStatus'] == 'confirmed').toList()
              ..sort((a, b) {
                final ta =
                    (a.data()['paymentConfirmedAt'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;
                final tb =
                    (b.data()['paymentConfirmedAt'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    0;
                return tb.compareTo(ta);
              });

        num sum(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> l) =>
            l.fold<num>(0, (s, d) => s + (d.data()['total'] ?? 0));

        final received = sum(paid);
        final pending = sum(
          all.where(
            (d) =>
                (d.data()['paymentStatus'] ?? 'awaiting_confirmation') ==
                'awaiting_confirmation',
          ),
        );

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: const Text('Bank account & delivery fee'),
                subtitle: const Text('What customers see when they pay'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentSettingsPage(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _stat('Received', naira(received), Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _stat(
                    'Awaiting confirmation',
                    naira(pending),
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirmed payments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (paid.isEmpty) const Text('No confirmed payments yet'),
            for (final d in paid)
              ListTile(
                dense: true,
                title: Text(
                  '${d.data()['userEmail'] ?? d.data()['phone'] ?? 'Customer'}',
                ),
                subtitle: Text(() {
                  final t = (d.data()['paymentConfirmedAt'] as Timestamp?)
                      ?.toDate();
                  return t == null ? '' : '${t.day}/${t.month}/${t.year}';
                }()),
                trailing: Text(
                  naira(d.data()['total'] ?? 0),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ───────────────────────────── Image upload field ─────────────────────────────

/// Picks a photo, uploads it to Firebase Storage and writes the download URL
/// into [controller]. The URL box stays editable so you can still paste one.
class _ImageUploadField extends StatefulWidget {
  final TextEditingController controller;
  final String folder;
  const _ImageUploadField({required this.controller, required this.folder});

  @override
  State<_ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<_ImageUploadField> {
  bool _uploading = false;
  double _progress = 0;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('IMAGE PICK ERROR: $e');
      if (mounted) setState(() => _error = 'Could not open gallery: $e');
      return;
    }
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _progress = 0;
    });
    UploadTask? task;
    try {
      final storage = FirebaseStorage.instance;
      // Give up after ~30s instead of retrying silently for up to 10 minutes.
      storage.setMaxUploadRetryTime(const Duration(seconds: 30));
      debugPrint('STORAGE BUCKET: ${storage.bucket}');

      final bytes = await picked.readAsBytes();
      debugPrint('UPLOAD size: ${bytes.length} bytes');
      final ref = storage.ref(
        '${widget.folder}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}',
      );
      task = ref.putData(
        bytes,
        SettableMetadata(contentType: picked.mimeType ?? 'image/jpeg'),
      );
      task.snapshotEvents.listen((s) {
        debugPrint(
          'UPLOAD ${s.state.name} ${s.bytesTransferred}/${s.totalBytes}',
        );
        if (s.totalBytes > 0 && mounted) {
          setState(() => _progress = s.bytesTransferred / s.totalBytes);
        }
      }, onError: (Object e) => debugPrint('UPLOAD STREAM ERROR: $e'));
      await task.timeout(const Duration(seconds: 60));
      widget.controller.text = await ref.getDownloadURL();
    } on TimeoutException {
      task?.cancel();
      debugPrint('UPLOAD TIMEOUT');
      if (mounted) {
        setState(
          () => _error =
              'Upload timed out (bucket: ${FirebaseStorage.instance.bucket}). '
              'Check your internet, the bucket name and the Storage rules.',
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('UPLOAD ERROR: ${e.code} - ${e.message}');
      if (mounted) {
        setState(
          () => _error =
              '${e.code}: ${e.message} (bucket: ${FirebaseStorage.instance.bucket})',
        );
      }
    } catch (e) {
      debugPrint('UPLOAD ERROR: $e');
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: const Icon(Icons.upload),
                label: Text(
                  _uploading
                      ? 'Uploading ${(_progress * 100).round()}%'
                      : 'Upload image',
                ),
              ),
              const SizedBox(width: 12),
              if (url.isNotEmpty) _thumb(url),
            ],
          ),
          if (_uploading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                color: AppColors.primary,
              ),
            ),
          // Shown inline because a SnackBar would hide behind the bottom sheet.
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.controller,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Image URL (filled automatically after upload)',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Upload an image first'
                : null,
          ),
        ],
      ),
    );
  }
}
