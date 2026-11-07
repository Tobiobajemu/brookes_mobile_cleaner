import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brooke\'s Mobile Cleaner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const MediaCleanerScreen(),
    );
  }
}

class MediaCleanerScreen extends StatefulWidget {
  const MediaCleanerScreen({super.key});

  @override
  State<MediaCleanerScreen> createState() => _MediaCleanerScreenState();
}

class _MediaCleanerScreenState extends State<MediaCleanerScreen> {
  List<AssetEntity> mediaList = [];
  bool isLoading = true;
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    if (kIsWeb) {
      // Web mock data since native photo_manager channels are unavailable on web
      setState(() {
        isLoading = false;
      });
      return;
    }

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      if (albums.isNotEmpty) {
        List<AssetEntity> media = await albums[0].getAssetListRange(
          start: 0,
          end: 100,
        );
        setState(() {
          mediaList = media;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brooke\'s Cleaner App'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : kIsWeb
              ? Center(
              child: SizedBox(
                height: 500,
                width: 350,
                child: CardSwiper(
                      controller: controller,
                      cardsCount: 5,
                      cardBuilder: (context, index, percentX, percentY) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              'https://picsum.photos/600/800?random=$index',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : mediaList.isEmpty
                  ? const Center(child: Text('No media found!'))
                  : SafeArea(
                      child: CardSwiper(
                        controller: controller,
                        cardsCount: mediaList.length,
                        cardBuilder: (context, index, percentX, percentY) {
                          return MediaCard(asset: mediaList[index]);
                        },
                      ),
                    ),
    );
  }
}

class MediaCard extends StatefulWidget {
  final AssetEntity asset;
  const MediaCard({super.key, required this.asset});

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.asset.type == AssetType.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final file = await widget.asset.file;
    if (file != null) {
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF222222),
        child: widget.asset.type == AssetType.video
            ? (_videoController != null && _videoController!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()))
            : (kIsWeb
                ? Image.network(
                    'https://picsum.photos/600/800?random=${widget.hashCode}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image(
                    image: AssetEntityImageProvider(widget.asset, isOriginal: false),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )),
      ),
    );
  }
}