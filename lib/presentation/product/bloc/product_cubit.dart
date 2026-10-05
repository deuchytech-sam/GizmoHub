import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:GizmoHub/data/models/product/product_model.dart';
import 'package:GizmoHub/data/repositories/product/product_repository.dart';

class ProductState {
  final bool isLoading;
  final List<ProductModel> products;
  final String? errorMessage;
  final String query;
  final String? category;
  final String sort;
  final String availability;

  const ProductState({
    this.isLoading = false,
    this.products = const [],
    this.errorMessage,
    this.query = '',
    this.category,
    this.sort = 'featured',
    this.availability = 'all',
  });

  ProductState copyWith({
    bool? isLoading,
    List<ProductModel>? products,
    String? errorMessage,
    String? query,
    String? category,
    String? sort,
    String? availability,
    bool clearCategory = false,
  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      errorMessage: errorMessage,
      query: query ?? this.query,
      category: clearCategory ? null : category ?? this.category,
      sort: sort ?? this.sort,
      availability: availability ?? this.availability,
    );
  }
}

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository productRepository;

  ProductCubit({required this.productRepository}) : super(const ProductState());

  StreamSubscription<List<ProductModel>>? _subscription;

  Future<void> getProducts() async {
    emit(state.copyWith(isLoading: true));

    try {
      final products = await productRepository.getProducts();

      emit(ProductState(isLoading: false, products: products));
    } catch (e) {
      emit(ProductState(isLoading: false, errorMessage: e.toString()));
    }
  }

  void watchProducts() {
    _subscription?.cancel();
    emit(state.copyWith(isLoading: true, errorMessage: null));
    _subscription = productRepository.watchProducts().listen(
      (products) => emit(state.copyWith(isLoading: false, products: products)),
      onError: (Object error) => emit(
        ProductState(
          isLoading: false,
          products: state.products,
          errorMessage: error.toString(),
        ),
      ),
    );
  }

  void setQuery(String value) => emit(state.copyWith(query: value));
  void setSort(String value) => emit(state.copyWith(sort: value));
  void setAvailability(String value) =>
      emit(state.copyWith(availability: value));
  void setCategory(String? value) =>
      emit(state.copyWith(category: value, clearCategory: value == null));

  List<ProductModel> get visibleProducts {
    final query = state.query.trim().toLowerCase();
    final matches = state.products.where((product) {
      final text = '${product.name} ${product.description} ${product.category}'
          .toLowerCase();
      final matchesQuery = query.isEmpty || text.contains(query);
      final matchesCategory =
          state.category == null ||
          product.category.split(', ').contains(state.category);
      final matchesAvailability =
          state.availability != 'in-stock' || product.stockQuantity > 0;
      final matchesNew =
          state.availability != 'new' ||
          (product.createdAt != null &&
              DateTime.now().difference(product.createdAt!).inDays <= 30);
      return matchesQuery &&
          matchesCategory &&
          matchesAvailability &&
          matchesNew;
    }).toList();
    switch (state.sort) {
      case 'low-to-high':
        matches.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'high-to-low':
        matches.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'top-rated':
        matches.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'discount':
        matches.sort((a, b) => b.discountValue.compareTo(a.discountValue));
        break;
      default:
        break;
    }
    return matches;
  }

  List<String> get categories =>
      state.products
          .expand((product) => product.category.split(', '))
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
