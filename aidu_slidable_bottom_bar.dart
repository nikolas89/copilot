import 'package:aidu_flutter_ui_library/aidu_slidable_bottom_bar/custom_grabbing.dart';
import 'package:flutter/material.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

class AiduSlidableBottomBar extends StatefulWidget {
  final Widget? topFixedSection;
  final Widget bottomFixedSection;
  final List<Widget> children;
  final bool isSlidable;
  final int defaultOpenedChildIndex;

  const AiduSlidableBottomBar({
    Key? key,
    this.topFixedSection,
    required this.bottomFixedSection,
    required this.children,
    this.isSlidable = true,
    this.defaultOpenedChildIndex = 0,
  }) : super(key: key);

  @override
  State<AiduSlidableBottomBar> createState() => AiduSlidableBottomBarState();
}

class AiduSlidableBottomBarState extends State<AiduSlidableBottomBar> {
  late SnappingSheetController controller = SnappingSheetController();
  final childrenScrollController = ScrollController();
  final topFixedSectionKey = GlobalKey();
  final bottomFixedSectionKey = GlobalKey();
  final childrenSectionKey = GlobalKey();

  double? closedBottomFixedSectionHeight;
  double? bottomFixedSectionHeight;
  double? childrenSectionHeight;

  double snappingMinPosition = 0;
  double snappingMaxPosition = 1;
  int snappingPositionIndex = 1;

  List<double?> childrenHeights = [];
  List<GlobalKey> keyList = [];

  bool isOpened = true;

  List<SnappingPosition> _getPositions() {
    final List<SnappingPosition> positionList = [];

    for (var i = 0; i < childrenHeights.length; i++) {
      positionList.add(
        SnappingPosition.pixels(
          positionPixels: childrenHeights[i] as double,
          snappingCurve: Curves.easeOutExpo,
          snappingDuration: const Duration(seconds: 1),
          grabbingContentOffset: GrabbingContentOffset.top,
        ),
      );
    }

    if (positionList.isEmpty) {
      return [
        const SnappingPosition.pixels(
          positionPixels: 0,
          snappingCurve: Curves.easeOutExpo,
          snappingDuration: Duration(seconds: 1),
          grabbingContentOffset: GrabbingContentOffset.top,
        ),
      ];
    }
    return positionList;
  }

  List<Widget> _getChildren() {
    final childrenList = <Widget>[];
    final List<GlobalKey> oldKeyList = [...keyList];
    keyList.clear();

    for (var i = 0; i < widget.children.length; i++) {
      final itemKey = GlobalKey();
      keyList.add(itemKey);
      childrenList.add(
        KeyedSubtree(
          key: itemKey,
          child: widget.children[i],
        ),
      );
    }
    if (oldKeyList.length != keyList.length) {
      _calculateHeight();
    }
    childrenList.add(
      SizedBox(height: bottomFixedSectionHeight),
    );
    return childrenList;
  }

  void _calculateHeight() => WidgetsBinding.instance!.addPostFrameCallback(
        (_) {
          final double? _topFixedSectionHeight;
          if (widget.topFixedSection != null) {
            final RenderBox? topFixedSectionBox =
                topFixedSectionKey.currentContext?.findRenderObject()
                    as RenderBox?;
            _topFixedSectionHeight = topFixedSectionBox?.size.height;
          } else {
            _topFixedSectionHeight = 0.0;
          }

          final RenderBox? bottomFixedSectionBox =
              bottomFixedSectionKey.currentContext?.findRenderObject()
                  as RenderBox?;
          final _bottomFixedSectionHeight = bottomFixedSectionBox?.size.height;
          final RenderBox? childrenSectionBox =
              childrenSectionKey.currentContext?.findRenderObject()
                  as RenderBox?;
          final _childrenSectionHeight = childrenSectionBox?.size.height;

          if (_bottomFixedSectionHeight != null &&
              _childrenSectionHeight != null) {
            isOpened = !widget.isSlidable;

            bottomFixedSectionHeight = _bottomFixedSectionHeight;
            childrenSectionHeight = _childrenSectionHeight;
            closedBottomFixedSectionHeight = _bottomFixedSectionHeight + 10;

            snappingMinPosition = _bottomFixedSectionHeight + 10;
            snappingMaxPosition = _bottomFixedSectionHeight +
                _childrenSectionHeight +
                _topFixedSectionHeight!;

            childrenHeights.clear();
            childrenHeights.add(snappingMinPosition);
            final List<GlobalKey> reversedKeyList = keyList.reversed.toList();

            for (var i = 0; i < reversedKeyList.length; i++) {
              final RenderBox? itemBox = reversedKeyList[i]
                  .currentContext
                  ?.findRenderObject() as RenderBox?;
              double? itemHeight = itemBox?.size.height;
              if (i == 0) {
                itemHeight =
                    itemHeight! + childrenHeights[i]! + _topFixedSectionHeight;
              } else {
                itemHeight = itemHeight! + childrenHeights[i]!;
              }
              childrenHeights.add(itemHeight);
            }
            setState(() {});
          }
          _snapToPosition();
        },
      );

  void _snapToPosition() {
    if (widget.defaultOpenedChildIndex != 0) {
      controller.snapToPosition(
        SnappingPosition.pixels(
          positionPixels:
              childrenHeights[widget.defaultOpenedChildIndex] as double,
          grabbingContentOffset: GrabbingContentOffset.top,
        ),
      );
    } else {
      if (!isOpened || !widget.isSlidable) {
        controller.snapToPosition(
          SnappingPosition.pixels(
            positionPixels: widget.isSlidable
                ? childrenHeights[0] as double
                : snappingMaxPosition,
            grabbingContentOffset: GrabbingContentOffset.top,
          ),
        );
      }
    }
  }

  dynamic _onSheetMoved(sheetPositionData) {
    if (widget.isSlidable) {
      final firstChildHeight = childrenHeights[1] as double;

      if (childrenScrollController.hasClients &&
          sheetPositionData.pixels as double > firstChildHeight) {
        childrenScrollController.animateTo(
          childrenScrollController.position.maxScrollExtent,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 200),
        );
      }

      if (sheetPositionData.relativeToSnappingPositions as double > 0.0 &&
          !isOpened) {
        setState(() {
          isOpened = true;
        });
      } else if (sheetPositionData.relativeToSnappingPositions as double ==
              0.0 &&
          isOpened) {
        setState(() {
          isOpened = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(AiduSlidableBottomBar oldWidget) {
    _snapToPosition();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (childrenScrollController.hasClients) {
        childrenScrollController
            .jumpTo(childrenScrollController.position.maxScrollExtent);
      }
    });

    return GestureDetector(
      onTap: () {
        if (widget.isSlidable) {
          if (snappingPositionIndex == childrenHeights.length) {
            snappingPositionIndex = 0;
          }
          controller.snapToPosition(
            SnappingPosition.pixels(
              positionPixels:
                  childrenHeights[snappingPositionIndex++] as double,
              grabbingContentOffset: GrabbingContentOffset.top,
            ),
          );
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SnappingSheet(
              controller: controller,
              lockOverflowDrag: true,
              initialSnappingPosition: SnappingPosition.pixels(
                positionPixels: snappingMinPosition,
                snappingCurve: Curves.easeOutExpo,
                snappingDuration: const Duration(seconds: 1),
                grabbingContentOffset: GrabbingContentOffset.top,
              ),
              snappingPositions: _getPositions(),
              sheetBelow: SnappingSheetContent(
                draggable: widget.isSlidable,
                child: isOpened
                    ? Container(
                        decoration: widget.isSlidable
                            ? const BoxDecoration(color: Colors.white)
                            : const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  topRight: Radius.circular(5),
                                ),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.08),
                                    blurRadius: 24,
                                  ),
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.1),
                                    blurRadius: 24,
                                    offset: Offset(0, -8),
                                  ),
                                ],
                              ),
                        child: Column(
                          children: [
                            if (widget.isSlidable) const CustomGrabbing(),
                            if (widget.topFixedSection != null)
                              Container(
                                key: topFixedSectionKey,
                                color: Colors.white,
                                child: widget.topFixedSection!,
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: childrenScrollController,
                                physics: const NeverScrollableScrollPhysics(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: widget.topFixedSection == null
                                        ? const BorderRadius.only(
                                            topLeft: Radius.circular(5),
                                            topRight: Radius.circular(5),
                                          )
                                        : BorderRadius.zero,
                                    color: Colors.white,
                                  ),
                                  child: Column(
                                    key: childrenSectionKey,
                                    children: _getChildren(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        child: OverflowBox(
                          minHeight: 0,
                          maxHeight: closedBottomFixedSectionHeight,
                          child: Column(
                            children: [
                              if (widget.isSlidable) const CustomGrabbing(),
                              ColoredBox(
                                color: Colors.white,
                                child: widget.bottomFixedSection,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              onSheetMoved: (sheetPositionData) =>
                  _onSheetMoved(sheetPositionData),
            ),
            if (isOpened)
              Positioned(
                bottom: 0,
                child: Container(
                  key: bottomFixedSectionKey,
                  color: Colors.white,
                  width: MediaQuery.of(context).size.width,
                  height: bottomFixedSectionHeight,
                  child: widget.bottomFixedSection,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
