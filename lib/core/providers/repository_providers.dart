import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/company.dart';
import '../models/complaint.dart';
import '../models/invoice.dart';
import '../models/item_request.dart';
import '../models/master_data.dart';
import '../models/payment.dart';
import '../models/payment_request.dart';
import '../models/product.dart';
import '../repositories/company_repository.dart';
import '../repositories/complaint_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/master_data_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/payment_request_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/request_repository.dart';
import '../repositories/user_repository.dart';
import '../services/distribution_service.dart';
import '../services/invoice_service.dart';
import '../services/pdf_invoice_service.dart';
import '../services/user_provisioning_service.dart';
import 'supabase_providers.dart';

// --- Repositories ----------------------------------------------------------

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(supabaseClientProvider)),
);

final companyRepositoryProvider = Provider<CompanyRepository>(
  (ref) => CompanyRepository(ref.watch(supabaseClientProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(supabaseClientProvider)),
);

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => RequestRepository(ref.watch(supabaseClientProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(supabaseClientProvider)),
);

final complaintRepositoryProvider = Provider<ComplaintRepository>(
  (ref) => ComplaintRepository(ref.watch(supabaseClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(supabaseClientProvider)),
);

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepository(ref.watch(supabaseClientProvider)),
);

final masterDataRepositoryProvider = Provider<MasterDataRepository>(
  (ref) => MasterDataRepository(ref.watch(supabaseClientProvider)),
);

final paymentRequestRepositoryProvider = Provider<PaymentRequestRepository>(
  (ref) => PaymentRequestRepository(ref.watch(supabaseClientProvider)),
);

final userProvisioningProvider = Provider<UserProvisioningService>(
  (ref) => UserProvisioningService(ref.watch(supabaseClientProvider)),
);

final distributionServiceProvider = Provider<DistributionService>(
  (ref) => DistributionService(
    companies: ref.watch(companyRepositoryProvider),
    products: ref.watch(productRepositoryProvider),
    requests: ref.watch(requestRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
    complaints: ref.watch(complaintRepositoryProvider),
    notifications: ref.watch(notificationRepositoryProvider),
    invoices: ref.watch(invoiceRepositoryProvider),
  ),
);

final invoiceServiceProvider = Provider<InvoiceService>(
  (ref) => InvoiceService(
    requests: ref.watch(requestRepositoryProvider),
    payments: ref.watch(paymentRepositoryProvider),
    invoices: ref.watch(invoiceRepositoryProvider),
  ),
);

final pdfInvoiceServiceProvider = Provider<PdfInvoiceService>(
  (ref) => PdfInvoiceService(),
);

// --- Live collection streams ----------------------------------------------

final employeesProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(userRepositoryProvider).watchEmployees(),
);

final companiesProvider = StreamProvider.autoDispose<List<Company>>(
  (ref) => ref.watch(companyRepositoryProvider).watchAll(),
);

final approvedCompaniesProvider = StreamProvider.autoDispose<List<Company>>(
  (ref) => ref.watch(companyRepositoryProvider).watchApproved(),
);

final pendingCompaniesProvider = StreamProvider.autoDispose<List<Company>>(
  (ref) => ref.watch(companyRepositoryProvider).watchPending(),
);

final productsProvider = StreamProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);

final masterCategoriesProvider =
    StreamProvider.autoDispose<List<MasterCategory>>(
  (ref) => ref.watch(masterDataRepositoryProvider).watchCategories(),
);

final masterUnitsProvider = StreamProvider.autoDispose<List<MasterUnit>>(
  (ref) => ref.watch(masterDataRepositoryProvider).watchUnits(),
);

/// Payments collected by a specific employee.
final employeePaymentsProvider =
    StreamProvider.autoDispose.family<List<Payment>, dynamic>(
  (ref, employeeId) =>
      ref.watch(paymentRepositoryProvider).watchByEmployee(employeeId),
);

/// Requests recorded by a specific employee.
final employeeRequestsProvider =
    StreamProvider.autoDispose.family<List<ItemRequest>, dynamic>(
  (ref, employeeId) =>
      ref.watch(requestRepositoryProvider).watchByEmployee(employeeId),
);

/// Complaints raised by a specific user (employee or company).
final userComplaintsProvider =
    StreamProvider.autoDispose.family<List<Complaint>, dynamic>(
  (ref, uid) => ref.watch(complaintRepositoryProvider).watchByUser(uid),
);

/// All pending item requests (admin review queue).
final pendingRequestsProvider = StreamProvider.autoDispose<List<ItemRequest>>(
  (ref) => ref.watch(requestRepositoryProvider).watchPending(),
);

/// All processed/resolved item requests (fulfilled or rejected history).
final processedRequestsProvider = StreamProvider.autoDispose<List<ItemRequest>>(
  (ref) => ref.watch(requestRepositoryProvider).watchProcessed(),
);

/// A single company's approved requests, for the employee's route stop.
final approvedRequestsForCompanyProvider =
    StreamProvider.autoDispose.family<List<ItemRequest>, dynamic>(
  (ref, companyId) =>
      ref.watch(requestRepositoryProvider).watchApprovedByCompany(companyId),
);

/// All complaints (admin overview).
final allComplaintsProvider = StreamProvider.autoDispose<List<Complaint>>(
  (ref) => ref.watch(complaintRepositoryProvider).watchAll(),
);

// --- Company-scoped streams (client portal) --------------------------------

final companyByIdProvider =
    StreamProvider.autoDispose.family<Company?, dynamic>(
  (ref, companyId) => ref.watch(companyRepositoryProvider).watchById(companyId),
);

final companyRequestsProvider =
    StreamProvider.autoDispose.family<List<ItemRequest>, dynamic>(
  (ref, companyId) =>
      ref.watch(requestRepositoryProvider).watchByCompany(companyId),
);

final companyPaymentsProvider =
    StreamProvider.autoDispose.family<List<Payment>, dynamic>(
  (ref, companyId) =>
      ref.watch(paymentRepositoryProvider).watchByCompany(companyId),
);

final companyInvoicesProvider =
    StreamProvider.autoDispose.family<List<Invoice>, dynamic>(
  (ref, companyId) =>
      ref.watch(invoiceRepositoryProvider).watchByCompany(companyId),
);

// --- Notifications ---------------------------------------------------------

final userNotificationsProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, dynamic>(
  (ref, uid) => ref.watch(notificationRepositoryProvider).watchForUser(uid),
);

final roleNotificationsProvider =
    StreamProvider.autoDispose.family<List<AppNotification>, String>(
  (ref, role) => ref.watch(notificationRepositoryProvider).watchForRole(role),
);

// --- Payment Requests & UPI ------------------------------------------------

final pendingPaymentRequestForCompanyProvider =
    StreamProvider.autoDispose.family<List<PaymentRequest>, dynamic>(
  (ref, companyId) => ref
      .watch(paymentRequestRepositoryProvider)
      .watchPendingForCompany(companyId),
);

final companyPaymentRequestsProvider =
    StreamProvider.autoDispose.family<List<PaymentRequest>, dynamic>(
  (ref, companyId) =>
      ref.watch(paymentRequestRepositoryProvider).watchByCompany(companyId),
);

final adminUpiConfigProvider = StreamProvider.autoDispose<AdminUpiConfig>(
  (ref) => ref.watch(masterDataRepositoryProvider).watchUpiConfig(),
);
