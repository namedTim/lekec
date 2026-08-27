import 'package:flutter/material.dart';

/// A scrollable that always shows its scrollbar thumb, so the user can
/// see at a glance that more content exists below the viewport. Used on
/// medication-planning forms where the primary action ("Shrani"/"Naprej")
/// sits below the fold on smaller phones.
class HintedScrollView extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  const HintedScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  @override
  State<HintedScrollView> createState() => _HintedScrollViewState();
}

class _HintedScrollViewState extends State<HintedScrollView> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        padding: widget.padding,
        physics: widget.physics,
        child: widget.child,
      ),
    );
  }
}
