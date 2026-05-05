# Application: Critical Alerts entitlement for Droonialarm (iOS)

**Submitted via:** [Apple Developer Contact — Notifications: Critical Alerts](https://developer.apple.com/contact/request/notifications-critical-alerts/)

**Applicant:** Martti Randma — randma.martti@gmail.com — +372 5539649
**Apple Developer Team:** [team name + ID]
**App bundle identifier:** `ee.droonialarm`
**App name:** Droonialarm
**Date of submission:** 5 May 2026

---

## Form fields

### App description

Droonialarm is a non-commercial, open-source iOS and Android application that re-broadcasts Estonia's official **EE-ALARM** public emergency notifications (drone incursions, air-raid warnings, and other state-issued public-safety alerts) to subscribed users. Estonia is currently experiencing periodic Russian-launched drone incursions across its border (most recently 25 March 2026 Auvere strike, 31 March 2026 Estonia-wide alert, and 3 May 2026 Võrumaa alert) and the official notification channel — location-based SMS — does not bypass silent mode or Do Not Disturb. Estonia's Päästeamet (Rescue Board) has [publicly acknowledged](https://news.err.ee/1609984362/estonia-to-introduce-cell-broadcast-emergency-alert-system-in-2027) that the new network-based cell broadcast system is "more effective than current app notifications and SMS messages" and that some users have contacted the Rescue Board specifically because the SMS did not reach them. Cell broadcast (the proper EU-Alert standard) is procured but not operational until 2027.

Until 2027, Droonialarm is the only realistic mechanism by which sleeping or silent-phone users — including the elderly, people in Do Not Disturb, and Estonians abroad concerned about family at home — can be reliably woken when a state-issued emergency alert is dispatched.

### Why Critical Alerts are essential to the app's purpose

The entire purpose of the app is to wake the user from silence. Without Critical Alerts entitlement, iOS users in silent mode or with any Focus mode active will not hear the notification, defeating the only reason the app exists.

We have already implemented the Android equivalent (`USAGE_ALARM` notification channel with `enableBypassDnd(true)` and `ACCESS_NOTIFICATION_POLICY` permission). For iOS, we want to provide equivalent reliability — which only Critical Alerts entitlement enables.

We will use Critical Alerts **exclusively** for state-issued EE-ALARM emergency events sourced from Estonia's official `api.app.eesti.ee/api/sitrep/v1/full-events` SITREP feed (operated by the Information System Authority RIA / SMIT, the Estonian Ministry of Interior IT Centre). The app does not generate alerts itself; it only re-broadcasts what the Estonian state has already issued through its own channels.

### Frequency of Critical Alerts

Based on historical data:
- Major nationwide alerts: 2-4 per year
- Regional drone-incursion alerts: 5-15 per year (frequency rising due to ongoing Russian aggression)
- Annual nationwide siren tests (Päästeamet): 2 per year, scheduled and pre-announced

Critical Alerts will fire only on alerts that meet **all** of the following criteria:
1. Sourced from Estonia's official SITREP feed (no other sources)
2. Of `type: NOTIFICATION` and `state: OPEN`
3. Containing actual public-safety content (excluding internal-test entries)

We will explicitly **not** use Critical Alerts for:
- Marketing
- Engagement
- Update notifications
- Any non-life-safety event

### Disclaimers and user controls

The app's onboarding flow makes the user explicitly opt in to Critical Alerts (iOS native UNAuthorizationOptions opt-in dialog), and a clear disclaimer on every screen states:

> **MITTEAMETLIK / UNOFFICIAL.** The official emergency notification channel is EE-ALARM (helpline 1247) operated by Päästeamet. This app is a third-party re-broadcast tool and does not replace the official channel.

Users can disable Critical Alerts at any time via iOS Settings → Notifications → Droonialarm → Critical Alerts.

### Public-safety justification — supporting evidence

1. **Estonia is a NATO frontline state** experiencing weekly airspace incidents. Recent confirmed events:
   - **25 March 2026:** Russian Geran-2 drone struck the chimney of Auvere power station (Ida-Virumaa, Estonia). EE-ALARM was activated.
   - **31 March 2026:** Estonia-wide air-raid alert issued by Estonian Defence Forces (Kaitsevägi).
   - **3 May 2026:** Drone-threat alert for Võrumaa (single-county SMS-only alert).

2. **Päästeamet's own admission** that the SMS system is inadequate — same source cited above.

3. **Concurrent formal request** to Estonian state authorities (Päästeamet, RIA, SMIT, Ministry of Interior) under Estonia's Public Information Act (Avaliku teabe seadus § 14), requesting partnership for direct SITREP feed access. Letter is publicly published at: <https://github.com/marttirandma/droonialarm/blob/main/docs/letter-to-paasteamet.md>

4. **Project credibility**: Open-source (MIT license). All code, documentation, infrastructure analysis, and reverse-engineering findings are publicly published. We have no commercial interest. Hosting costs (~15€/month) are paid by the applicant personally.

5. **Real users impacted**: At least three independent Estonian residents have personally contacted the applicant after the 3 May 2026 Võrumaa drone alert, reporting that they did not hear the SMS because their phone was on silent. This includes the applicant's own mother. The applicant himself is currently abroad while his daughter remains in Estonia, with no way to ensure she hears alerts at night.

6. **The official Estonian apps do not currently bypass silent mode on either platform.** Estonia's "Eesti äpp" (the consumer-facing official app, RIA-built) does support a guest mode without authentication, but on Android it uses the default `fcm_fallback_notification_channel` (USAGE_NOTIFICATION_EVENT), which does not bypass silent / DND. Its iOS `Runner.entitlements` does not include `com.apple.developer.usernotifications.critical-alerts`. Estonia's "Ole valmis!" app similarly lacks both. Until either of these is updated — which we are formally requesting in our concurrent letter to Päästeamet/RIA/SMIT — there is no native iOS path by which an Estonian resident can be reliably awakened from silent mode by an EE-ALARM notification. Droonialarm fills this gap.

### Project repository

Full transparency: every line of code, every research finding, the SITREP API analysis, the rate-limiter logger that records what the public Estonian feed contains in real time, our privacy policy, and the formal letter to Estonian authorities — all are publicly available at:

**<https://github.com/marttirandma/droonialarm>**

Live infrastructure (already running):
- Cloudflare Worker SITREP logger: <https://droonialarm-sitrep-logger.zzpgkx8hcv.workers.dev>
- Privacy policy: <https://marttirandma.github.io/droonialarm/privacy/>

### Commitment

If Apple grants the Critical Alerts entitlement, we commit to:
1. Using it strictly for EE-ALARM-sourced public-safety events (defined above)
2. Maintaining an audit log of every Critical Alert dispatched, publicly visible
3. Implementing user-facing controls per Apple Human Interface Guidelines for emergency alerts
4. Providing Apple a private contact (the applicant's email + phone above) for any concerns

We are also willing to:
- Limit Critical Alert usage to a maximum number per month, contractually agreed with Apple
- Restrict the audience to verified Estonian-located accounts if required
- Submit to additional review at Apple's discretion

If Apple denies the entitlement, the iOS application will not be released to the App Store. We will not deploy iOS notifications without entitlement, since standard delivery would silently fail for the very users we exist to serve.

---

**Thank you for considering this application.**

Martti Randma
randma.martti@gmail.com
+372 5539649

[github.com/marttirandma/droonialarm](https://github.com/marttirandma/droonialarm)
