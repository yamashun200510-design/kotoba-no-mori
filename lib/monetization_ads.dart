import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Optional AdMob integration. The game remains fully playable when ads are
/// unavailable, offline, or not permitted by the user's consent choice.
class MonetizationAds {
  MonetizationAds._();

  static const int dailyCoinReward = 10;
  static const _androidTestUnit = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosTestUnit = 'ca-app-pub-3940256099942544/1712485313';
  static const _configuredAndroidUnit = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID_ID',
  );
  static const _configuredIosUnit = String.fromEnvironment(
    'ADMOB_REWARDED_IOS_ID',
  );

  static final ValueNotifier<bool> rewardReady = ValueNotifier(false);
  static final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(
    false,
  );
  static Future<void>? _initializing;
  static RewardedAd? _rewardedAd;
  static bool _loading = false;

  static bool get supported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool get configuredForBuild => supported && _adUnitId.isNotEmpty;

  static String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_configuredAndroidUnit.isNotEmpty) return _configuredAndroidUnit;
      return kReleaseMode ? '' : _androidTestUnit;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_configuredIosUnit.isNotEmpty) return _configuredIosUnit;
      return kReleaseMode ? '' : _iosTestUnit;
    }
    return '';
  }

  static Future<void> initialize() {
    if (!supported || _adUnitId.isEmpty) return Future.value();
    return _initializing ??= _initialize();
  }

  static Future<void> _initialize() async {
    try {
      await MobileAds.instance.initialize();
      final completed = Completer<void>();

      void finishConsentFlow() {
        if (completed.isCompleted) return;
        unawaited(_refreshConsentAndLoad());
        completed.complete();
      }

      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((_) {
            finishConsentFlow();
          });
        },
        (_) => finishConsentFlow(),
      );
      await completed.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {},
      );
    } catch (error) {
      debugPrint('Optional ad setup unavailable: $error');
    }
  }

  static Future<void> _refreshConsentAndLoad() async {
    try {
      final canRequest = await ConsentInformation.instance.canRequestAds();
      final privacyStatus = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          privacyStatus == PrivacyOptionsRequirementStatus.required;
      if (canRequest) _loadRewarded();
    } catch (error) {
      debugPrint('Ad consent is unavailable: $error');
    }
  }

  static void _loadRewarded() {
    if (_loading || _rewardedAd != null || _adUnitId.isEmpty) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _rewardedAd = ad;
          rewardReady.value = true;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          rewardReady.value = false;
          debugPrint('Rewarded ad unavailable: $error');
        },
      ),
    );
  }

  /// Returns false if there is no ad ready to show. [onEarned] is called only
  /// by the SDK's earned-reward callback, never merely because the ad opened.
  static bool showRewarded({
    required VoidCallback onEarned,
    required VoidCallback onClosed,
  }) {
    final ad = _rewardedAd;
    if (ad == null) return false;
    _rewardedAd = null;
    rewardReady.value = false;
    var closed = false;
    void finish() {
      if (closed) return;
      closed = true;
      ad.dispose();
      onClosed();
      _loadRewarded();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('Rewarded ad could not open: $error');
        finish();
      },
    );
    ad.show(onUserEarnedReward: (_, _) => onEarned());
    return true;
  }

  static void showPrivacyOptions() {
    if (!privacyOptionsRequired.value) return;
    ConsentForm.showPrivacyOptionsForm((_) {
      unawaited(_refreshConsentAndLoad());
    });
  }
}
