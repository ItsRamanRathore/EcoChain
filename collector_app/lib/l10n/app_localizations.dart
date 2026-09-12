import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'e-Mulya Collector'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @newLot.
  ///
  /// In en, this message translates to:
  /// **'New Lot'**
  String get newLot;

  /// No description provided for @handover.
  ///
  /// In en, this message translates to:
  /// **'Handover'**
  String get handover;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get navPrices;

  /// No description provided for @navRecyclers.
  ///
  /// In en, this message translates to:
  /// **'Recyclers'**
  String get navRecyclers;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get navScan;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @priceBoard.
  ///
  /// In en, this message translates to:
  /// **'Price Board'**
  String get priceBoard;

  /// No description provided for @recyclersList.
  ///
  /// In en, this message translates to:
  /// **'Find Recyclers'**
  String get recyclersList;

  /// No description provided for @profileTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get profileTransactions;

  /// No description provided for @profileEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get profileEarnings;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get profileJoined;

  /// No description provided for @lotNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Handover Lot'**
  String get lotNewTitle;

  /// No description provided for @lotTakephoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the E-Waste lot'**
  String get lotTakephoto;

  /// No description provided for @lotCaptureBtn.
  ///
  /// In en, this message translates to:
  /// **'Capture Photo'**
  String get lotCaptureBtn;

  /// No description provided for @lotConfirmCat.
  ///
  /// In en, this message translates to:
  /// **'Confirm or Select Category'**
  String get lotConfirmCat;

  /// No description provided for @lotChooseCat.
  ///
  /// In en, this message translates to:
  /// **'Choose the category that best matches your item'**
  String get lotChooseCat;

  /// No description provided for @lotNextWeight.
  ///
  /// In en, this message translates to:
  /// **'Next: Enter Weight'**
  String get lotNextWeight;

  /// No description provided for @lotHearEstimate.
  ///
  /// In en, this message translates to:
  /// **'Hear Estimate'**
  String get lotHearEstimate;

  /// No description provided for @lotReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get lotReview;

  /// No description provided for @lotSummary.
  ///
  /// In en, this message translates to:
  /// **'Lot Summary'**
  String get lotSummary;

  /// No description provided for @lotCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get lotCategory;

  /// No description provided for @lotWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get lotWeight;

  /// No description provided for @lotSaveFinish.
  ///
  /// In en, this message translates to:
  /// **'Save & Finish'**
  String get lotSaveFinish;
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
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
