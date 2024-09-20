import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class RecomendationsPhone extends StatefulWidget {
  const RecomendationsPhone({super.key});

  @override
  State<RecomendationsPhone> createState() => _RecomendationsPhoneState();
}

class _RecomendationsPhoneState extends State<RecomendationsPhone> {
  // Pongo:: tracks
  List<sp.Track> pTracks = [];

  // Pongo:: artists
  List<Artist> pArtists = [];

  // Pongo:: albums
  List<Album> pAlbums = [];

  // Pongo:: playlists
  List<Playlist> pPlaylists = [];

  // End-user:: tracks
  List<sp.Track> euTracks = [];

  // End-user:: artists
  List<Artist> euArtists = [];

  // Bool recomendations disabled
  bool recommendationsDisabled = false;

  // Show body
  bool showBody = false;

  @override
  void initState() {
    super.initState();
    getRecommendations();
  }

  void getRecommendations() async {
    final data = await Recommendations().get(context);

    print(data.keys);
    setState(() {
      // Pongo:: tracks

      pTracks = (data["tracks"]["tracks"] as List<dynamic>)
          .map((track) => sp.Track.fromJson(track))
          .toList();

      // Pongo:: artists
      pArtists = (data["artists"]["artists"] as List<dynamic>).map((artist) {
        return Artist(
          id: artist["id"],
          name: artist["name"],
          image: artist["images"].isNotEmpty
              ? calculateWantedResolution(artist["images"], 300, 300)
              : "",
        );
      }).toList();

      // Pongo:: albums
      pAlbums = (data["albums"]["albums"]["items"] as List<dynamic>).isNotEmpty
          ? (data["albums"]["albums"]["items"] as List<dynamic>).map((album) {
              return Album(
                id: album["id"],
                name: album["name"],
                type: album["album_type"],
                artists: album["artists"].map((artist) {
                  return artist["name"]; //{artist["id"]: artist["name"]};
                }).toList(),
                image: calculateWantedResolution(album["images"], 300, 300),
              );
            }).toList()
          : [];

      // Pongo:: playlists
      pPlaylists = (data["playlists"]["playlists"]["items"] as List<dynamic>)
              .isNotEmpty
          ? (data["playlists"]["playlists"]["items"] as List<dynamic>)
              .map((playlist) {
              return Playlist(
                id: playlist["id"],
                name: playlist["name"],
                image: playlist["images"].isNotEmpty
                    ? calculateWantedResolution(playlist["images"], 300, 300)
                    : "",
              );
            }).toList()
          : [];

      // End-user:: tracks
      euTracks = (data["eu_tracks"]["tracks"] as List<dynamic>)
          .map((track) => sp.Track.fromJson(track))
          .toList();

      // End-user:: artists
      euArtists =
          (data["eu_artists"]["artists"] as List<dynamic>).map((artist) {
        return Artist(
          id: artist["id"],
          name: artist["name"],
          image: artist["images"].isNotEmpty
              ? calculateWantedResolution(artist["images"], 300, 300)
              : "",
        );
      }).toList();

      recommendationsDisabled = pTracks.isEmpty &&
          pArtists.isEmpty &&
          pAlbums.isEmpty &&
          pPlaylists.isEmpty &&
          euArtists.isEmpty &&
          euTracks.isEmpty;

      // Show body => true
      showBody = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: showBody
          ? RecommendationsBodyPhone(
              key: const ValueKey(true),
              pTracks: pTracks,
              pArtists: pArtists,
              pAlbums: pAlbums,
              pPlaylists: pPlaylists,
              euTracks: euTracks,
              euArtists: euArtists,
              recommendationsDisabled: recommendationsDisabled,
            )
          : const SizedBox(
              key: ValueKey(false),
            ),
    );
  }
}
