import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wl_gen/interfaces/lib_xelis_interface.dart';

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

final xelisTableProgressProvider = StreamProvider<XelisTableProgressState>(
  (ref) => libXelis.createProgressReportStream(),
);
