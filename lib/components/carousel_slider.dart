import "package:carousel_slider/carousel_slider.dart" as slider;
import "package:flutter/material.dart";
import "package:index/components/carousel_poster.dart";
import "package:index/enums/media_type.dart";
import "package:index/models/movie.dart";
import "package:index/models/tv_show.dart";
import "package:smooth_page_indicator/smooth_page_indicator.dart";

class CarouselSlider extends StatelessWidget {
  CarouselSlider({
    super.key,
    required this.mediaType,
    required this.items,
    required this.currentItemIndex,
    required this.onItemChanged,
    this.onItemTap,
  });

  final MediaType mediaType;
  final List<dynamic> items;
  final int currentItemIndex;
  final Function(int index) onItemChanged;
  final Function(int index)? onItemTap;

  final slider.CarouselSliderController _controller = slider.CarouselSliderController();

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      slider.CarouselSlider.builder(
        carouselController: _controller,
        itemCount: items.length,
        options: slider.CarouselOptions(
          aspectRatio: 2,
          autoPlay: true,
          enlargeCenterPage: true,
          onPageChanged: (int index, slider.CarouselPageChangedReason reason) => onItemChanged(index),
        ),
        itemBuilder: (BuildContext context, int index, int realIndex) {
          dynamic media = items[index];
          final String backdropPath = media.backdropPath;
          late String title;

          if (mediaType == MediaType.movies) {
            Movie movie = media as Movie;
            title = movie.title;
          } else if (mediaType == MediaType.tvShows) {
            TvShow tvShow = media as TvShow;
            title = tvShow.originalName;
          }

          return CarouselPoster(
            backdropPath: backdropPath,
            title: title,
            onTap: () => onItemTap?.call(index),
          );
        },
      ),
      Container(
        margin: const EdgeInsets.only(top: 20),
        child: AnimatedSmoothIndicator(
          activeIndex: currentItemIndex,
          count: items.length,
          effect: ExpandingDotsEffect(
            dotWidth: 10,
            dotHeight: 10,
            dotColor: Colors.white30,
            activeDotColor: Theme.of(context).primaryColor,
          ),
        ),
      ),
    ],
  );
}