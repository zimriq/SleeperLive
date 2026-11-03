# App Store listing preparation

Prepared November 3, 2026. English (US) copy is in metadata/en-US. These are copy-and-paste text files, not an automatic App Store Connect upload. No listing has been published. Final publication still requires the privacy policy, production verification, accurate screenshots, and rights review.

## Prepared copy

- name.txt: proposed app name; confirm availability and rights before submission.
- subtitle.txt: proposed subtitle.
- promotional_text.txt: current-feature promotional copy.
- description.txt: plain-text description of implemented behavior, including optional background updates, sample mode, experimental estimates and delivery limits. Deletion copy depends on the matching server endpoint being deployed and tested.
- keywords.txt: comma-separated discovery terms, within the 100-byte limit. No other app/company names are included.
- support_url.txt: current public support page.

Character limits were checked for the app name/subtitle (30), promotional text (170), and description (4,000), plus the keywords' 100-byte limit. The privacy-policy URL is intentionally not supplied because the policy is not published. Do not copy an invented URL or unpublished draft into App Store Connect.

## Screenshot capture plan — not completed

Capture the actual final build in use; concept boards or generated UI are not screenshots of the app. Fictional sample content must retain its Sample/Preview labels. Use non-sensitive data or obtain permission for any real league/user content. Capture the required sizes shown in App Store Connect and verify against Apple's current specifications.

Suggested sequence and optional captions:

1. **Your matchup at a glance** — in-app loaded matchup with both scores and the update time. Keep estimates visually subordinate. If using the sample, retain its labels rather than presenting it as a real matchup.
2. **Follow from your Lock Screen** — actual Lock Screen Live Activity from the final app, including its score/status labels. A sample capture must remain visibly a preview. Hide unrelated personal notifications.
3. **Scores in Dynamic Island** — real expanded presentation on a supported iPhone. Do not add a fictional Island to an unsupported device or invent a score-update animation.
4. **Start with your username** — username lookup and league selection. Avoid making this the only screenshot; show the main functionality first.
5. **You're in control** — actual background-update opt-in or Privacy & Help screen with the current controls.

The Xcode targets currently support both iPhone and iPad. Confirm that universal support is intentional, verify the iPad experience, and supply required iPad screenshots unless the actual shipping target support is changed intentionally. Don't reuse an iPhone screenshot as a fabricated iPad screen. The full set of sizes and validation requirements depends on the selected platform/device families in App Store Connect.

No screenshots were captured or visually approved in this checkpoint. Physical-device push testing, VoiceOver, large text, and the Settings return flow also remain separate checks.

## Fields requiring final decisions or external verification

- App name availability and permission to use third-party names, data, league content, and icon assets. The independent-app disclaimer does not establish those rights.
- Primary category: Sports is the proposed fit; the owner must choose the final category.
- Age rating: complete Apple's questionnaire from actual behavior. Do not infer an age rating merely because this is a fantasy sports app, and do not add claims of betting, prizes, or payments the app does not implement.
- Price, territories, release timing, copyright holder, and any jurisdiction-specific business information: owner decisions, not guessed here.
- Privacy-policy URL and final App Privacy answers: pending operational verification and publication.
- Export-compliance answers: assess actual encryption/framework use and applicable exemptions; no answer is supplied automatically.
- Review contact and any real review account/league data: verify in App Store Connect. APP_REVIEW_NOTES.md supplies the sample-mode instructions, but sample mode does not prove production push works.
- Final archive version/build number, production signing, server revision, device validation, support page and policy availability: check immediately before submission. The server Railway handoff is in PRE_APP_STORE_SERVER_REVIEW.md on develop.

## Sources

- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- https://developer.apple.com/app-store/product-page/
- https://developer.apple.com/app-store/review/guidelines/ — accurate metadata and screenshots of the app in use.
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
