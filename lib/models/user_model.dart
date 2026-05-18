enum SubscriptionTier { starter, pro }

class UserModel {
  final String id;
  final String email;
  final String name;
  SubscriptionTier tier;
  final DateTime? subscriptionExpiry;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.tier = SubscriptionTier.starter,
    this.subscriptionExpiry,
  });

  bool get isPro => tier == SubscriptionTier.pro;

  // Limits based on requirements
  int get maxVideoHeight => tier == SubscriptionTier.pro ? 4320 : 1080;
  int get maxAudioBitrate => tier == SubscriptionTier.pro ? 320 : 128;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'],
      name: json['name'],
      tier: json['tier'] == 'pro' ? SubscriptionTier.pro : SubscriptionTier.starter,
      subscriptionExpiry: json['expiry'] != null ? DateTime.parse(json['expiry']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'tier': tier == SubscriptionTier.pro ? 'pro' : 'starter',
      'expiry': subscriptionExpiry?.toIso8601String(),
    };
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String price;
  final String duration;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
  });

  static List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: '6_months_pro',
      name: 'Pro (6 Months)',
      price: '\$19.99',
      duration: '6 Months',
      features: [
        'Download up to 4K / 8K Video',
        '320kbps Studio Quality Audio',
        'No Ads (Forever)',
        'Parallel Downloads',
        'Priority Support'
      ],
    ),
    SubscriptionPlan(
      id: '12_months_pro',
      name: 'Pro (1 Year)',
      price: '\$34.99',
      duration: '12 Months',
      features: [
        'Everything in 6 Months plan',
        'Best Value: Save 15%',
        'Early access to new features',
        'Desktop & Mobile Sync'
      ],
    ),
  ];
}
