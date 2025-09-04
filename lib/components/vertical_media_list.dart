import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:semo/components/helpers.dart";
import "package:semo/utils/aspect_ratios.dart";

class VerticalMediaList<T> extends StatelessWidget {
  const VerticalMediaList({
    super.key,
    this.pagingController,
    required this.itemBuilder,
    this.items,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.62,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.isLoading = false,
    this.emptyStateMessage,
    this.errorMessage,
  }) : assert(
          (pagingController != null) || (items != null),
          "Either provide pagingController for paginated grid, or items for simple grid",
        );

  final PagingController<int, T>? pagingController;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final List<T>? items;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool isLoading;
  final String? emptyStateMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          Flexible(
            child: _buildGridView(context),
          ),
        ],
      );

  Widget _buildGridView(BuildContext context) {
    final int responsiveCrossAxisCount = _responsiveCrossAxisCount(context);
    final double responsiveAspectRatio = AspectRatios.posterWidthOverHeight;
    final double effectiveCrossAxisSpacing = crossAxisSpacing;
    final double effectiveMainAxisSpacing = mainAxisSpacing;

    // If pagingController is provided, use paginated grid
    if (pagingController != null) {
      return PagingListener<int, T>(
        controller: pagingController!,
        builder: (BuildContext context, PagingState<int, T> state, NextPageCallback fetchNextPage) => PagedGridView<int, T>(
          state: state,
          fetchNextPage: fetchNextPage,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          builderDelegate: PagedChildBuilderDelegate<T>(
            itemBuilder: itemBuilder,
            firstPageErrorIndicatorBuilder: (BuildContext context) => buildErrorIndicator(
              context,
              errorMessage ?? "Failed to load items",
              () => pagingController?.refresh(),
              isFirstPage: true,
            ),
            newPageErrorIndicatorBuilder: (BuildContext context) => buildErrorIndicator(
              context,
              "Failed to load more items",
              () => pagingController?.fetchNextPage(),
              isFirstPage: false,
            ),
            firstPageProgressIndicatorBuilder: (BuildContext context) => buildLoadingIndicator(isFirstPage: true),
            newPageProgressIndicatorBuilder: (BuildContext context) => buildLoadingIndicator(),
            noItemsFoundIndicatorBuilder: (BuildContext context) => buildEmptyState(
              context,
              emptyStateMessage ?? "No items found",
            ),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: responsiveCrossAxisCount,
            crossAxisSpacing: effectiveCrossAxisSpacing,
            mainAxisSpacing: effectiveMainAxisSpacing,
            childAspectRatio: responsiveAspectRatio,
          ),
        ),
      );
    }

    // If items list is provided, use simple GridView.builder
    if (items != null) {
      if (isLoading) {
        return buildLoadingIndicator();
      }

      if (items!.isEmpty) {
        return buildEmptyState(context, emptyStateMessage ?? "No items found");
      }

      return GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsiveCrossAxisCount,
          crossAxisSpacing: effectiveCrossAxisSpacing,
          mainAxisSpacing: effectiveMainAxisSpacing,
          childAspectRatio: responsiveAspectRatio,
        ),
        itemCount: items?.length,
        itemBuilder: (BuildContext context, int index) => itemBuilder(context, items![index], index),
      );
    }

    // Fallback - should never reach here due to assertion
    return Container();
  }

  int _responsiveCrossAxisCount(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isPortrait = size.height >= size.width;
    final bool isTablet = size.shortestSide >= 600;

    // Estimate target item width for posters; adjust per device class.
    final double targetWidth = isTablet ? (isPortrait ? 180 : 200) : (isPortrait ? 120 : 140);

    final double paddingH = padding?.horizontal ?? 0;
    final double availableWidth = size.width - paddingH;
    final int count = (availableWidth / (targetWidth + crossAxisSpacing)).floor().clamp(2, 8);

    // Ensure at least 3 in portrait phones if space allows; more in landscape/tablets.
    if (isPortrait && !isTablet) {
      return count < 3 ? 3 : count;
    }

    return count;
  }
}
