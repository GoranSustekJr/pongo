String calculateBestImage(List images) {
  if (images.isNotEmpty) {
    int best = 0;
    int bestResoultion = 0;
    for (int i = 0; i < images.length; i++) {
      int resolution = images[i]['width'] != null
          ? images[i]['height'] != null
              ? images[i]['height'] * images[i]['width']
              : images[i]['width'] * images[i]['width']
          : images[i]['height'] != null
              ? images[i]['width'] != null
                  ? images[i]['height'] * images[i]['width']
                  : images[i]['height'] + images[i]['height']
              : 0;
      if (resolution > bestResoultion) {
        best = i;
        bestResoultion = resolution;
      }
    }

    return images[best]["url"];
  }
  return "";
}

String calculateWantedResolution(List images, int width, int height) {
  if (images.isNotEmpty) {
    String? wanted;
    int wantedResolution = width * height;
    print(images[0]);
    List<Map> resolutions = images
        .map((image) => {
              "image": image["url"],
              "resolution": image['width'] != null
                  ? image['height'] != null
                      ? image['height'] * image['width']
                      : image['width'] * image['width']
                  : image['height'] != null
                      ? image['width'] != null
                          ? image['height'] * image['width']
                          : image['height'] + image['height']
                      : 0
            })
        .toList();
    resolutions.sort((a, b) => a['resolution'].compareTo(b['resolution']));

    for (int i = 0; i < resolutions.length; i++) {
      if (resolutions[i]["resolution"] >= wantedResolution) {
        wanted = resolutions[i]["image"];

        break;
      }
    }

    if (wanted == null) {
      return calculateBestImage(images);
    }

    return wanted;
  }
  return "";
}

String calculateBestImageForTrack(List images) {
  if (images.isNotEmpty) {
    int best = 0;
    int bestResoultion = 0;
    for (int i = 0; i < images.length; i++) {
      int resolution = images[i].width != null
          ? images[i].height != null
              ? images[i].height * images[i].width
              : images[i].width * images[i].width
          : images[i].height != null
              ? images[i].width != null
                  ? images[i].height * images[i].width
                  : images[i].height + images[i].height
              : 0;
      if (resolution > bestResoultion) {
        best = i;
        bestResoultion = resolution;
      }
    }

    return images[best].url;
  }
  return "";
}

String calculateWantedResolutionForTrack(List images, int width, int height) {
  if (images.isNotEmpty) {
    String? wanted;
    int wantedResolution = width * height;
    print(images[0]);
    List<Map> resolutions = images
        .map((image) => {
              "image": image.url,
              "resolution": image.width != null
                  ? image.height != null
                      ? image.height * image.width
                      : image.width * image.width
                  : image.height != null
                      ? image.width != null
                          ? image.height * image.width
                          : image.height + image.height
                      : 0
            })
        .toList();
    resolutions.sort((a, b) => a['resolution'].compareTo(b['resolution']));

    for (int i = 0; i < resolutions.length; i++) {
      if (resolutions[i]["resolution"] >= wantedResolution) {
        wanted = resolutions[i]["image"];

        break;
      }
    }

    if (wanted == null) {
      return calculateBestImage(images);
    }

    return wanted;
  }
  return "";
}
