import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheManagerImage extends CacheManager {
  static const key = 'imageCache';

  CacheManagerImage()
      : super(
          Config(
            key,
            stalePeriod: const Duration(hours: 2), // Set cache expiration time
            maxNrOfCacheObjects: 100, // Adjust this as needed
          ),
        );
}
