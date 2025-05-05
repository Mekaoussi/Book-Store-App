import 'package:flutter/material.dart';

class PurchaseHistoryItem extends StatelessWidget {
  final String bookImageAsset;
  final String authorName;
  final String bookName;
  final double bookRating;
  final String bookPrice;
  final String purchaseDate;

  const PurchaseHistoryItem(
    book, {
    super.key,
    required this.bookImageAsset,
    required this.authorName,
    required this.bookName,
    required this.bookRating,
    required this.bookPrice,
    required this.purchaseDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 5, top: 12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 245, 245, 245),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 152, 72, 178).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                child: SizedBox(
                  width: 100, // Reduced from 120
                  child: Image.asset(
                    bookImageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12), // Reduced from 16
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.0), // Reduced from 16
                          ),
                          const SizedBox(height: 4.0), // Reduced from 8
                          Text(
                            bookName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.0, // Reduced from 18
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            purchaseDate,
                            style: const TextStyle(
                              fontSize: 14.0, // Reduced from 16
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                bookPrice,
                                style: const TextStyle(
                                  fontSize: 14.0, // Reduced from 16
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text("|"),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color.fromARGB(255, 245, 245, 0),
                                    size: 16, // Reduced from 20
                                  ),
                                  const SizedBox(width: 2.0), // Reduced from 4
                                  Text(
                                    bookRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14.0, // Reduced from 16
                                      color: Color.fromARGB(255, 60, 60, 60),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0), // Reduced from 8
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 4),
                              Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(255, 233, 223,
                                          235), // Light purple background
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(15)),
                                    ),
                                    child: const Text(""),
                                  ),
                                  Positioned(
                                    width: 40,
                                    height: 20,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 152, 72,
                                                178), // Your theme purple
                                            Color.fromARGB(255, 176, 106,
                                                197), // Lighter purple
                                          ],
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(15),
                                          bottomLeft: Radius.circular(15),
                                        ),
                                      ),
                                      child: const Center(child: Text("")),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
}
