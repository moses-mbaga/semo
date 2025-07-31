import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:index/components/helpers.dart";

class VerticalMediaList<T> extends StatelessWidget {
  const VerticalMediaList({
    super.key,
    this.pagingController,
    required this.itemBuilder,
    this.items,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.5,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.isLoading = false,
    this.emptyStateMessage,
    this.errorMessage,
  }) : assert((pagingController != null) || (items != null),
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
      // Grid content
      Flexible(
        child: _buildGridView(context),
      ),
    ],
  );

  Widget _buildGridView(BuildContext context) {
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
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
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
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: items?.length,
        itemBuilder: (BuildContext context, int index) => itemBuilder(context, items![index], index),
      );
    }

    // Fallback - should never reach here due to assertion
    return Container();
  }
}