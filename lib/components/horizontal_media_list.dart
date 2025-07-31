import "package:flutter/material.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:index/components/helpers.dart";

class HorizontalMediaList<T> extends StatelessWidget {
  const HorizontalMediaList({
    super.key,
    this.height,
    required this.title,
    this.items,
    this.pagingController,
    required this.itemBuilder,
    this.onViewAllTap,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.isLoading = false,
    this.emptyStateMessage,
    this.errorMessage,
  }) : assert((pagingController != null) || (items != null),
  "Either provide pagingController for paginated list, or items for simple list",
  );

  final double? height;
  final String title;
  final List<T>? items;
  final PagingController<int, T>? pagingController;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VoidCallback? onViewAllTap;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool isLoading;
  final String? emptyStateMessage;
  final String? errorMessage;

  Widget _buildListView(BuildContext context) {
    // If pagingController is provided, use paginated list
    if (pagingController != null) {
      return PagingListener<int, T>(
        controller: pagingController!,
        builder: (BuildContext context, PagingState<int, T> state, NextPageCallback fetchNextPage) => PagedListView<int, T>(
          state: state,
          fetchNextPage: fetchNextPage,
          shrinkWrap: shrinkWrap,
          physics: physics,
          padding: padding,
          scrollDirection: Axis.horizontal,
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
        ),
      );
    }

    // If items list is provided, use simple ListView.builder
    if (items != null) {
      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (items!.isEmpty) {
        return buildEmptyState(context, emptyStateMessage ?? "No items found");
      }

      return ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        itemCount: items?.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) => itemBuilder(context, items![index], index),
      );
    }

    // Fallback - should never reach here due to assertion
    return Container();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Row(
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          if (onViewAllTap != null)
            GestureDetector(
              onTap: onViewAllTap,
              child: Text(
                "View all",
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white54),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: height ?? MediaQuery.of(context).size.height * 0.25,
        child: _buildListView(context),
      ),
    ],
  );
}