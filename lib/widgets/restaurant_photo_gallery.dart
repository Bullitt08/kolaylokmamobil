import 'package:flutter/material.dart';

class RestaurantPhotoGallery extends StatefulWidget {
  final List<String> sliderPhotos;
  final List<String> allPhotos;
  final PageController controller;
  final int currentIndex;
  final Function(int) onPageChanged;

  const RestaurantPhotoGallery({
    Key? key,
    required this.sliderPhotos,
    required this.allPhotos,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  State<RestaurantPhotoGallery> createState() => _RestaurantPhotoGalleryState();
}

class _RestaurantPhotoGalleryState extends State<RestaurantPhotoGallery> {
  Map<int, Key> _progressKeys = {};

  void _resetProgress(int index) {
    setState(() {
      _progressKeys[index] = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoGridGallery(photos: widget.allPhotos),
          ),
        );
      },
      child: Container(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(
              controller: widget.controller,
              itemCount: widget.sliderPhotos.length,
              onPageChanged: widget.onPageChanged,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.sliderPhotos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            if (widget.sliderPhotos.length > 1) ...[
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: widget.currentIndex > 0
                          ? () {
                              widget.controller.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              _resetProgress(widget.currentIndex - 1);
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white),
                      onPressed:
                          widget.currentIndex < widget.sliderPhotos.length - 1
                              ? () {
                                  widget.controller.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  _resetProgress(widget.currentIndex + 1);
                                }
                              : null,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.sliderPhotos.length, (index) {
                    bool isCurrentPhoto = index == widget.currentIndex;
                    if (!_progressKeys.containsKey(index)) {
                      _progressKeys[index] = UniqueKey();
                    }
                    return Container(
                      width: 6,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: TweenAnimationBuilder<double>(
                        key: isCurrentPhoto ? _progressKeys[index] : null,
                        duration: const Duration(seconds: 5),
                        tween:
                            Tween(begin: 0.0, end: isCurrentPhoto ? 1.0 : 0.0),
                        onEnd: () {
                          if (isCurrentPhoto) {
                            if (widget.currentIndex <
                                widget.sliderPhotos.length - 1) {
                              widget.controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              _resetProgress(widget.currentIndex + 1);
                            } else {
                              widget.controller.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              _resetProgress(0);
                            }
                          }
                        },
                        builder: (context, value, child) {
                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              if (isCurrentPhoto)
                                Positioned.fill(
                                  bottom: 24 - (24 * value),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PhotoGridGallery extends StatelessWidget {
  final List<String> photos;

  const PhotoGridGallery({
    Key? key,
    required this.photos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tüm Fotoğraflar (${photos.length})',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(1),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 1,
          crossAxisSpacing: 1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenGallery(
                    photos: photos,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'photo_${photos[index]}',
              child: Container(
                color: Colors.grey[900],
                child: Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const FullScreenGallery({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 50,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    '${_currentIndex + 1}/${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
