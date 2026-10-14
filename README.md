# Indore Chai Company — Distribution Management

A Flutter **web-first** (mobile-ready) app for a tea/chai **distribution**
business, backed by **Firebase** (Auth + Firestore). One login serves three
roles: **Admin**, **Employee**, and **Company (client)**.

- Admin manages products, employees, companies, approvals and step-by-step routes.
- Employees serve routes: distribute goods, collect payments, take requests, raise complaints.
- Companies raise requests, pay bills, raise complaints, and see notifications + employee ETA.

## Status

All three role apps — Admin console, Employee field app and the Company portal —
are built and wired to live Firestore, and the **functional loop is closed**:

> company raises a request → admin approves it → the employee delivers it on
> their route → it lands on that month's bill → the company downloads the PDF
> and pays it → the invoice settles.

Push notifications (`FcmService`) remain **written but unreachable** — there is
no web service worker and no VAPID key. In-app notifications work for all three
roles.

The most useful next steps are **Firestore security rules** (there are none, so
the database accepts any authenticated read or write regardless of role) and
making `DistributionService`'s multi-document writes transactional.

See **[PROJECT.md](PROJECT.md)** for the full architecture, Firebase setup,
admin-seeding steps, a dead-code inventory, and the prioritised TODO list.

## Run

```bash
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

Firebase **web** is already configured against a live project, so the app boots
straight to the login screen. The android/iOS option blocks are still
placeholders; if mobile is revived, run `flutterfire configure`
(see PROJECT.md for details).
