import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class WaterfallLayout {
  WaterfallLayout({
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    required this.itemExtent,
  });

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double Function(int index) itemExtent;

  List<double> computeOffsets(int itemCount) {
    final List<double> offsets = <double>[];
    final List<double> columnHeights =
        List<double>.filled(crossAxisCount, 0.0);

    for (int i = 0; i < itemCount; i++) {
      double minHeight = columnHeights[0];
      int shortestCol = 0;
      for (int c = 1; c < crossAxisCount; c++) {
        if (columnHeights[c] < minHeight) {
          minHeight = columnHeights[c];
          shortestCol = c;
        }
      }

      offsets.add(minHeight);

      final double extent = itemExtent(i);
      columnHeights[shortestCol] = minHeight + extent + mainAxisSpacing;
    }

    return offsets;
  }

  List<int> computeColumns(int itemCount) {
    final List<int> columns = <int>[];
    final List<double> columnHeights =
        List<double>.filled(crossAxisCount, 0.0);

    for (int i = 0; i < itemCount; i++) {
      double minHeight = columnHeights[0];
      int shortestCol = 0;
      for (int c = 1; c < crossAxisCount; c++) {
        if (columnHeights[c] < minHeight) {
          minHeight = columnHeights[c];
          shortestCol = c;
        }
      }

      columns.add(shortestCol);

      final double extent = itemExtent(i);
      columnHeights[shortestCol] = minHeight + extent + mainAxisSpacing;
    }

    return columns;
  }

  double scrollExtent(int itemCount) {
    final List<double> columnHeights =
        List<double>.filled(crossAxisCount, 0.0);

    for (int i = 0; i < itemCount; i++) {
      double minHeight = columnHeights[0];
      int shortestCol = 0;
      for (int c = 1; c < crossAxisCount; c++) {
        if (columnHeights[c] < minHeight) {
          minHeight = columnHeights[c];
          shortestCol = c;
        }
      }

      final double extent = itemExtent(i);
      columnHeights[shortestCol] = minHeight + extent + mainAxisSpacing;
    }

    double maxHeight = 0;
    for (int c = 0; c < crossAxisCount; c++) {
      if (columnHeights[c] > maxHeight) {
        maxHeight = columnHeights[c];
      }
    }

    return (maxHeight - mainAxisSpacing).clamp(0.0, double.infinity);
  }
}

class SliverWaterfallFlow extends SliverMultiBoxAdaptorWidget {
  const SliverWaterfallFlow({
    super.key,
    required super.delegate,
    required this.crossAxisCount,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    required this.itemExtent,
  });

  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double Function(int index) itemExtent;

  @override
  RenderSliverWaterfallFlow createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverWaterfallFlow(
      childManager: element,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      itemExtent: itemExtent,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverWaterfallFlow renderObject) {
    renderObject
      ..crossAxisCount = crossAxisCount
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing
      ..itemExtent = itemExtent;
  }
}

class RenderSliverWaterfallFlow extends RenderSliverMultiBoxAdaptor {
  RenderSliverWaterfallFlow({
    required super.childManager,
    required int crossAxisCount,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
    required double Function(int index) itemExtent,
  })  : _crossAxisCount = crossAxisCount,
        _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing,
        _itemExtent = itemExtent;

  int get crossAxisCount => _crossAxisCount;
  int _crossAxisCount;
  set crossAxisCount(int value) {
    if (_crossAxisCount == value) return;
    _crossAxisCount = value;
    markNeedsLayout();
  }

  double get mainAxisSpacing => _mainAxisSpacing;
  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing == value) return;
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  double get crossAxisSpacing => _crossAxisSpacing;
  double _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing == value) return;
    _crossAxisSpacing = value;
    markNeedsLayout();
  }

  double Function(int index) get itemExtent => _itemExtent;
  double Function(int index) _itemExtent;
  set itemExtent(double Function(int index) value) {
    _itemExtent = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! SliverGridParentData) {
      child.parentData = SliverGridParentData();
    }
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final SliverGridParentData parentData =
        child.parentData! as SliverGridParentData;
    return parentData.crossAxisOffset ?? 0.0;
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.setDidUnderflow(false);

    final int? childCount = childManager.childCount;
    if (childCount == null || childCount == 0) {
      geometry = SliverGeometry.zero;
      return;
    }

    final double childCrossAxisExtent =
        (constraints.crossAxisExtent - (crossAxisCount - 1) * crossAxisSpacing) /
            crossAxisCount;

    final WaterfallLayout layout = WaterfallLayout(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      itemExtent: _itemExtent,
    );

    final List<double> offsets = layout.computeOffsets(childCount);
    final List<int> columns = layout.computeColumns(childCount);

    final double scrollOffset = constraints.scrollOffset;
    final double viewportHeight = constraints.remainingPaintExtent;

    int firstIndex = 0;
    for (int i = 0; i < childCount; i++) {
      if (offsets[i] + _itemExtent(i) > scrollOffset) {
        firstIndex = i;
        break;
      }
    }

    int? targetLastIndex;
    for (int i = firstIndex; i < childCount; i++) {
      if (offsets[i] >= scrollOffset + viewportHeight) {
        targetLastIndex = i;
        break;
      }
    }

    if (firstChild == null) {
      if (!addInitialChild(index: firstIndex, layoutOffset: offsets[firstIndex])) {
        final double max = layout.scrollExtent(childCount);
        geometry = SliverGeometry(scrollExtent: max, maxPaintExtent: max);
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox? trailingChildWithLayout;

    double trailingScrollOffset = offsets[firstIndex] + _itemExtent(firstIndex);

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final BoxConstraints childConstraints = BoxConstraints.tightFor(
        width: childCrossAxisExtent,
        height: _itemExtent(index),
      );
      final RenderBox? child = insertAndLayoutLeadingChild(childConstraints);
      if (child != null) {
        final SliverGridParentData parentData =
            child.parentData! as SliverGridParentData;
        parentData.layoutOffset = offsets[index];
        parentData.crossAxisOffset =
            columns[index] * (childCrossAxisExtent + crossAxisSpacing);
        trailingChildWithLayout ??= child;
        trailingScrollOffset =
            math.max(trailingScrollOffset, offsets[index] + _itemExtent(index));
      }
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(
        BoxConstraints.tightFor(
          width: childCrossAxisExtent,
          height: _itemExtent(firstIndex),
        ),
      );
      final SliverGridParentData parentData =
          firstChild!.parentData! as SliverGridParentData;
      parentData.layoutOffset = offsets[firstIndex];
      parentData.crossAxisOffset =
          columns[firstIndex] * (childCrossAxisExtent + crossAxisSpacing);
      trailingChildWithLayout = firstChild;
    }

    bool reachedEnd = false;
    for (int index = indexOf(trailingChildWithLayout!) + 1;
        targetLastIndex == null || index <= targetLastIndex;
        ++index) {
      final BoxConstraints childConstraints = BoxConstraints.tightFor(
        width: childCrossAxisExtent,
        height: _itemExtent(index),
      );
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(
          childConstraints,
          after: trailingChildWithLayout,
        );
        if (child == null) {
          reachedEnd = true;
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;
      final SliverGridParentData parentData =
          child.parentData! as SliverGridParentData;
      parentData.layoutOffset = offsets[index];
      parentData.crossAxisOffset =
          columns[index] * (childCrossAxisExtent + crossAxisSpacing);
      trailingScrollOffset =
          math.max(trailingScrollOffset, offsets[index] + _itemExtent(index));
    }

    final int lastIndex = indexOf(lastChild!);

    final double estimatedTotalExtent = reachedEnd
        ? trailingScrollOffset
        : childManager.estimateMaxScrollOffset(
            constraints,
            firstIndex: firstIndex,
            lastIndex: lastIndex,
            leadingScrollOffset: offsets[firstIndex],
            trailingScrollOffset: trailingScrollOffset,
          );

    final double paintExtent =
        math.min(estimatedTotalExtent - scrollOffset, viewportHeight);

    final double maxExtent = layout.scrollExtent(childCount);

    geometry = SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintExtent.clamp(0.0, maxExtent),
      maxPaintExtent: maxExtent,
      hasVisualOverflow: estimatedTotalExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );

    childManager.didFinishLayout();
  }
}
