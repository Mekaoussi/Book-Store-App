import 'package:bookstore/getting_books/data_models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:io';

class collectionTabItem extends StatelessWidget {
  final Book book;
  final String markedOrFav;

  const collectionTabItem({
    super.key,
    required this.markedOrFav,
    required this.book,
  });

  Future<String?> _getLocalCoverPath() async {
    try {
      final coversBox = await Hive.openBox<String>('downloadedCovers');
      return coversBox.get(book.id.toString());
    } catch (e) {
      print('Error getting local cover path: $e');
      return null;
    }
  }

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
                  width: 100,
                  child: FutureBuilder<String?>(
                    future: _getLocalCoverPath(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        // Use local image file if available
                        return Image.file(
                          File(snapshot.data!),
                          width: 100,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to network image if local file is corrupted
                            return CachedNetworkImage(
                              imageUrl: book.coverImage,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.book,
                                    size: 40, color: Colors.grey),
                              ),
                            );
                          },
                        );
                      } else {
                        // Try network image if no local file
                        return CachedNetworkImage(
                          imageUrl: book.coverImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.book,
                                size: 40, color: Colors.grey),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  book.author,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              markedOrFav == "marked"
                                  ? const Icon(Icons.bookmark, size: 18.0)
                                  : const Icon(
                                      Icons.favorite,
                                      color: Color.fromARGB(255, 255, 0, 0),
                                      size: 18.0,
                                    ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            book.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            book.publicationDate,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DZD ${book.price.toString()}',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text("|"),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color.fromARGB(255, 245, 245, 0),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2.0),
                                  Text(
                                    book.totalRating.toString(),
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: Color.fromARGB(255, 60, 60, 60),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          SizedBox(
                            height: 26,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: book.genres.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color:
                                            const Color.fromARGB(255, 0, 0, 0),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      book.genres[index],
                                      style: const TextStyle(fontSize: 12.0),
                                    ),
                                  ),
                                );
                              },
                            ),
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
