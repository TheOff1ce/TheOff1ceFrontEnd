import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/ui.dart';
import '../hooks/prescription_hook.dart';
import 'result_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage(
      {super.key, required this.controller, required this.image});
  final PrescriptionController controller;
  final XFile image;
  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(changed);
    widget.controller.analyze(widget.image);
  }

  void changed() {
    if (!mounted) return;
    if (widget.controller.status == PrescriptionStatus.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(controller: widget.controller),
        ),
      );
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        body: SafeArea(
          child: widget.controller.status == PrescriptionStatus.failure
              ? AppError(
                  error: widget.controller.error!,
                  retry: () => widget.controller.analyze(widget.image),
                )
              : const AppLoading(),
        ),
      );
}
