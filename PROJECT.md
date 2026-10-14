# Indore Chai Company — Distribution Management (Chai Project)

A **Flutter web-first** application (mobile-ready) for running a tea/chai
**distribution** business. Backed by **Firebase** (Auth + Firestore). Three
roles share a **single login**:

- **Admin** — manages products, employees, companies (clients), approvals, per-company billing, and the request/complaint inbox.
- **Employee** — works from a Home screen: records a **company sale** (added to that company's bill, no payment) or a **walk-in sale** (companyless, collects cash/UPI), registers a company for approval, and raises complaints.
- **Company (client)** — raises requests, pays bills, raises complaints, sees notifications.

> **Status (2026-09-07):** The delivery-**route** feature has been removed to
> simplify the app. The employee app is now **Home-first with two direct sale
> actions** — a *company sale* (added to the company's bill / "subscription", no
> payment taken) and a *walk-in sale* (companyless, cash/UPI collected on the
> spot). The admin console dropped Routes; **Inbox moved to an app-bar icon**
> (badged with pending requests + complaints), the **admin notification bell was
> removed**, and **billing moved onto each company** (a bill icon on the company
> card opens a per-company detail + invoices/payments page). Branding, single
> login and role routing are unchanged.
>
> What remains is **hardening, not features**: Firestore security rules are
> still absent, multi-document writes are still non-transactional, and FCM push
> is still dead code. Removing the route also left the company **request →
> approve** loop without an employee fulfilment step. See [Known gaps](#known-gaps--todo).

---

## Tech Stack

| Layer            | Technology                                                        |
| ---------------- | ----------------------------------------------------------------- |
| Framework        | Flutter (web-first) · Dart 3.10.4                                  |
| State management | `flutter_riverpod` ^3.3.2 — plain `Provider` / `StreamProvider`, no Notifier classes |
| Navigation       | `go_router` ^17.5.0 (path-based URLs on web)                      |
| Backend          | `firebase_core`, `firebase_auth`, `cloud_firestore`               |
| Secure storage   | `flutter_secure_storage` (remember-me credential prefill)         |
| Docs / invoices  | `pdf` + `printing` — live: per-company billing page + company Bills tab |
| Push             | `firebase_messaging` — **written, not reachable; no service worker** |
| Formatting       | `intl` (₹ currency, dates)                                        |
| UI               | Material 3 (**brand orange `#F06030`** seed), `google_fonts` (Inter), **forced light theme** |

**Declared but never imported** (safe to remove from `pubspec.yaml`):
`fl_chart`, `firebase_storage`. Storage is only implied by
`Invoice.docUrl` / `InvoiceRepository.setDocUrl`, neither of which is ever
called. Previously removed as unused: `geolocator`, `flutter_map`, `latlong2`
(location is ETA + route-order only, no live GPS map).

---

## Firebase setup

**Web is already configured against a real Firebase project** — `lib/firebase_options.dart`
carries live values in its `web` block, and `DefaultFirebaseOptions.currentPlatform`
returns `web` when `kIsWeb`. So `flutter run -d chrome` boots to the **login
screen**, not the setup screen.

The `android` / `ios` / `macos` / `windows` blocks are still `REPLACE_ME`, but the
`android/` and `ios/` platform folders have been deleted from the repo, so this
only matters if mobile is revived (`flutterfire configure` regenerates the file).

`main.dart` gates on `options.projectId != 'REPLACE_ME'`; when that fails,
`firebaseReadyProvider` is false and the router pins every path to `/setup`.

### Seed the admin (no in-app admin signup)
1. **Authentication → Users → Add user**:
   - Email: `<your_admin_userid>@chai.app` (e.g. `admin@chai.app`)
   - Password: `<your_password>` (min 6 characters)
   - Copy the generated UID.
2. **Firestore → collection `users` → Add document**, Document ID = that UID:
   - `userId` (string) = `admin` (or your chosen alphanumeric User ID)
   - `name` (string) = `System Admin`
   - `phone` (string) = `9876543210`
   - `email` (string) = `admin@chai.app` (optional, for reference)
   - `role` (string) = `admin`
   - `status` (string) = `active`
   - `createdAt` (timestamp) = Current server timestamp
3. Sign in on the login page using:
   - User ID: `admin`
   - Password: `<your_password>`
   - Routed automatically to the admin console.

A **company** user additionally needs `companyId` on their `users/{uid}` doc —
it is the only link to their `companies/{id}` document, and every company screen
bails with "No company linked" without it.

---

## Project Structure

```
lib/
├── main.dart                       # Firebase init + gate, providers, daily auto-logout, light theme, web keyboard-overlay builder
├── firebase_options.dart           # web = REAL; android/ios = REPLACE_ME placeholders
├── core/
│   ├── models/                     # 8 models + models.dart barrel
│   │   ├── app_user.dart  company.dart  product.dart  item_request.dart
│   │   ├── payment.dart  invoice.dart  complaint.dart  app_notification.dart
│   ├── repositories/               # Firestore CRUD per collection (8)
│   │   ├── user_repository.dart  company_repository.dart  product_repository.dart
│   │   ├── request_repository.dart  payment_repository.dart
│   │   ├── complaint_repository.dart  notification_repository.dart
│   │   └── invoice_repository.dart          # read + generate/pay live
│   ├── services/
│   │   ├── auth_service.dart              # sign-in/out, user-doc stream, error messages
│   │   ├── session_service.dart           # daily auto-logout (date compare)
│   │   ├── credential_store.dart          # encrypted remember-me prefill
│   │   ├── user_provisioning_service.dart # create accounts via secondary Firebase app
│   │   ├── distribution_service.dart      # company sale (distributeGoods) + walk-in sale + portal writes
│   │   ├── firestore_refs.dart            # central collection refs
│   │   ├── invoice_service.dart           # generateForCompany — per-company billing page
│   │   ├── pdf_invoice_service.dart       # printOrShare — invoice PDF download
│   │   └── fcm_service.dart               # DEAD — initForUser never called
│   ├── providers/
│   │   ├── firebase_providers.dart        # firebase instances, prefs, ready-flag
│   │   ├── auth_providers.dart            # authState, appUser (role/status)
│   │   └── repository_providers.dart      # repos, services + all live stream providers
│   ├── theme/app_theme.dart               # M3 brand-orange seed + Inter + brand colour constants
│   └── utils/  router.dart  url_strategy{,_stub,_web}.dart
└── ui/
    ├── views/
    │   ├── auth/       login_view.dart  pending_view.dart
    │   ├── common/     loading_view.dart  setup_required_view.dart  notifications_view.dart
    │   ├── admin/      admin_dashboard_view.dart  admin_home_view.dart
    │   │               inventory_view.dart  offices_view.dart (companies)
    │   │               helpers_view.dart (employees)
    │   │               inbox_view.dart (app-bar icon → Requests | Complaints)
    │   │               requests_view.dart  complaints_view.dart
    │   │               company_detail_view.dart (per-company billing)
    │   ├── helper/     helper_dashboard_view.dart  helper_home_view.dart
    │   │               company_sale_screen.dart  walkin_sale_screen.dart
    │   │               helper_complaints_view.dart  item_picker_screen.dart
    │   └── office/     office_dashboard_view.dart  office_home_view.dart
    │                   office_requests_view.dart  office_subscription_view.dart (Bills)
    │                   office_complaints_view.dart  office_actions.dart
    └── widgets/  adaptive_nav_scaffold.dart  status_views.dart
                  complaint_dialog.dart  complaint_tile.dart  app_logo.dart

assets/          logo_no_bg.png / logo_white_bg.png   # 1024px committed sources
                 logo_full.png / logo_mark.png / logo_doc.png   # generated cuts
tool/            gen_logo_assets.py                   # regenerates the cuts
```

> **Naming note:** role folders are historical — `helper/` = **Employee**,
> `office/` = **Company**. The dashboards already show the correct labels
> ("Employee", "Company"); only the folder/class names lag. A rename is a
> low-priority cleanup task.

---

## Firestore collections

`users`, `companies`, `products`, `requests`, `payments`,
`invoices`, `complaints`, `notifications`. (The `routes` collection was removed
with the delivery-route feature.)

Key fields: `users.role/status/companyId`; `companies.approval`
(pending/approved/rejected), `companies.outstanding`, `companies.ownerUid`;
`requests.paymentMode` (`payNow`/`addToBill`) + `status`
(pending/approved/fulfilled/rejected); `payments.method` (cash/upi);
`invoices.month/lines/paid/status`. A **walk-in** sale writes a payment with an
empty `companyId` and `companyName` = the customer name (or `"Walk-in"`).

`notifications` are addressed by **either** `toUid` (a specific user) **or**
`toRole` (a broadcast, e.g. `"admin"`).

---

## Work Status

### Done — Foundation
- [x] Web app (path URLs, PWA manifest/branding), cross-platform kept open
- [x] Firebase init with placeholder gate + "not configured" setup screen
- [x] Single login page; role read from `users/{uid}` after sign-in
- [x] Role-based routing (setup / login / loading / pending / admin / employee / company)
- [x] Persistent session + **daily auto-logout** (startup & resume)
- [x] **Remember-me** prefill via encrypted secure storage
- [x] Data models + repositories + Riverpod providers for all 9 collections
- [x] Forced light theme

### Done — Admin console
- [x] Live dashboard stats (products, companies, employees) + pending banner
- [x] **Inbox as an app-bar icon** (badge = pending requests + open complaints)
- [x] Inventory: product CRUD (add/edit/delete, low-stock highlight)
- [x] Employees: create account (secondary-app provisioning), enable/disable
- [x] Companies: create (with optional login), **approval queue** (approve/reject)
- [x] **Per-company billing**: a bill icon on the company card opens a company
      detail page (details, outstanding, month generate/regenerate, invoices
      with PDF download + record-payment, payment history)
- [x] Notification bell **removed** (per the simplification)

### Done — Employee app
- [x] Home-first with two sale actions + "Collected today" + register-a-company
- [x] **Company sale**: pick an approved company → item picker locked to
      add-to-bill (no payment) → `distributeGoods(addToBill)` increments that
      company's outstanding ("subscription")
- [x] **Walk-in sale**: companyless, inline picker + cash/UPI → `recordWalkInSale`
      writes a payment (no outstanding, no invoice, no request)
- [x] Stock decremented on both sale paths
- [x] Register a company (writes a pending company + admin notification)
- [x] Complaints: list + raise
- [x] Notifications written to Firestore for key events

### Done — Company (client) portal  *(Phase 4 — was wrongly listed as TODO)*

All six screens are live against Firestore. There is **no dummy data anywhere
under `lib/ui/views/office/`** — the only literals are UI strings and formatters.

- [x] Live "today's delivery / assigned employee" card with **ETA + route order** (`companyAssignmentProvider`)
- [x] **Raise item request** (pay-now or add-to-bill) — `DistributionService.raiseCompanyRequest`
- [x] **Pay bill** (records payment, decrements outstanding) — `DistributionService.payByCompany`
- [x] Raise complaint + view own complaints
- [x] View notifications (bell + unread badge) — `NotificationBell`
- [x] Dummy `office_*` screens replaced with live data

### Done — Request lifecycle (Phase 7)

The company's primary action now has a receiving end at every step.

- [x] **Admin Inbox → Requests** (`requests_view.dart`): pending queue with
      approve / reject (the "awaiting delivery" section was removed 2026-09-07)
- [x] Approving notifies the company owner and flips the request to `approved`
- [x] **Employee route stop** surfaces that company's approved requests as a
      badge and a "Deliver approved request" action, opening the item picker
      **pre-filled** with the requested basket
- [x] Delivery calls `distributeGoods(requestId: …)`, which **closes out the
      existing request** rather than creating a second one — creating a new doc
      would bill the company twice at month end
- [x] Delivered quantities overwrite the requested ones, so a partial hand-over
      bills correctly
- [~] **Reworked 2026-09-07:** with the route feature gone, the employee no longer
      has a screen that delivers an approved request and closes it out
      (`distributeGoods(requestId:)`). The admin Inbox → Requests keeps the
      approve/deny queue (the obsolete "awaiting delivery" list was removed); the
      employee records the goods via a separate *company sale* — see
      [Known gaps](#known-gaps--todo).

### Done — Phase 5: monthly billing + documents

- [x] `InvoiceService.generateForCompany(company, month)` — aggregates
      `addToBill` + `fulfilled` requests into invoice lines and persists
- [x] **Generation upserts on (company, month)** — regenerating a month refreshes
      that bill instead of silently creating a duplicate
- [x] **Invoice-scoped settlement**: a bill's `paid` counts only payments
      carrying that invoice's id, so cash taken at the door never makes a
      monthly bill look part-paid
- [x] **Per-company billing** (`company_detail_view.dart`, opened from the bill
      icon on each company card): month selector, generate/regenerate, PDF
      download, record payment. The standalone `billing_view.dart` console and
      its "generate all" bulk action were removed 2026-09-07.
- [x] **Company Bills tab**: per-invoice Download and "Pay this bill"
- [x] `payBillFlow` threads `invoiceId` through to `payByCompany`, which updates
      the invoice's `paid`/`status` via `InvoiceRepository.applyPayment`
- [x] `PdfInvoiceService` renders the brand logo and the company name
- [ ] No Storage upload of the generated PDF (`Invoice.docUrl` is still null)

### Partly done — Phase 6: notifications

- [x] In-app notification centre (`notifications_view.dart`): merges `toUid` +
      `toRole` feeds, unread badge, tap-to-mark-read
- [x] Wired for the **employee + company** dashboards. The admin bell was
      **removed** 2026-09-07, so the `toRole: "admin"` feed is no longer surfaced
      to admins (they act on the app-bar Inbox + the pending-company banner)
- [ ] **FCM push is non-functional**: `fcm_service.dart` is never called, there is
      no `web/firebase-messaging-sw.js`, no Firebase JS SDK in `web/index.html`, and
      `_vapidKey` is an empty `String.fromEnvironment('FCM_VAPID_KEY')`

### Done — Branding

- [x] Logo everywhere: login, loading, setup, pending, all three app bars, the
      PDF invoice header, favicon, PWA icons (incl. maskable), and a pre-boot
      splash in `index.html`
- [x] `AppLogo.full` (lockup) / `AppLogo.mark` (cup only, for < 96px)
- [x] Theme reseeded from brand orange `#F06030`; `manifest.json` and
      `index.html` theme colours match
- [x] Renamed to **Indore Chai Company** across app, manifest, title and invoice
- [x] Status "pending" chips moved orange → amber, so status stays readable
      against brand-orange chrome

---

## Dead code inventory

Declared, compiled, shipped in the bundle — and never executed. This is the
single most misleading thing about the codebase: the files exist, so the
features *look* done.

| Symbol | Defined in | Consumed by |
| --- | --- | --- |
| `fcmServiceProvider` | `repository_providers.dart` | **nothing** |
| `ComplaintRepository.watchByCompany` | `complaint_repository.dart` | **no provider wraps it** (see gap 4) |
| `InvoiceRepository.setPaid` / `setDocUrl` | `invoice_repository.dart` | **nothing** — settlement goes through `applyPayment`; `setDocUrl` awaits Storage |
| `PaymentMethod.addedToBill` | `payment.dart` | **never written** — a payment is either cash or UPI |
| `DistributionService.collectPayment` / `takeRequest` | `distribution_service.dart` | **nothing** — their only caller was the deleted route screen (2026-09-07) |
| `distributeGoods(requestId:)` close-out branch | `distribution_service.dart` | **nothing passes `requestId`** since the route delivery screen was removed |
| `approvedRequestsForCompanyProvider` | `repository_providers.dart` | **nothing** — was the route stop's per-company "approved" badge |

Now live: `invoiceServiceProvider`, `pdfInvoiceServiceProvider`,
`pendingRequestsProvider`, `allComplaintsProvider`, and
`ComplaintTile.onStatusChange` / `showAuthor`. (`allInvoicesProvider` was
**deleted** 2026-09-07 with the standalone billing console.)

---

## Known gaps & TODO

Re-derived from the code, in priority order. The feature loop is closed, so
what is left is correctness, security and cleanup.

1. **Firestore security rules — still none.** This is now the single most
   important gap. The router guard stops a signed-in user from *navigating* to
   another role's console, but that is a client-side redirect, not
   authorisation: the database itself still accepts any authenticated read or
   write. Rules should key off `users/{uid}.role` and, for companies, scope
   reads to their own `companyId`.
2. **`DistributionService` multi-writes are not transactional** — `distributeGoods`,
   `recordWalkInSale` and `payByCompany` do their sub-writes (adjust-stock →
   record-payment/outstanding → notify) as sequential awaits, so a mid-flight
   failure leaves stock and balances desynced. Wants a Firestore
   `runTransaction` or a batched write.
3. **An approved request is not linked to the eventual sale** *(by design,
   2026-09-07)*. The company-request feature is **approve/deny only**: a request
   reaches the admin Inbox → Requests, the admin approves or rejects it, and the
   company is notified. There is no fulfilment step — the employee records the
   actual goods via a separate *company sale* (add-to-bill), which is not tied
   back to the request, so an approved request stays `approved` and is never
   auto-marked `fulfilled`. Wire the two together only if that linkage is wanted.
4. **`currentCompanyProvider`** — the `appUserProvider → companyId → companyByIdProvider`
   two-hop with a null-bail is copy-pasted across four office views, each with
   slightly different "no company linked" copy.
5. **Company complaints are uid-scoped, not company-scoped** — `office_complaints_view`
   uses `userComplaintsProvider(uid)`, so a company with two logins never sees its
   colleagues' complaints. `watchByCompany` already exists; it just needs a provider.
6. **FCM** — service worker, VAPID key, an `initForUser` call after login, and a
   sender (Cloud Function) are all missing.
7. **Tabs are not deep-linkable** — each dashboard is one flat route whose body is
   `_views[_selectedIndex]`, not an `IndexedStack`, so tab state and scroll
   offsets are lost on switch and on refresh.
8. **`office_actions.dart` imports `../helper/item_picker_screen.dart`** — cross-role
   layering smell; the picker should move to `ui/widgets/` or `ui/views/common/`.
9. **Employee "add company"** — the register-a-company dialog writes a pending
   company + admin notification; confirm it covers everything the brief's
   "employee submit" step needs.
10. **Storage upload of generated PDFs** — `Invoice.docUrl` / `setDocUrl` exist
    but nothing populates them; invoices are re-rendered on demand instead.
11. **Unused deps** — `fl_chart` and `firebase_storage` are still declared and
    never imported.
12. **Tests** — only `test/widget_test.dart` (setup-screen smoke test) exists.
    The invoice-generation rules (upsert, invoice-scoped `paid`) and the
    add-to-bill vs walk-in payment branches are the highest-value units to cover.
13. **Rename** `helper/`→`employee/`, `office/`→`company/` (folders and classes).

---

## Conventions

Follow these when adding screens; they are consistent across all existing views.

- **Widgets:** screens are `ConsumerWidget`; a screen gets `ConsumerStatefulWidget`
  only for local form/tab state. Dialogs with forms are separate
  `ConsumerStatefulWidget` classes at the bottom of the same file. There are **no**
  `AsyncNotifier` / `StateNotifier` classes anywhere.
- **Async triad:** `ref.watch(appUserProvider).value` null-guard →
  `asyncValue.when(loading: CircularProgressIndicator, error: ErrorStateView(message: '$e'), data: …)`
  → `.isEmpty` → `EmptyState(icon:, message:)`.
- **Writes:** always `ref.read(xProvider).method(...)` inside a
  `Future<void> _verb(BuildContext context, WidgetRef ref)`; never `ref.watch`.
- **Confirm dialogs** return `bool?` and are compared `== true`.
- **Feedback:** snackbars are the only success channel, short past-tense
  ("Route created"). Guard with `if (context.mounted)` / `if (mounted)`.
  Form errors go to a local `String? _error` → `errorText`, never a snackbar.
- **Currency:** a file-private
  `final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');`
  — the escape, never a literal ₹. Amount fields use `prefixText: '₹ '`.
- **Theme:** `Theme.of(context).textTheme.*` and `colorScheme.*` for structure;
  bare `Colors.<name>` + `withValues(alpha: 0.1/0.12/0.4)` for status semantics
  (green = done, **amber = pending**, blue = in-progress, red = rejected,
  grey = skipped; pending moved off orange when orange became the brand
  colour). Never `withOpacity`. Radii are hardcoded 12 (card) / 16 (stat
  tile) / 20 (hero); padding `EdgeInsets.all(16)`. There are no design tokens —
  `app_theme.dart` is 26 lines of M3 seed + Inter.
- **Chrome:** the three dashboards own `AdaptiveNavScaffold` (which supplies the
  `Scaffold` + `AppBar`); child screens add a bare inner `Scaffold` only to host a FAB.

---

## Requirements traceability (from the brief)

| Requirement                                                   | Status |
| ------------------------------------------------------------- | ------ |
| Firebase enabled, everything dynamic via Firestore            | Done (web config is live) |
| Single login page                                             | Done |
| Admin account created directly in DB                          | Done (seeding documented) |
| Admin creates employees and companies                         | Done |
| Employee can add company (needs admin approval)               | **Partial** — approval done; employee submit screen TODO |
| Cross-role access control                                     | **Partial** — router guard done; Firestore rules still absent |
| Persistent session + daily auto-logout on day change          | Done |
| Save id/pass prefilled on login                               | Done |
| Admin creates step-by-step route for employee                 | **Removed** — route feature dropped (simplification) |
| Company raises request (pay-on-delivery or add-to-bill)       | **Partial** — company raises + admin approves; no employee fulfilment step after route removal |
| Manage monthly bills + generate document                      | Done — per-company billing page + PDF download |
| Employee: record company sale (add-to-bill) + walk-in sale (cash/UPI) + complaint | Done — reworked; route-based collect/take-request removed |
| Company: request, complaint, pay bill, notifications          | Done — employee-ETA dropped with routes |

---

## Getting Started

```bash
flutter pub get
flutter run -d chrome      # web — boots to login, Firebase web config is live
flutter analyze            # clean (0 issues)
flutter test
```

---

## Changelog

### [Unreleased]

- **Simplification (2026-09-07) — delivery route removed.** Deleted the
  `DeliveryRoute` model + repository, the admin Routes builder, and the employee
  "My Route" screen, plus every route provider/ref and the `routes` collection.
- **Employee app reworked to Home-first, two sale actions.** *Company sale*
  (pick an approved company → add-to-bill, no payment) and *walk-in sale*
  (companyless, cash/UPI) via the new `recordWalkInSale`. Kept register-a-company
  + complaints; dropped the route-based deliver / collect / take-request flow.
- **Admin — Inbox moved to an app-bar icon** (badged with pending requests +
  complaints), **notification bell removed**, and **billing moved onto each
  company** (bill icon on the company card → new `company_detail_view.dart`).
  Admin nav went 7 → 4 destinations (resolves the old "cramped bottom bar" gap).
  The standalone `billing_view.dart`, its "generate all" action, and the
  now-unused `allInvoicesProvider` were deleted.
- **Requests inbox = approve/deny only.** Removed the obsolete "awaiting
  delivery" section from `requests_view.dart` (it referenced the deleted route
  delivery and would never clear) and the now-dead `approvedRequestsProvider`. A
  company request still lands in the app-bar Inbox → Requests for approve/reject.
- **Web keyboard fold fixed.** The app no longer folds / shrinks / distorts when
  the on-screen keyboard opens or closes: `web/index.html` now carries a viewport
  meta with `interactive-widget=overlays-content` (keyboard overlays instead of
  resizing the layout viewport) + `maximum-scale=1.0, user-scalable=no` (no iOS
  focus-zoom), and `main.dart`'s `MaterialApp.router` builder zeroes the bottom
  view-inset on web so no `Scaffold` resizes to the keyboard either.
- **Verified:** `flutter analyze` clean (0 issues) across the whole project.

- **Feature — request lifecycle closed.** Admin Inbox (Requests | Complaints)
  with approve/reject; approved requests surface on the employee's route stop
  pre-filled, and delivering one closes out that request instead of creating a
  duplicate.
- **Feature — billing wired.** Admin Billing screen (month selector, generate /
  regenerate / generate-all, PDF, record payment) and per-invoice Download +
  "Pay this bill" on the company Bills tab.
- **Fix — invoice correctness.** Generation now upserts on (company, month)
  instead of creating duplicates, and a bill's `paid` counts only payments
  tagged with that invoice's id, so cash-on-delivery no longer makes a monthly
  bill look part-paid.
- **Fix — cross-role router hole.** A signed-in user is now redirected off any
  role home that is not their own.
- **Feature — admin notification bell + complaints console**, consuming the
  `toRole: "admin"` feed and `allComplaintsProvider` that were already written.
- **Branding.** Logo applied across app, documents and web shell; theme reseeded
  from brand orange `#F06030`; renamed to Indore Chai Company; pending status
  chips moved to amber.
- **Fix:** `Table.fromTextArray` → `TableHelper.fromTextArray` (last analyze issue).

- **Docs:** audited the whole codebase against this file and corrected it.
  Phase 4 (Company portal) was implemented but still listed as dummy/TODO;
  Phases 5 and 6 have complete service layers that **no UI calls**. Added a
  dead-code inventory, a re-derived priority TODO list, and a conventions
  section. Recorded the cross-role router hole and the unused
  `fl_chart` / `firebase_storage` dependencies. **No code was changed.**
- **Fix:** route builder now loads approved companies (stops were un-addable).
- **Change:** forced light theme (`ThemeMode.light`).

### Phase 4 — Company portal *(was undocumented)*
- Six live screens under `lib/ui/views/office/`, company-scoped providers
  (`companyByIdProvider`, `companyRequestsProvider`, `companyPaymentsProvider`,
  `companyInvoicesProvider`, `companyAssignmentProvider`), and
  `DistributionService.raiseCompanyRequest` / `payByCompany`.
- In-app notification centre + `NotificationBell` (employee + company).

### Phase 5/6 groundwork — service layer only *(was undocumented)*
- `InvoiceService`, `PdfInvoiceService`, `FcmService`, `InvoiceRepository`.
  All unreferenced by any UI.

### Phase 3 — Employee field app
- Repos: request/payment/complaint/notification; `DistributionService`.
- Employee Home (live), My Route (step-by-step serving), Complaints; item picker.
- Stock/outstanding updates + event notifications.

### Phase 2 — Admin console
- Repositories + `UserProvisioningService` (secondary Firebase app).
- Inventory, Employees, Companies + approvals, Routes builder, live stats.

### Phase 1 — Foundation
- Firebase gate, single login, role routing, session + daily auto-logout,
  remember-me, models/providers for all collections.

### Web app conversion
- Path-based URLs, responsive nav rail/bottom bar, PWA branding.

### 1.0.0+1 — Initial upload
- Flutter scaffolding with hardcoded dummy dashboards (Admin/Helper/Office).
