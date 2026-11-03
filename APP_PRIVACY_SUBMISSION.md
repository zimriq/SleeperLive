# Privacy submission preparation

Prepared November 3, 2026. This is a working guide for completing the submission, not a published privacy policy or certification of production settings. Manifest categories reflect the local app/server code and the owner's statement that no analytics or crash-reporting service is used. Recheck after any SDK, backend, hosting, or business-model change.

## Implemented manifest declarations

The app's PrivacyInfo.xcprivacy declares no tracking and retains its required-reason UserDefaults entry, CA92.1. It now declares these collected data categories, linked to a device/account and used for App Functionality:

- **User ID:** account/display handles and roster identity obtained through Sleeper and associated with the selected matchup. The app has no Sleeper password or separate username/password login. A username saved only on-device would not itself be collection, but server-held names/roster associations are not solely on-device.
- **Device ID:** the server-issued device identifier, attestation key identifier, and Live Activity push-token association used for authentication and delivery. These are device identifiers even without an advertising identifier.
- **Other User Content:** user-created league/team names saved with activity attributes.
- **Gameplay Content:** saved fantasy matchup selection, scores, and estimates associated with the roster/device. Classification as gameplay content is a considered interpretation for this fantasy-sports companion, not a statement that it offers real-money gaming. Confirm that this category remains appropriate in the final submission questionnaire.
- **Product Interaction:** stored Live Activity start, end, and delivery lifecycle information. This is for functionality, not behavioral analytics. No browsing or general tap history is implemented.

All entries have Linked = Yes because retained activity data connects to the device registration and roster/account context. Hashing a credential does not by itself make the related record anonymous. All entries have Tracking = No and purpose App Functionality based on reviewed behavior. No tracking domain list is supplied because no cross-app advertising or data-broker tracking is implemented. The App Tracking Transparency prompt is not a general privacy-consent prompt and should not be added solely because these functionality identifiers exist.

## App Store Connect answers still need verification

Use the categories above as the starting point, not automatic final answers. Opting in does not remove disclosure obligations for data that is retained off-device. The privacy manifest, App Store privacy questionnaire, published policy, and actual production behavior must agree.

Before submitting:

1. Verify Railway access/application log configuration and retention. Determine whether network identifiers, request metadata, diagnostic information, or request bodies are retained and whether additional categories apply. The source-level IP rate counters alone do not establish the hosting provider's practices.
2. Confirm database backup type, schedule, retention, access controls, and treatment of deletion requests when restoring a backup.
3. Assess support email contents and contact details. If the customer-support optional-disclosure exception does not meet all Apple's conditions, add Customer Support and any applicable contact categories to the final declarations. Do not claim that support email never contains personal data.
4. Verify the deployed server matches the reviewed code, including the active-database deletion route. Account/device deletion and disconnection have different retention effects. This manifest does not promise deletion from backups or logs.
5. Review the exported distribution archive's privacy report in Xcode Organizer, including any linked SDKs. No third-party iOS package references were found in the reviewed Xcode project; recheck the final archive rather than assuming that remains true.
6. Verify public privacy-policy and support URLs, enter the final questionnaire answers, and ensure the in-app policy link is visible. The privacy-policy URL is still missing; the app is not submission-ready.

## Required-reason API review

The current app accesses UserDefaults through AppStorage for the last username, selected league, and cached dashboard. Those values are used by the app itself, matching its CA92.1 declaration. A source search did not identify the common file-timestamp, disk-space, uptime, or keyboard-list APIs checked during this pass. That search is not a binary-level audit or proof that all future code/SDKs are covered. The widget renders activity content and contains no separate persistent preferences or outbound network client in the reviewed source.

## Sources

- https://developer.apple.com/app-store/app-privacy-details/ — collection, linked data, tracking, and optional disclosure definitions.
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype — category identifiers and definitions.
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatypepurposes — App Functionality includes authentication, features, fraud prevention, and security.
- https://developer.apple.com/documentation/technotes/tn3184-adding-data-collection-details-to-your-privacy-manifest — manifest schema.
