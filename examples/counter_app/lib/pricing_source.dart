@pragma('vm:never-inline')
int initialCounterValue() => 1;

@pragma('vm:never-inline')
int adjustedCounterValue(int base) => base + 3;

class PricingEngine {
  @pragma('vm:never-inline')
  static int staticCounterValue() => 7;
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
String fieldStatusLabel(PricingOffer offer) => offer.baseLabel;

@pragma('vm:never-inline')
String statusLabel() => 'base';

@pragma('vm:never-inline')
String widgetTreeLabel() => 'baseline widget tree';

@pragma('vm:never-inline')
int quadCounterValue(int a, int b, int c, int d) => a + b + c + d;
