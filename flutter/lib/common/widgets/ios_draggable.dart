part of 'overlay.dart';

class IOSDraggable extends StatefulWidget {
  const IOSDraggable(
      {Key? key,
      this.chatModel,
      required this.position,
      required this.width,
      required this.height,
      required this.builder})
      : super(key: key);

  final DraggableKeyPosition position;
  final ChatModel? chatModel;
  final double width;
  final double height;
  final Widget Function(BuildContext) builder;

  @override
  IOSDraggableState createState() =>
      IOSDraggableState();
}

class IOSDraggableState extends State<IOSDraggable> {
  @override
  Widget build(BuildContext context) {
    // The enclosing Scaffold already excludes the software keyboard. Use its
    // actual constraints rather than subtracting keyboard insets a second time.
    return LayoutBuilder(builder: (context, constraints) {
      final padding = MediaQuery.paddingOf(context);
      final width = widget.width.clamp(
          0.0, (constraints.maxWidth - padding.horizontal).clamp(0.0, double.infinity));
      final height = widget.height.clamp(
          0.0, (constraints.maxHeight - padding.vertical).clamp(0.0, double.infinity));
      final offset = Offset(
        widget.position.pos.dx.clamp(padding.left,
            (constraints.maxWidth - padding.right - width).clamp(padding.left, double.infinity)),
        widget.position.pos.dy.clamp(padding.top,
            (constraints.maxHeight - padding.bottom - height).clamp(padding.top, double.infinity)),
      );
      return Stack(children: [
        Positioned(
          left: offset.dx,
          top: offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() => widget.position.update(offset + details.delta));
              widget.chatModel?.setChatWindowPosition(widget.position.pos);
            },
            child: Material(
              child: Container(
                width: width,
                height: height,
                decoration:
                    BoxDecoration(border: Border.all(color: MyTheme.border)),
                child: widget.builder(context),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

