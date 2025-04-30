import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  // Get all products as a stream
  Stream<List<Product>> getProducts() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    query = query.toLowerCase();
    return _productsCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  // Search products (synchronous for instant results)
  Future<List<Product>> searchProductsSync(String query) async {
    query = query.toLowerCase();

    try {
      // First try exact match search
      final exactMatchSnapshot =
          await _productsCollection.where('nameLower', isEqualTo: query).get();

      if (exactMatchSnapshot.docs.isNotEmpty) {
        return exactMatchSnapshot.docs.map((doc) {
          return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      }

      // If no exact matches, try contains search
      final containsSnapshot =
          await _productsCollection
              .where('nameLower', isGreaterThanOrEqualTo: query)
              .where('nameLower', isLessThanOrEqualTo: '$query\uf8ff')
              .get();

      return containsSnapshot.docs.map((doc) {
        return Product.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      // Fallback search if field indices are not set up
      final allProductsSnapshot = await _productsCollection.get();

      return allProductsSnapshot.docs
          .map(
            (doc) =>
                Product.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .where((product) => product.name.toLowerCase().contains(query))
          .toList();
    }
  }

  // Get a product by ID
  Future<Product> getProductById(String id) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(id).get();

      if (!doc.exists) {
        throw Exception('Product not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return Product(
        id: doc.id,
        name: data['name'] ?? '',
        price:
            (data['price'] is int)
                ? (data['price'] as int).toDouble()
                : (data['price'] ?? 0.0),
        gstRate: data['gstRate'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Add a new product
  Future<void> addProduct(Product product) async {
    await _productsCollection.add({
      ...product.toMap(),
      'nameLower': product.name.toLowerCase(),
    });
  }

  // Update an existing product
  Future<void> updateProduct(Product product) async {
    await _productsCollection.doc(product.id).update({
      ...product.toMap(),
      'nameLower': product.name.toLowerCase(),
    });
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }
}
