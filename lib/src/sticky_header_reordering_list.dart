import 'package:flutter/material.dart';
import 'package:sticky_header_reordering_list/src/utils/measure_size.dart';

/// A widget that displays a reordering list with sticky headers.
///
/// The `StickyHeaderReorderingList` allows you to group items by sections,
/// display sticky headers for each section, and optionally enable drag-and-drop
/// reordering of items.
///
/// This widget is highly customizable and works with any type of data by
/// providing custom builders for items and headers.
///
/// Example usage:
/// ```dart
/// StickyHeaderReorderingList<String>(
///   items: ['Apple', 'Banana', 'Carrot'],
///   sectionExtractor: (item) => item[0], // Groups items by the first letter
///   headerBuilder: (context, section) => Container(
///     color: Colors.grey[200],
///     padding: EdgeInsets.all(8.0),
///     child: Text(section, style: TextStyle(fontWeight: FontWeight.bold)),
///   ),
///   itemBuilder: (context, item) => ListTile(title: Text(item)),
///   isReordering: true,
///   onReorderElements: (data, oldItem, newItem, newIndex, oldIndex, groupedItems) {
///     print("Reordered: $oldItem -> $newItem");
///   },
///   feedback: Material(
///             child: SizedBox(
///                width: MediaQuery.of(context).size.width,
///               child: widget.itemBuilder(context, item),
///              ),
///           ),
///  childWhenDragging: Opacity(
///               opacity: 0.5,
///               child: widget.itemBuilder(context, item),
///             ),
/// );
/// ```
class StickyHeaderReorderingList<T> extends StatefulWidget {
  /// The list of items to display.
  final List<T> items;

  /// A function that extracts the section name from each item.
  ///
  /// The section name is used to group items and create headers.
  final String Function(T) sectionExtractor;

  /// A builder function to create the header widget for each section.
  ///
  /// The `String` parameter represents the section name.
  final Widget Function(BuildContext, String) headerBuilder;

  /// A builder function to create the widget for each item in the list.
  final Widget Function(BuildContext, T) itemBuilder;

  /// Determines whether the list allows drag-and-drop reordering of items.
  ///
  /// Defaults to `false`.
  final bool isReordering;

  /// A callback triggered when items are reordered.
  ///
  /// The callback provides details about the reorder operation:
  /// - `data`: Metadata about the drag operation.
  /// - `oldItem`: The item being moved.
  /// - `newItem`: The item replacing the old position.
  /// - `newIndex`: The new index of the moved item.
  /// - `oldIndex`: The old index of the moved item.
  /// - `items`: The updated grouped items.
  final void Function(
    Map<String, dynamic> data,
    T oldItem,
    T newItem,
    int newIndex,
    int oldIndex,
    Map<String, List<T>> items,
  )? onReorderElements;

  /// The height of the first sticky header.
  ///
  /// Defaults to `50`.
  final double heightOfFirstHeader;

  /// A widget that is displayed while dragging an item.
  ///
  /// If not provided, the default is a [Material] widget wrapping the item's
  /// `itemBuilder` output, styled to appear as a floating version of the item.
  /// This widget represents the visual feedback shown to the user during a drag-and-drop operation.
  final Widget? feedback;

  /// A widget displayed in place of the dragged item in the list.
  ///
  /// If not provided, the default is a semi-transparent version of the item's
  /// `itemBuilder` output. This widget allows you to customize what is shown
  /// in the original item's position while it is being dragged.
  final Widget? childWhenDragging;

  final Widget Function(BuildContext, int)? dividerBuilder;

  /// Creates a [StickyHeaderReorderingList] widget.
  const StickyHeaderReorderingList(
      {super.key,
      required this.items,
      required this.sectionExtractor,
      required this.headerBuilder,
      required this.itemBuilder,
      this.isReordering = false,
      this.onReorderElements,
      this.heightOfFirstHeader = 50,
      this.feedback,
      this.childWhenDragging,
      this.dividerBuilder});

  @override
  State<StickyHeaderReorderingList> createState() =>
      _StickyHeaderReorderingListState<T>();
}

class _StickyHeaderReorderingListState<T>
    extends State<StickyHeaderReorderingList<T>> {
  /// A map of grouped items by section.
  late Map<String, List<T>> groupedItems;

  /// Tracks the index of the currently pinned header.
  int _pinnedHeaderIndex = 0;

  /// The scroll controller for managing the list's scroll behavior.
  final ScrollController _scrollController = ScrollController();

  /// A key to identify the sticky header widget.
  final GlobalKey stickyKey = GlobalKey();

  /// The height of each item in the list. Defaults to `70.0`.
  double itemHeight = 70.0;

  @override
  void initState() {
    super.initState();
    groupedItems = _groupItemsBySection(widget.items);
    _scrollController.addListener(_onScroll);
  }

  /// Groups the provided [items] into sections using [widget.sectionExtractor].
  ///
  /// Returns a map where the keys are section names and the values are lists of items.
  Map<String, List<T>> _groupItemsBySection(List<T> items) {
    Map<String, List<T>> grouped = {};
    for (var item in items) {
      String section = widget.sectionExtractor(item);
      grouped.putIfAbsent(section, () => []).add(item);
    }
    return grouped;
  }

  /// Updates the pinned header based on the current scroll position.
  void _onScroll() {
    double offset = _scrollController.offset;

    for (int i = 0; i < groupedItems.length; i++) {
      double headerPosition = _getHeaderPosition(i);
      double nextHeaderPosition = _getHeaderPosition(i + 1);

      if (offset >= headerPosition - 10 &&
          (i == groupedItems.length - 1 || offset < nextHeaderPosition)) {
        if (_pinnedHeaderIndex != i) {
          setState(() {
            _pinnedHeaderIndex = i;
          });
        }
        break;
      }
    }
  }

  /// Calculates the scroll position of a header at the given [index].
  double _getHeaderPosition(int index) {
    double headerHeight = 50;
    double position = 0.0;

    for (int i = 0; i < index; i++) {
      position += headerHeight +
          (groupedItems[groupedItems.keys.elementAt(i)]!.length * itemHeight);
    }
    return position;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _scrollController,
          slivers: [
            for (int i = 0; i < groupedItems.keys.length; i++) ...[
              _buildHeader(groupedItems.keys.elementAt(i), i),
              _buildDraggableList(
                  i, groupedItems[groupedItems.keys.elementAt(i)]!),
            ]
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildPinnedHeader(),
        ),
      ],
    );
  }

  /// Builds the pinned header for the currently visible section.
  Widget _buildPinnedHeader() {
    String section = groupedItems.keys.elementAt(_pinnedHeaderIndex);
    return widget.headerBuilder(context, section);
  }

  /// Builds the header widget for a specific section.
  Widget _buildHeader(String section, int sectionIndex) {
    if (sectionIndex == 0) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: widget.heightOfFirstHeader,
        ),
      );
    }
    return SliverToBoxAdapter(
      child: widget.headerBuilder(context, section),
    );
  }

  /// Builds the draggable list for a specific section.
  Widget _buildDraggableList(int sectionIndex, List<T> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          if (items.isEmpty) {
            return DragTarget<Map<String, dynamic>>(
              onWillAcceptWithDetails: (data) => true,
              onAcceptWithDetails: (data) {
                final int oldSectionIndex = data.data['sectionIndex'];
                final int oldIndex = data.data['itemIndex'];
                final T oldItem = data.data['item'];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    groupedItems[groupedItems.keys.elementAt(oldSectionIndex)]!
                        .removeAt(oldIndex);
                    groupedItems[groupedItems.keys.elementAt(sectionIndex)]!
                        .add(oldItem);

                    if (widget.onReorderElements != null) {
                      widget.onReorderElements!(
                        data.data,
                        oldItem,
                        oldItem,
                        0,
                        oldIndex,
                        groupedItems,
                      );
                    }
                  });
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  height: 50,
                );
              },
            );
          }
          final item = items[index];
          return MeasureSize(
            onChange: (size) {
              if (size != null && size.height != itemHeight) {
                setState(() {
                  itemHeight = size.height;
                });
              }
            },
            child: !widget.isReordering
                ? widget.itemBuilder(context, item)
                : _buildDraggableItem(sectionIndex, index, item),
          );
        },
        childCount: items.isEmpty ? 1 : items.length,
      ),
    );
  }

  /// Builds a draggable item for the list.
  Widget _buildDraggableItem(int sectionIndex, int index, T item) {
    return LongPressDraggable(
      data: {
        'sectionIndex': sectionIndex,
        'itemIndex': index,
        'item': item,
      },
      feedback: widget.feedback ??
          Material(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: widget.itemBuilder(context, item),
            ),
          ),
      childWhenDragging: widget.childWhenDragging ??
          Opacity(
            opacity: 0.5,
            child: widget.itemBuilder(context, item),
          ),
      child: DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (data) => true,
        onAcceptWithDetails: (data) {
          final int oldSectionIndex = data.data['sectionIndex'];
          final int oldIndex = data.data['itemIndex'];
          final T oldItem = data.data['item'];

          final newSectionIndex = sectionIndex;
          final newIndex = index;
          final T newItem = groupedItems[
              groupedItems.keys.elementAt(newSectionIndex)]![newIndex];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              groupedItems[groupedItems.keys.elementAt(oldSectionIndex)]!
                  .removeAt(oldIndex);
              groupedItems[groupedItems.keys.elementAt(newSectionIndex)]!
                  .insert(newIndex, oldItem);
              if (widget.onReorderElements != null) {
                widget.onReorderElements!(
                  data.data,
                  oldItem,
                  newItem,
                  newIndex,
                  oldIndex,
                  groupedItems,
                );
              }
            });
          });
        },
        builder: (context, candidateData, rejectedData) =>
            widget.itemBuilder(context, item),
      ),
    );
  }
}
