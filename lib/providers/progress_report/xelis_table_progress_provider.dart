import 'package:xelis_flutter/src/api/api.dart' as xelis_api;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';
import 'dart:math' as math;

enum XelisTableGenerationStep {
  t1PointsGeneration,
  t1CuckooSetup,
  t2Table,
  unknown;

  factory XelisTableGenerationStep.fromString(String step) {
    return switch (step) {
      "T1PointsGeneration" => XelisTableGenerationStep.t1PointsGeneration,
      "T1CuckooSetup" => XelisTableGenerationStep.t1CuckooSetup,
      "T2Table" => XelisTableGenerationStep.t2Table,
      _ => XelisTableGenerationStep.unknown,
    };
  }

  String get displayName => switch (this) {
    t1PointsGeneration => "Generating T1 Points",
    t1CuckooSetup => "Setting up T1 Cuckoo",
    t2Table => "Generating T2 Table",
    unknown => "Processing",
  };
}

class XelisTableProgressState {
  final double? tableProgress;
  final XelisTableGenerationStep currentStep;

  const XelisTableProgressState({
    this.tableProgress,
    this.currentStep = XelisTableGenerationStep.unknown,
  });

  XelisTableProgressState copyWith({
    double? tableProgress,
    XelisTableGenerationStep? currentStep,
  }) {
    return XelisTableProgressState(
      tableProgress: tableProgress ?? this.tableProgress,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

final xelisTableProgressProvider = StreamProvider<XelisTableProgressState>((ref) {
  double lastPrintedProgress = 0.0;
  return xelis_api.createProgressReportStream().map((report) {
    return report.when(
      tableGeneration: (progress, step, _) {
        final currentStep = XelisTableGenerationStep.fromString(step);
        final stepIndex = switch(currentStep) {
          XelisTableGenerationStep.t1PointsGeneration => 0,
          XelisTableGenerationStep.t1CuckooSetup => 1,
          XelisTableGenerationStep.t2Table => 2,
          XelisTableGenerationStep.unknown => 0,
        };
        
        if ((progress - lastPrintedProgress).abs() >= 0.05 || 
            currentStep != XelisTableGenerationStep.fromString(step) ||
            progress >= 0.99) {
          debugPrint("Xelis Table Generation: $step - ${progress*100.0}%");
          lastPrintedProgress = progress;
        }

        return XelisTableProgressState(
          tableProgress: progress,
          currentStep: currentStep,
        );
      },
      misc: (_) => const XelisTableProgressState(),
    );
  });
});