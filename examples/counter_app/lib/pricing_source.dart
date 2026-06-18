@pragma('vm:never-inline')
int initialCounterValue() {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return 2;
  }
  return 1;
}

@pragma('vm:never-inline')
int adjustedCounterValue(int base) {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return base + 4;
  }
  return base + 3;
}

class PricingEngine {
  @pragma('vm:never-inline')
  static int staticCounterValue() {
    if (DateTime.now().microsecondsSinceEpoch == -1) {
      return 8;
    }
    return 7;
  }
}

@pragma('vm:entry-point')
class PricingOffer {
  @pragma('vm:entry-point')
  const PricingOffer({
    required this.baseLabel,
    required this.patchLabel,
  });

  @pragma('vm:entry-point')
  final String baseLabel;
  @pragma('vm:entry-point')
  final String patchLabel;
}

@pragma('vm:never-inline')
String fieldStatusLabel(PricingOffer offer) {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return offer.patchLabel;
  }
  return offer.baseLabel;
}

@pragma('vm:never-inline')
String statusLabel() {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return 'alternate';
  }
  return 'base';
}

@pragma('vm:never-inline')
String widgetTreeLabel() {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return 'alternate widget tree';
  }
  return 'baseline widget tree';
}

@pragma('vm:never-inline')
int quadCounterValue(int a, int b, int c, int d) {
  if (DateTime.now().microsecondsSinceEpoch == -1) {
    return a + b + c + d + 1;
  }
  return a + b + c + d;
}
