import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing In...'**
  String get signingIn;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing Out...'**
  String get signingOut;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get access;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @residentProfile.
  ///
  /// In en, this message translates to:
  /// **'Resident Profile'**
  String get residentProfile;

  /// No description provided for @serviceRequest.
  ///
  /// In en, this message translates to:
  /// **'Service Request'**
  String get serviceRequest;

  /// No description provided for @serviceHistory.
  ///
  /// In en, this message translates to:
  /// **'Service History'**
  String get serviceHistory;

  /// No description provided for @createServiceRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Service Request'**
  String get createServiceRequest;

  /// No description provided for @viewServiceHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewServiceHistory;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe Issue'**
  String get describeIssue;

  /// No description provided for @problemTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem title'**
  String get problemTitle;

  /// No description provided for @problemDescription.
  ///
  /// In en, this message translates to:
  /// **'Problem description'**
  String get problemDescription;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @preferredScheduleNote.
  ///
  /// In en, this message translates to:
  /// **'Preferred schedule note'**
  String get preferredScheduleNote;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @todayHighlights.
  ///
  /// In en, this message translates to:
  /// **'Today Highlights'**
  String get todayHighlights;

  /// No description provided for @announcementCenter.
  ///
  /// In en, this message translates to:
  /// **'Announcement Center'**
  String get announcementCenter;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noDataAvailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. Try again.'**
  String get failedToLoad;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login cannot be empty.'**
  String get loginRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty.'**
  String get passwordRequired;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your account and password.'**
  String get loginFailed;

  /// No description provided for @secureAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Access'**
  String get secureAccessTitle;

  /// No description provided for @secureResidentAccess.
  ///
  /// In en, this message translates to:
  /// **'Secure resident access is protected and verified before the dashboard can be used.'**
  String get secureResidentAccess;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @residentIdentity.
  ///
  /// In en, this message translates to:
  /// **'Resident Identity'**
  String get residentIdentity;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language.'**
  String get chooseLanguage;

  /// No description provided for @loadingAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Loading announcements...'**
  String get loadingAnnouncements;

  /// No description provided for @noAnnouncementsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No announcements available yet.'**
  String get noAnnouncementsAvailable;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @viewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Detail'**
  String get viewDetail;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @residenceSummary.
  ///
  /// In en, this message translates to:
  /// **'Residence Summary'**
  String get residenceSummary;

  /// No description provided for @latestAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Latest Announcements'**
  String get latestAnnouncements;

  /// No description provided for @visitor.
  ///
  /// In en, this message translates to:
  /// **'Visitor'**
  String get visitor;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @tower.
  ///
  /// In en, this message translates to:
  /// **'Tower'**
  String get tower;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @residentType.
  ///
  /// In en, this message translates to:
  /// **'Resident Type'**
  String get residentType;

  /// No description provided for @contractEnd.
  ///
  /// In en, this message translates to:
  /// **'Contract End'**
  String get contractEnd;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Your Current Balance'**
  String get currentBalance;

  /// No description provided for @openBilling.
  ///
  /// In en, this message translates to:
  /// **'Open Billing'**
  String get openBilling;

  /// No description provided for @monthlyBillingStatus.
  ///
  /// In en, this message translates to:
  /// **'Monthly billing status'**
  String get monthlyBillingStatus;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @visitorAccess.
  ///
  /// In en, this message translates to:
  /// **'Visitor Access'**
  String get visitorAccess;

  /// No description provided for @visitorAccessSection.
  ///
  /// In en, this message translates to:
  /// **'Visitor Access'**
  String get visitorAccessSection;

  /// No description provided for @registerVisitor.
  ///
  /// In en, this message translates to:
  /// **'Register Visitor'**
  String get registerVisitor;

  /// No description provided for @visitorHistory.
  ///
  /// In en, this message translates to:
  /// **'Visitor History'**
  String get visitorHistory;

  /// No description provided for @accessInformation.
  ///
  /// In en, this message translates to:
  /// **'Access Information'**
  String get accessInformation;

  /// No description provided for @visitorQrPass.
  ///
  /// In en, this message translates to:
  /// **'Visitor QR Pass'**
  String get visitorQrPass;

  /// No description provided for @visitorManagement.
  ///
  /// In en, this message translates to:
  /// **'Visitor Management'**
  String get visitorManagement;

  /// No description provided for @visitorName.
  ///
  /// In en, this message translates to:
  /// **'Visitor Name'**
  String get visitorName;

  /// No description provided for @visitorFullName.
  ///
  /// In en, this message translates to:
  /// **'Visitor full name'**
  String get visitorFullName;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @purposeOfVisit.
  ///
  /// In en, this message translates to:
  /// **'Purpose of Visit'**
  String get purposeOfVisit;

  /// No description provided for @numberOfVisitors.
  ///
  /// In en, this message translates to:
  /// **'Number of Visitors'**
  String get numberOfVisitors;

  /// No description provided for @vehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get vehicleNumber;

  /// No description provided for @vehicleNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number (Optional)'**
  String get vehicleNumberOptional;

  /// No description provided for @scheduleVisit.
  ///
  /// In en, this message translates to:
  /// **'Schedule Visit'**
  String get scheduleVisit;

  /// No description provided for @visitTime.
  ///
  /// In en, this message translates to:
  /// **'Visit Time'**
  String get visitTime;

  /// No description provided for @expectedDuration.
  ///
  /// In en, this message translates to:
  /// **'Expected Duration'**
  String get expectedDuration;

  /// No description provided for @passGenerated.
  ///
  /// In en, this message translates to:
  /// **'PASS GENERATED'**
  String get passGenerated;

  /// No description provided for @visitorId.
  ///
  /// In en, this message translates to:
  /// **'Visitor ID'**
  String get visitorId;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @shareQr.
  ///
  /// In en, this message translates to:
  /// **'Share QR'**
  String get shareQr;

  /// No description provided for @shareVisitorPass.
  ///
  /// In en, this message translates to:
  /// **'Share Visitor Pass'**
  String get shareVisitorPass;

  /// No description provided for @continueToVerification.
  ///
  /// In en, this message translates to:
  /// **'Continue to Verification'**
  String get continueToVerification;

  /// No description provided for @accessApproved.
  ///
  /// In en, this message translates to:
  /// **'Access Approved'**
  String get accessApproved;

  /// No description provided for @checkInSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Check-In Successful'**
  String get checkInSuccessful;

  /// No description provided for @checkInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-In Time'**
  String get checkInTime;

  /// No description provided for @downloadHistory.
  ///
  /// In en, this message translates to:
  /// **'Download History'**
  String get downloadHistory;

  /// No description provided for @backToAccessHub.
  ///
  /// In en, this message translates to:
  /// **'Back to Access Hub'**
  String get backToAccessHub;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// No description provided for @browsePhoto.
  ///
  /// In en, this message translates to:
  /// **'Browse a photo from File Explorer'**
  String get browsePhoto;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture a new issue photo'**
  String get capturePhoto;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @chooseExistingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing photo'**
  String get chooseExistingPhoto;

  /// No description provided for @continueToDescription.
  ///
  /// In en, this message translates to:
  /// **'Continue to Description'**
  String get continueToDescription;

  /// No description provided for @estimatedSla.
  ///
  /// In en, this message translates to:
  /// **'Estimated SLA'**
  String get estimatedSla;

  /// No description provided for @serviceOptions.
  ///
  /// In en, this message translates to:
  /// **'service options'**
  String get serviceOptions;

  /// No description provided for @trackingDetail.
  ///
  /// In en, this message translates to:
  /// **'Tracking Detail'**
  String get trackingDetail;

  /// No description provided for @realTimeTicketInfo.
  ///
  /// In en, this message translates to:
  /// **'Real-time status and service ticket information.'**
  String get realTimeTicketInfo;

  /// No description provided for @backToServices.
  ///
  /// In en, this message translates to:
  /// **'Back to Services'**
  String get backToServices;

  /// No description provided for @noServiceRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No service requests found for this filter.'**
  String get noServiceRequestsFound;

  /// No description provided for @loadingServiceCatalog.
  ///
  /// In en, this message translates to:
  /// **'Loading service catalog...'**
  String get loadingServiceCatalog;

  /// No description provided for @loadingServiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading service history...'**
  String get loadingServiceHistory;

  /// No description provided for @technicalServices.
  ///
  /// In en, this message translates to:
  /// **'Technical Services'**
  String get technicalServices;

  /// No description provided for @serviceInformation.
  ///
  /// In en, this message translates to:
  /// **'Service Information'**
  String get serviceInformation;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @affectedArea.
  ///
  /// In en, this message translates to:
  /// **'Affected area'**
  String get affectedArea;

  /// No description provided for @managementOffice.
  ///
  /// In en, this message translates to:
  /// **'Management Office'**
  String get managementOffice;

  /// No description provided for @allResidents.
  ///
  /// In en, this message translates to:
  /// **'All residents'**
  String get allResidents;

  /// No description provided for @totalAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Total Announcements'**
  String get totalAnnouncements;

  /// No description provided for @importantAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Important Announcements'**
  String get importantAnnouncements;

  /// No description provided for @filterAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Filter Announcements'**
  String get filterAnnouncements;

  /// No description provided for @newestAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Newest Announcements'**
  String get newestAnnouncements;

  /// No description provided for @residentId.
  ///
  /// In en, this message translates to:
  /// **'Resident ID'**
  String get residentId;

  /// No description provided for @residence.
  ///
  /// In en, this message translates to:
  /// **'Residence'**
  String get residence;

  /// No description provided for @towerAndFloor.
  ///
  /// In en, this message translates to:
  /// **'Tower & Floor'**
  String get towerAndFloor;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @profileStatus.
  ///
  /// In en, this message translates to:
  /// **'Profile Status'**
  String get profileStatus;

  /// No description provided for @linked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get linked;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @simulatedForDemo.
  ///
  /// In en, this message translates to:
  /// **'is simulated for demo.'**
  String get simulatedForDemo;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @serviceCharge.
  ///
  /// In en, this message translates to:
  /// **'Service Charge'**
  String get serviceCharge;

  /// No description provided for @facilityMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Facility Maintenance'**
  String get facilityMaintenance;

  /// No description provided for @dueInSixDays.
  ///
  /// In en, this message translates to:
  /// **'Due in 6 days'**
  String get dueInSixDays;

  /// No description provided for @payThisMonthInvoice.
  ///
  /// In en, this message translates to:
  /// **'Pay this month invoice'**
  String get payThisMonthInvoice;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get addAttachment;

  /// No description provided for @choosePhotoComputer.
  ///
  /// In en, this message translates to:
  /// **'Choose an existing photo from your computer.'**
  String get choosePhotoComputer;

  /// No description provided for @choosePhotoSource.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo source for your service request.'**
  String get choosePhotoSource;

  /// No description provided for @maxPhotoAttachments.
  ///
  /// In en, this message translates to:
  /// **'Maximum 3 photo attachments per request.'**
  String get maxPhotoAttachments;

  /// No description provided for @photoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo could not be selected. Try again.'**
  String get photoPickFailed;

  /// No description provided for @whatServiceNeeded.
  ///
  /// In en, this message translates to:
  /// **'What type of service do you need?'**
  String get whatServiceNeeded;

  /// No description provided for @chooseSpecificService.
  ///
  /// In en, this message translates to:
  /// **'Choose a specific service option'**
  String get chooseSpecificService;

  /// No description provided for @describeIssueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide issue details, a preferred schedule note, and supporting photos.'**
  String get describeIssueSubtitle;

  /// No description provided for @scheduleAutomaticTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule is set automatically'**
  String get scheduleAutomaticTitle;

  /// No description provided for @scheduleAutomaticBody.
  ///
  /// In en, this message translates to:
  /// **'Visit date and service time are arranged by management/backend, so residents only need to add notes if there is a preferred timing request.'**
  String get scheduleAutomaticBody;

  /// No description provided for @optionalPhotosDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional photos to help the service team understand the issue faster.'**
  String get optionalPhotosDescription;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @ticketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket Created!'**
  String get ticketCreated;

  /// No description provided for @ticketSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your service request has been submitted successfully.'**
  String get ticketSubmittedSuccess;

  /// No description provided for @ticketNumber.
  ///
  /// In en, this message translates to:
  /// **'Ticket Number'**
  String get ticketNumber;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategory;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned To'**
  String get assignedTo;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @operationalTime.
  ///
  /// In en, this message translates to:
  /// **'Operational Time'**
  String get operationalTime;

  /// No description provided for @slaDue.
  ///
  /// In en, this message translates to:
  /// **'SLA Due'**
  String get slaDue;

  /// No description provided for @slaState.
  ///
  /// In en, this message translates to:
  /// **'SLA State'**
  String get slaState;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get completedAt;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @noTimelineUpdates.
  ///
  /// In en, this message translates to:
  /// **'No timeline updates available yet.'**
  String get noTimelineUpdates;

  /// No description provided for @slaNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'SLA not available'**
  String get slaNotAvailable;

  /// No description provided for @ticketDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ticket detail is not available. Try opening it from history.'**
  String get ticketDetailUnavailable;

  /// No description provided for @serviceRequestUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Service request is not available. Try submitting again.'**
  String get serviceRequestUnavailable;

  /// No description provided for @serviceDesk.
  ///
  /// In en, this message translates to:
  /// **'Resident Service Desk'**
  String get serviceDesk;

  /// No description provided for @serviceDeskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage repair reports and monitor technician progress.'**
  String get serviceDeskSubtitle;

  /// No description provided for @serviceHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report your unit repair needs quickly.'**
  String get serviceHeroSubtitle;

  /// No description provided for @serviceRequestCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit maintenance, electricity, water, and cleaning issues.'**
  String get serviceRequestCardSubtitle;

  /// No description provided for @serviceHistoryCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track report status from process to completion.'**
  String get serviceHistoryCardSubtitle;

  /// No description provided for @handlingFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Handling Flow'**
  String get handlingFlowTitle;

  /// No description provided for @handlingFlowBody.
  ///
  /// In en, this message translates to:
  /// **'After a report is submitted, management verifies it, assigns a technician, and updates the work status until completion.'**
  String get handlingFlowBody;

  /// No description provided for @communityHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest information and updates from management.'**
  String get communityHeroSubtitle;

  /// No description provided for @managementAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Management Announcement'**
  String get managementAnnouncement;

  /// No description provided for @managementUpdate.
  ///
  /// In en, this message translates to:
  /// **'Management update'**
  String get managementUpdate;

  /// No description provided for @syncAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Syncing the latest information from management.'**
  String get syncAnnouncements;

  /// No description provided for @loadingLatestDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading latest details...'**
  String get loadingLatestDetails;

  /// No description provided for @recentlyPublished.
  ///
  /// In en, this message translates to:
  /// **'Recently published'**
  String get recentlyPublished;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @announcementPreviewFallback.
  ///
  /// In en, this message translates to:
  /// **'Latest update from the management office is available to review.'**
  String get announcementPreviewFallback;

  /// No description provided for @managementFollowInfo.
  ///
  /// In en, this message translates to:
  /// **'Please follow the latest information from management office.'**
  String get managementFollowInfo;

  /// No description provided for @attachmentPreview.
  ///
  /// In en, this message translates to:
  /// **'Attachment Preview'**
  String get attachmentPreview;

  /// No description provided for @previewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get previewUnavailable;

  /// No description provided for @imageAttachment.
  ///
  /// In en, this message translates to:
  /// **'Image Attachment'**
  String get imageAttachment;

  /// No description provided for @attachmentFile.
  ///
  /// In en, this message translates to:
  /// **'Attachment File'**
  String get attachmentFile;

  /// No description provided for @fileAttachment.
  ///
  /// In en, this message translates to:
  /// **'File attachment'**
  String get fileAttachment;

  /// No description provided for @noAttachmentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No attachments available.'**
  String get noAttachmentsAvailable;

  /// No description provided for @noFileAttachments.
  ///
  /// In en, this message translates to:
  /// **'No file attachments'**
  String get noFileAttachments;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total outstanding'**
  String get totalOutstanding;

  /// No description provided for @billingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track dues, installment timelines, and premium building services.'**
  String get billingSubtitle;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @visitorEnteredResidence.
  ///
  /// In en, this message translates to:
  /// **'Visitor has entered the residence.'**
  String get visitorEnteredResidence;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @visitorHistoryDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Visitor history downloaded'**
  String get visitorHistoryDownloaded;

  /// No description provided for @trackVisitorActivity.
  ///
  /// In en, this message translates to:
  /// **'Track all visitor activity and check-in records.'**
  String get trackVisitorActivity;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @pendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSync;

  /// No description provided for @residentAccount.
  ///
  /// In en, this message translates to:
  /// **'Resident Account'**
  String get residentAccount;

  /// No description provided for @assignedAfterActivation.
  ///
  /// In en, this message translates to:
  /// **'Assigned after activation'**
  String get assignedAfterActivation;

  /// No description provided for @informationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Information unavailable'**
  String get informationUnavailable;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @emailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Building alerts, visitor pass, service updates'**
  String get emailUpdates;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility and contact preferences'**
  String get privacySubtitle;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Concierge support and resident assistance'**
  String get helpCenterSubtitle;

  /// No description provided for @retryAnnouncementsHint.
  ///
  /// In en, this message translates to:
  /// **'Please try again to load the latest announcements.'**
  String get retryAnnouncementsHint;

  /// No description provided for @announcementsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Latest information from management will appear on this page.'**
  String get announcementsEmptyHint;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodNight;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
