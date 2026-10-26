# arrow.joy Android advertising

Google Mobile Ads 25.5.0 and UMP 4.0.0 are compiled directly into the isolated
Godot Android export. The first-party `ArrowJoyAds` v2 plugin connects native
callbacks to `ad_controller.gd`; the existing `ad_policy.gd` owns eligibility.
Desktop and private workshop builds have no native ad SDK.

## Privacy and placement

- All requests use `AgeRestrictedTreatment.CHILD`, content rating G, disabled
  publisher personalization and `npa=1`. No neutral age screen or birth date.
- UMP refreshes with under-age-of-consent true before SDK initialization.
  Initialization is blocked while `canRequestAds()` is false. No certificate or
  consent bypass. UMP and GMA must both retain their child settings.
- The manifest removes AD_ID and Android Ad Services permissions. No Firebase,
  analytics SDK or additional mediation adapters are installed.
- Privacy options are exposed in Settings → Privacy only when UMP requires them.
  The DE/EN policy describes technical SDK data and keeps local game saves local.
- Only interstitials at eligible normal next-puzzle transitions. No launch ads,
  banners, tutorial ads, collection completion ads or catch-up queue. A no-fill
  or display failure immediately continues without resetting the interval.
- Only the native `ad_opened` signal resets counters. Tokens make duplicate and
  stale callbacks harmless. Back cannot resume gameplay behind a native ad.
- AdMob additionally caps the unit at 1 impression / 6 minutes. High-engagement
  ads (longer close times / extra close steps) are disabled for this app.

## Build and check

The release signing environment is documented in README.md. No keystore secrets
belong in Git. Normal `--release` builds use production IDs from `admob.json`.

```
python tools/build_player.py --godot GODOT --release --output arrow.joy-0.27.0.aab
python tools/build_player.py --godot GODOT --release --test-ads --ads-smoke --output arrow.joy-0.27.0-ADS-SMOKE.apk
```

The second command uses a separate `com.thinkheim.arrowjoy.adstest` package and
Google demo app/unit IDs. Its private smoke harness waits for a demo interstitial,
then exercises the real controller once with eligible test-only counters. It must
never be uploaded as the production app. The production bundle excludes this harness.

`tests/test_native_ads.gd` covers missing ads, failures, genuine opening, duplicate
callbacks, continuation, Back, and disabling the provider for ad-free state.

The Android emulator registered the native plugin and handled a UMP TLS failure
without crashing or requesting ads. The actual Google demo ad could not be fetched
because the emulator did not trust the network certificate. Certificate validation
was not modified. Display and close on the S22 remain a release check; automated
callback tests are not proof that an actual ad was displayed.

## Console follow-up

The production draft uses version code 27001. Ads, data safety and family-targeting
declarations must accompany it. The public DE/EN policy is:
https://heinrichheinrichson-bit.github.io/PROJECT_LOGIC/arrowjoy-privacy.html

Store website:
https://heinrichheinrichson-bit.github.io/PROJECT_LOGIC/arrowjoy.html

The domain-root app-ads.txt already authorizes publisher pub-2541162065593575.
Once the Play listing is public, link package `com.thinkheim.arrowjoy` in AdMob and
complete its app verification/readiness review. Creating the app/unit is not approval
to serve unrestricted live ads.

Official integration references:
- https://developers.google.com/admob/android/quick-start
- https://developers.google.com/admob/android/targeting
- https://developers.google.com/admob/android/privacy
- https://developers.google.com/admob/android/privacy/play-data-disclosure
- https://docs.godotengine.org/en/4.7/tutorials/platform/android/android_plugin.html
