import 'package:bookstore/book_product/book_product_page.dart';
import 'package:bookstore/getting_books/books_provider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../getting_books/data_models.dart';

class OrderItem extends StatelessWidget {
  final Order order;

  const OrderItem({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header with improved layout - status badge below order number
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildStatusBadge(order.status),
              ],
            ),
            const Divider(thickness: 1, height: 24),

            // Order details with improved layout
            _buildInfoRow(
                'Date', DateFormat('MMM dd, yyyy').format(order.createdAt)),
            _buildInfoRow(
                'Payment Method', _formatPaymentMethod(order.paymentMethod)),
            _buildInfoRow(
                'Total Amount', 'DZD ${order.totalAmount.toStringAsFixed(2)}'),

            const SizedBox(height: 16.0),
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Items (${order.items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Order items with improved layout
            if (order.items.isNotEmpty)
              ...order.items.map((item) => _buildOrderItemTile(item)).toList()
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No items in this order',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'chargily':
        return 'Chargily Pay';
      case 'credit_card':
        return 'Credit Card';
      case 'paypal':
        return 'PayPal';
      default:
        return method
            .split('_')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : '')
            .join(' ');
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String displayStatus;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'paid':
        badgeColor = Colors.green;
        displayStatus = 'Paid';
        statusIcon = Icons.check_circle;
        break;
      case 'processing':
        badgeColor = Colors.blue;
        displayStatus = 'Processing';
        statusIcon = Icons.hourglass_top;
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        displayStatus = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        badgeColor = Colors.orange;
        displayStatus = 'Pending';
        statusIcon = Icons.pending;
        break;
    }

    return Container(
      constraints: const BoxConstraints(
          maxWidth: 120), // Limit width to prevent overflow
      child: Chip(
        padding: const EdgeInsets.symmetric(
            horizontal: 4, vertical: 0), // Reduce padding
        backgroundColor: badgeColor.withOpacity(0.1),
        label: Row(
          mainAxisSize: MainAxisSize.min, // Make row take minimum space
          children: [
            Icon(statusIcon, size: 16, color: badgeColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                displayStatus,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Smaller font size
                ),
                overflow:
                    TextOverflow.ellipsis, // Handle text overflow gracefully
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(dynamic orderItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover with improved styling
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: orderItem.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: orderItem.coverImage!,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book),
                  ),
          ),
          const SizedBox(width: 12.0),

          // Book details with improved layout
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderItem.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                if (orderItem.author != null && orderItem.author.isNotEmpty)
                  Text(
                    orderItem.author,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DZD ${orderItem.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 152, 72, 178),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 152, 72, 178)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'pdf',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Color.fromARGB(255, 152, 72, 178),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () {
                      // Navigate to book details
                      if (orderItem.bookId != null) {
                        final bookProvider =
                            Provider.of<BookProvider>(context, listen: false);
                        final book = bookProvider.getBookById(orderItem.bookId);

                        if (book != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookProductPage(book: book),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'View Book',
                      style: TextStyle(
                        color: Color.fromARGB(255, 152, 72, 178),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
