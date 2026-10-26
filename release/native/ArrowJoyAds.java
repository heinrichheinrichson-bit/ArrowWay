package com.thinkheim.arrowjoy;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import androidx.annotation.NonNull;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.ump.*;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

/** First-party bridge. All audiences receive child-safe, non-personalized ads.
 * The game owns eligibility. Native code never opens a late-arriving ad. */
public final class ArrowJoyAds extends GodotPlugin {
    private static final String TAG = "ArrowJoyAds";
    private final Handler ui = new Handler(Looper.getMainLooper());
    private volatile ConsentInformation consent;
    private volatile InterstitialAd ad;
    private String unit;
    private boolean started, initialized, loading, presenting, consentUpdating;
    private volatile boolean enabled = true;
    private long loadedAt, retryAt;
    private int requestToken, generation;
    private boolean didShow;

    public ArrowJoyAds(Godot godot) { super(godot); }
    @NonNull @Override public String getPluginName() { return "ArrowJoyAds"; }
    @NonNull @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
            new SignalInfo("ad_opened", Integer.class),
            new SignalInfo("ad_finished", Integer.class, Boolean.class),
            new SignalInfo("privacy_changed")
        ));
    }
    private void status(String value) { Log.i(TAG, value); }

    @UsedByGodot public void start(String interstitialId) {
        ui.post(() -> {
            if (started || getActivity() == null) return;
            started = true; unit = interstitialId;
            // Apply before UMP / MobileAds initialization, including test builds.
            MobileAds.setRequestConfiguration(new RequestConfiguration.Builder()
                .setAgeRestrictedTreatment(AgeRestrictedTreatment.CHILD)
                .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G)
                .setPublisherPrivacyPersonalizationState(
                    RequestConfiguration.PublisherPrivacyPersonalizationState.DISABLED)
                .build());
            consent = UserMessagingPlatform.getConsentInformation(getActivity());
            refreshConsent();
        });
    }
    private void refreshConsent() {
            if (consentUpdating || !enabled || getActivity() == null || consent == null) return;
            consentUpdating = true;
            ConsentRequestParameters params = new ConsentRequestParameters.Builder()
                .setTagForUnderAgeOfConsent(true).build();
            consent.requestConsentInfoUpdate(getActivity(), params, () ->
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(getActivity(), error -> {
                    status(error == null ? "Consent updated" : "Consent form unavailable");
                    privacyUpdated();
                }), error -> {
                    // Only previously valid consent may permit initialization on error.
                    status("Consent update unavailable"); privacyUpdated();
                });
    }
    private void privacyUpdated() {
        consentUpdating = false;
        emitSignal("privacy_changed");
        if (consent == null || !consent.canRequestAds() || !enabled) { ad = null; return; }
        if (initialized) { load(); return; }
        final Activity activity = getActivity();
        if (activity == null || activity.isDestroyed()) return;
        // Guard initialization independently from async consent callbacks.
        initialized = true;
        new Thread(() -> MobileAds.initialize(activity, result ->
            ui.post(() -> { status("SDK initialized: child / G / non-personalized"); load(); }))).start();
    }
    private void load() {
        if (!enabled || !initialized || consent == null || !consent.canRequestAds()
                || loading || ad != null || presenting || getActivity() == null
                || SystemClock.elapsedRealtime() < retryAt) return;
        loading = true;
        final int loadGeneration = generation;
        Bundle extras = new Bundle(); extras.putString("npa", "1");
        AdRequest request = new AdRequest.Builder()
            .addNetworkExtrasBundle(AdMobAdapter.class, extras).build();
        InterstitialAd.load(getActivity(), unit, request, new InterstitialAdLoadCallback() {
            @Override public void onAdLoaded(@NonNull InterstitialAd value) {
                loading = false;
                if (!enabled || loadGeneration != generation || consent == null || !consent.canRequestAds()) return;
                ad = value; loadedAt = SystemClock.elapsedRealtime(); status("Interstitial ready");
            }
            @Override public void onAdFailedToLoad(@NonNull LoadAdError error) {
                loading = false; ad = null; retryAt = SystemClock.elapsedRealtime() + 60000;
                status("No ad available: " + error.getCode());
            }
        });
    }
    @UsedByGodot public void prepare() {
        ui.post(() -> {
            if (consent != null && !consent.canRequestAds()) refreshConsent(); else load();
        });
    }
    @UsedByGodot public boolean isReady() { return ad != null && enabled; }
    @UsedByGodot public void setEnabled(boolean value) {
        ui.post(() -> { enabled = value; if (!value) { generation++; ad = null; } else load(); });
    }
    @UsedByGodot public void show(int token) {
        ui.post(() -> {
            if (presenting) { emitSignal("ad_finished", token, false); return; }
            Activity activity = getActivity();
            if (!enabled || ad == null || consent == null || !consent.canRequestAds()
                    || activity == null || activity.isFinishing() || activity.isDestroyed()
                    || SystemClock.elapsedRealtime() - loadedAt > 55 * 60 * 1000L) {
                ad = null; emitSignal("ad_finished", token, false); load(); return;
            }
            presenting = true; didShow = false; requestToken = token;
            final InterstitialAd current = ad; ad = null;
            current.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdShowedFullScreenContent() {
                    if (!presenting || requestToken != token) return;
                    didShow = true;
                    status("Interstitial opened"); emitSignal("ad_opened", token);
                }
                @Override public void onAdDismissedFullScreenContent() {
                    if (presenting && requestToken == token) finish(didShow);
                }
                @Override public void onAdFailedToShowFullScreenContent(@NonNull AdError error) {
                    if (presenting && requestToken == token) finish(false);
                }
            });
            try { current.show(activity); } catch (RuntimeException error) { finish(false); }
        });
    }
    private void finish(boolean shown) {
        if (!presenting) return;
        presenting = false;
        emitSignal("ad_finished", requestToken, shown); load();
    }
    @UsedByGodot public boolean privacyRequired() {
        return consent != null && consent.getPrivacyOptionsRequirementStatus()
            == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
    }
    @UsedByGodot public void showPrivacy() {
        ui.post(() -> {
            if (consent == null || getActivity() == null || !privacyRequired() || presenting) return;
            generation++; ad = null;
            UserMessagingPlatform.showPrivacyOptionsForm(getActivity(), error -> privacyUpdated());
        });
    }
    @Override public void onMainDestroy() {
        enabled = false; generation++; ad = null; ui.removeCallbacksAndMessages(null);
        super.onMainDestroy();
    }
}
