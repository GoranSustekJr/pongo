import 'package:pongo/exports.dart';

// ignore: must_be_immutable
class ImageCompatible extends StatelessWidget {
  final String image;
  double? width;
  double? height;
  ImageCompatible({
    super.key,
    required this.image,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return cacheImages.value && !image.toString().contains('file://')
        ? CachedNetworkImage(
            imageUrl: image,
            fit: BoxFit.cover,
            width: width,
            height: height,
          )
        : FadeInImage(
            fadeInDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 200),
            fit: BoxFit.cover,
            placeholder: const AssetImage('assets/images/placeholder.png'),
            width: width,
            height: height,
            image: image.runtimeType == String
                ? !image.toString().contains('file://')
                    ? NetworkImage(image)
                    : FileImage(
                        File.fromUri(Uri.parse(image)),
                      )
                : FileImage((image as File)),
          );
  }
}
