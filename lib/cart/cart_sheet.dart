import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bookstore/providers/cart_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:bookstore/cart/payment_webview.dart';

void showCartSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CartSheet(),
  );
}

class CartSheet extends StatefulWidget {
  const CartSheet({Key? key}) : super(key: key);

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildSheetHeader(),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    if (cartProvider.items.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: cartProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = cartProvider.items[index];
                        return ListTile(
                          leading: Image.network(
                            item.coverImage,
                            width: 40,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.book, size: 40),
                          ),
                          title: Text(item.title),
                          subtitle:
                              Text('DZD ${item.price.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                cartProvider.removeFromCart(item.bookId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              _buildCheckoutSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Cart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'DZD ${cartProvider.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: cartProvider.items.isEmpty || _isProcessing
                      ? null
                      : () => _processCheckout(context),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Checkout with Chargily'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPaymentWebView(
      BuildContext context, String paymentUrl, String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebViewPage(
          paymentUrl: paymentUrl,
          orderId: orderId,
        ),
      ),
    );
  }

  Future<void> _processCheckout(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    setState(() {
      _isProcessing = true;
    });

    final result = await cartProvider.checkout('chargily');

    setState(() {
      _isProcessing = false;
    });

    if (result != null && result['payment_url'] != null) {
      // Close the cart sheet
      Navigator.pop(context);

      // Option 1: Use WebView (current implementation)
      _openPaymentWebView(
          context, result['payment_url'], result['order_number'].toString());

      // Option 2: Launch URL in external browser instead
      // import 'package:url_launcher/url_launcher.dart';
      // final Uri url = Uri.parse(result['payment_url']);
      // if (await canLaunchUrl(url)) {
      //   await launchUrl(url, mode: LaunchMode.externalApplication);
      // }
    } else if (cartProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
