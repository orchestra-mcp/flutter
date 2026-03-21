import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'Orchestra'**
  String get appName;

  /// Confirmation button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Cancel action button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save action button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete action button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit action button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Close action button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Back navigation button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next navigation button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Done action button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Generic loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// Retry action button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Search label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Pin item action
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// Unpin item action
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// Copy action button
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Share action button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Rename action button
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Select action button
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Export action button
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Confirm action button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Affirmative response
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Negative response
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Marks a field as optional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// Log in action label
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// Register action label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Forgot password link label
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Reset password action label
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Divider text between login form and OAuth buttons
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// Sign in button label
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Create account action label
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Magic link login option label
  ///
  /// In en, this message translates to:
  /// **'Magic Link Login'**
  String get magicLogin;

  /// Passkey authentication option label
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get passkey;

  /// Two-factor authentication label
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactor;

  /// Social sign-in option label
  ///
  /// In en, this message translates to:
  /// **'Sign in with Social Account'**
  String get socialSignIn;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// Prompt for users without an account
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t have an account?'**
  String get dontHaveAccount;

  /// Prompt for users who already have an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Option to sign in without a password
  ///
  /// In en, this message translates to:
  /// **'Sign in without password'**
  String get signInWithoutPassword;

  /// Option to sign in using a passkey
  ///
  /// In en, this message translates to:
  /// **'Sign in with Passkey'**
  String get signInWithPasskey;

  /// Button to send a magic login link
  ///
  /// In en, this message translates to:
  /// **'Send Magic Link'**
  String get sendMagicLink;

  /// Button to send a password reset link
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Instruction to check email after sending a link
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmail;

  /// Resend action button
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// One-time password code field label
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// Error message for invalid login credentials
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// Validation error for missing email
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Validation error for missing password
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Validation error when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// Validation error for password that is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Profile settings section title
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// Team settings section title
  ///
  /// In en, this message translates to:
  /// **'Team Settings'**
  String get teamSettings;

  /// Appearance settings section title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Security settings section title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Notification settings section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettings;

  /// About section label
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Change password action label
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Two-factor authentication settings label
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// Passkeys settings label
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get passkeys;

  /// Add passkey action label
  ///
  /// In en, this message translates to:
  /// **'Add Passkey'**
  String get addPasskey;

  /// Remove passkey action label
  ///
  /// In en, this message translates to:
  /// **'Remove Passkey'**
  String get removePasskey;

  /// Sign out action label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Sign out confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Help section label
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Privacy policy label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy;

  /// Report issue action label
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get reportIssue;

  /// Issue history section label
  ///
  /// In en, this message translates to:
  /// **'Issue History'**
  String get issueHistory;

  /// Orchestrator settings section label
  ///
  /// In en, this message translates to:
  /// **'Orchestrator'**
  String get orchestrator;

  /// DevTools navigation label
  ///
  /// In en, this message translates to:
  /// **'DevTools'**
  String get devtools;

  /// Terminal settings label
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// Workspaces settings label
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaces;

  /// Auto-start on login setting label
  ///
  /// In en, this message translates to:
  /// **'Auto Start'**
  String get autoStart;

  /// Default shell setting label
  ///
  /// In en, this message translates to:
  /// **'Default Shell'**
  String get defaultShell;

  /// Orchestrator binary path setting label
  ///
  /// In en, this message translates to:
  /// **'Orchestrator Path'**
  String get orchestratorPath;

  /// MCP server port setting label
  ///
  /// In en, this message translates to:
  /// **'MCP Port'**
  String get mcpPort;

  /// Log level setting label
  ///
  /// In en, this message translates to:
  /// **'Log Level'**
  String get logLevel;

  /// Reset all settings to defaults action
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// Projects section title
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// Create new project action label
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// Project name field label
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// Project description field label
  ///
  /// In en, this message translates to:
  /// **'Project Description'**
  String get projectDescription;

  /// Project status field label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectStatus;

  /// Features section label
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// Plans section label
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get plans;

  /// Requests section label
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// Persons / team members section label
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get persons;

  /// Project file tree label
  ///
  /// In en, this message translates to:
  /// **'Project Tree'**
  String get projectTree;

  /// Active projects list label
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get activeProjects;

  /// Archived projects list label
  ///
  /// In en, this message translates to:
  /// **'Archived Projects'**
  String get archivedProjects;

  /// Notes section title
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Agents section title
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// Skills section title
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// Workflows section title
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get workflows;

  /// Documentation section title
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get docs;

  /// Delegations section title
  ///
  /// In en, this message translates to:
  /// **'Delegations'**
  String get delegations;

  /// Sessions section title
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// Create new note action label
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// Create new agent action label
  ///
  /// In en, this message translates to:
  /// **'New Agent'**
  String get newAgent;

  /// Create new workflow action label
  ///
  /// In en, this message translates to:
  /// **'New Workflow'**
  String get newWorkflow;

  /// Pinned items section label
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// Recent items section label
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// Health section title
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// Overall health score label
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// Vitals section label
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// Daily flow / schedule label
  ///
  /// In en, this message translates to:
  /// **'Daily Flow'**
  String get dailyFlow;

  /// Hydration tracking label
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// Caffeine tracking label
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get caffeine;

  /// Nutrition tracking label
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// Pomodoro timer label
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get pomodoro;

  /// Daily shutdown routine label
  ///
  /// In en, this message translates to:
  /// **'Shutdown Routine'**
  String get shutdown;

  /// Weight tracking label
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Sleep tracking label
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// Add water intake action label
  ///
  /// In en, this message translates to:
  /// **'Add Water'**
  String get addWater;

  /// Add meal action label
  ///
  /// In en, this message translates to:
  /// **'Add Meal'**
  String get addMeal;

  /// Add caffeine intake action label
  ///
  /// In en, this message translates to:
  /// **'Add Caffeine'**
  String get addCaffeine;

  /// Log weight action label
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get logWeight;

  /// Goal label for health tracking
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// Amount consumed label
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get consumed;

  /// Amount remaining label
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// Cortisol level label
  ///
  /// In en, this message translates to:
  /// **'Cortisol'**
  String get cortisol;

  /// Cortisol safe window label
  ///
  /// In en, this message translates to:
  /// **'Cortisol Window'**
  String get cortisolWindow;

  /// Health safety score label
  ///
  /// In en, this message translates to:
  /// **'Safety Score'**
  String get safetyScore;

  /// Health flare risk indicator label
  ///
  /// In en, this message translates to:
  /// **'Flare Risk'**
  String get flareRisk;

  /// Recommended shutdown time window label
  ///
  /// In en, this message translates to:
  /// **'Shutdown Window'**
  String get shutdownWindow;

  /// Bedtime label
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtime;

  /// Recommended work time window label
  ///
  /// In en, this message translates to:
  /// **'Work Window'**
  String get workWindow;

  /// Step count label
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// Energy level label
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// Heart rate label
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// Metabolic age label
  ///
  /// In en, this message translates to:
  /// **'Metabolic Age'**
  String get metabolicAge;

  /// Body fat percentage label
  ///
  /// In en, this message translates to:
  /// **'Body Fat'**
  String get bodyFat;

  /// Visceral fat level label
  ///
  /// In en, this message translates to:
  /// **'Visceral Fat'**
  String get visceralFat;

  /// Body water percentage label
  ///
  /// In en, this message translates to:
  /// **'Body Water'**
  String get bodyWater;

  /// Daily water intake goal label
  ///
  /// In en, this message translates to:
  /// **'Water Goal'**
  String get waterGoal;

  /// Daily caffeine limit label
  ///
  /// In en, this message translates to:
  /// **'Caffeine Goal'**
  String get caffeineGoal;

  /// Daily calorie goal label
  ///
  /// In en, this message translates to:
  /// **'Calorie Goal'**
  String get calorieGoal;

  /// Daily protein goal label
  ///
  /// In en, this message translates to:
  /// **'Protein Goal'**
  String get proteinGoal;

  /// Daily carbohydrate goal label
  ///
  /// In en, this message translates to:
  /// **'Carb Goal'**
  String get carbGoal;

  /// Daily fat goal label
  ///
  /// In en, this message translates to:
  /// **'Fat Goal'**
  String get fatGoal;

  /// Unit for hydration measurement (ml/oz)
  ///
  /// In en, this message translates to:
  /// **'Hydration Unit'**
  String get hydrationUnit;

  /// Unit for weight measurement (kg/lb)
  ///
  /// In en, this message translates to:
  /// **'Weight Unit'**
  String get weightUnit;

  /// Placeholder text for the global search field
  ///
  /// In en, this message translates to:
  /// **'Search anything...'**
  String get searchPlaceholder;

  /// Search results section title
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// Message shown when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Recent searches section title
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// Clear recent searches action label
  ///
  /// In en, this message translates to:
  /// **'Clear Recent'**
  String get clearRecent;

  /// Search scope selector prefix label
  ///
  /// In en, this message translates to:
  /// **'Search in'**
  String get searchIn;

  /// Search within projects action label
  ///
  /// In en, this message translates to:
  /// **'Search Projects'**
  String get searchProjects;

  /// Search within notes action label
  ///
  /// In en, this message translates to:
  /// **'Search Notes'**
  String get searchNotes;

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Mark all notifications as read action label
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllRead;

  /// Clear all notifications action label
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Empty state message for notifications
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Notification settings section title
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Push notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// Email notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// Reminder notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminderNotifications;

  /// Mention notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get mentionNotifications;

  /// Update notifications toggle label
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updateNotifications;

  /// Summary section title
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Today's summary section title
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Summary'**
  String get todaySummary;

  /// Weekly summary section title
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get weekSummary;

  /// Insights feature pill label
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// AI-generated insights section title
  ///
  /// In en, this message translates to:
  /// **'AI Insights'**
  String get aiInsights;

  /// Generate AI insight action label
  ///
  /// In en, this message translates to:
  /// **'Generate Insight'**
  String get generateInsight;

  /// Loading message while generating AI insight
  ///
  /// In en, this message translates to:
  /// **'Generating insight...'**
  String get insightLoading;

  /// Empty state message for insights
  ///
  /// In en, this message translates to:
  /// **'No insights yet'**
  String get noInsights;

  /// Create new agent screen title
  ///
  /// In en, this message translates to:
  /// **'New Agent'**
  String get newAgentTitle;

  /// Agent name field label
  ///
  /// In en, this message translates to:
  /// **'Agent Name'**
  String get agentName;

  /// Agent description field label
  ///
  /// In en, this message translates to:
  /// **'Agent Description'**
  String get agentDescription;

  /// Agent AI provider field label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get agentProvider;

  /// Agent AI model field label
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get agentModel;

  /// Agent system prompt field label
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get agentSystemPrompt;

  /// Run agent action label
  ///
  /// In en, this message translates to:
  /// **'Run Agent'**
  String get runAgent;

  /// Agent status label
  ///
  /// In en, this message translates to:
  /// **'Agent Status'**
  String get agentStatus;

  /// Agent running status label
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get agentRunning;

  /// Agent completed status label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get agentDone;

  /// Agent error status label
  ///
  /// In en, this message translates to:
  /// **'Agent Error'**
  String get agentError;

  /// Create new skill action label
  ///
  /// In en, this message translates to:
  /// **'New Skill'**
  String get newSkill;

  /// Skill name field label
  ///
  /// In en, this message translates to:
  /// **'Skill Name'**
  String get skillName;

  /// Skill description field label
  ///
  /// In en, this message translates to:
  /// **'Skill Description'**
  String get skillDescription;

  /// Install skill action label
  ///
  /// In en, this message translates to:
  /// **'Install Skill'**
  String get installSkill;

  /// Remove skill action label
  ///
  /// In en, this message translates to:
  /// **'Remove Skill'**
  String get removeSkill;

  /// Enable skill action label
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enableSkill;

  /// Disable skill action label
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disableSkill;

  /// Note title field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitle;

  /// Note content field label
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get noteContent;

  /// Save note action label
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get saveNote;

  /// Delete note action label
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// Pin note action label
  ///
  /// In en, this message translates to:
  /// **'Pin Note'**
  String get pinNote;

  /// Unpin note action label
  ///
  /// In en, this message translates to:
  /// **'Unpin Note'**
  String get unpinNote;

  /// Confirmation message after note is updated
  ///
  /// In en, this message translates to:
  /// **'Note updated'**
  String get noteUpdated;

  /// Confirmation message after note is deleted
  ///
  /// In en, this message translates to:
  /// **'Note deleted'**
  String get noteDeleted;

  /// Create new document action label
  ///
  /// In en, this message translates to:
  /// **'New Document'**
  String get newDoc;

  /// Document title field label
  ///
  /// In en, this message translates to:
  /// **'Document Title'**
  String get docTitle;

  /// Document content field label
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get docContent;

  /// Publish document action label
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishDoc;

  /// Unpublish document action label
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublishDoc;

  /// Confirmation message after document is published
  ///
  /// In en, this message translates to:
  /// **'Document published'**
  String get docPublished;

  /// Document draft status label
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get docDraft;

  /// Create new workflow screen title
  ///
  /// In en, this message translates to:
  /// **'New Workflow'**
  String get newWorkflowTitle;

  /// Workflow name field label
  ///
  /// In en, this message translates to:
  /// **'Workflow Name'**
  String get workflowName;

  /// Workflow description field label
  ///
  /// In en, this message translates to:
  /// **'Workflow Description'**
  String get workflowDescription;

  /// Run workflow action label
  ///
  /// In en, this message translates to:
  /// **'Run Workflow'**
  String get runWorkflow;

  /// Stop workflow action label
  ///
  /// In en, this message translates to:
  /// **'Stop Workflow'**
  String get stopWorkflow;

  /// Workflow running status message
  ///
  /// In en, this message translates to:
  /// **'Workflow running...'**
  String get workflowRunning;

  /// Workflow completed status message
  ///
  /// In en, this message translates to:
  /// **'Workflow completed'**
  String get workflowDone;

  /// Workflow steps section label
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get workflowSteps;

  /// Add workflow step action label
  ///
  /// In en, this message translates to:
  /// **'Add Step'**
  String get addStep;

  /// Create new delegation action label
  ///
  /// In en, this message translates to:
  /// **'New Delegation'**
  String get newDelegation;

  /// Delegate to field label
  ///
  /// In en, this message translates to:
  /// **'Delegate To'**
  String get delegateTo;

  /// Delegation task field label
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get delegationTask;

  /// Delegation status field label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get delegationStatus;

  /// Accept delegation action label
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptDelegation;

  /// Reject delegation action label
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectDelegation;

  /// Delegation completed status message
  ///
  /// In en, this message translates to:
  /// **'Delegation completed'**
  String get delegationDone;

  /// Create new session action label
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get newSession;

  /// Session name field label
  ///
  /// In en, this message translates to:
  /// **'Session Name'**
  String get sessionName;

  /// Session status field label
  ///
  /// In en, this message translates to:
  /// **'Session Status'**
  String get sessionStatus;

  /// Session active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sessionActive;

  /// Session paused status label
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get sessionPaused;

  /// Session ended status label
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get sessionEnded;

  /// End session action label
  ///
  /// In en, this message translates to:
  /// **'End Session'**
  String get endSession;

  /// Pause session action label
  ///
  /// In en, this message translates to:
  /// **'Pause Session'**
  String get pauseSession;

  /// Resume session action label
  ///
  /// In en, this message translates to:
  /// **'Resume Session'**
  String get resumeSession;

  /// Teams section title
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// Team name field label
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamName;

  /// Team members section label
  ///
  /// In en, this message translates to:
  /// **'Team Members'**
  String get teamMembers;

  /// Invite team member action label
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get inviteMember;

  /// Remove team member action label
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get removeMember;

  /// Team member role field label
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get teamRole;

  /// Team admin role label
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get teamAdmin;

  /// Team member role label
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get teamMember;

  /// Leave team action label
  ///
  /// In en, this message translates to:
  /// **'Leave Team'**
  String get leaveTeam;

  /// Delete team action label
  ///
  /// In en, this message translates to:
  /// **'Delete Team'**
  String get deleteTeam;

  /// Profile section title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Bio / about me field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Timezone field label
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// GitHub username field label
  ///
  /// In en, this message translates to:
  /// **'GitHub Username'**
  String get githubUsername;

  /// Avatar URL field label
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get avatarUrl;

  /// Update profile action label
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// Confirmation message after profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// Error message when profile update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileError;

  /// Error message for network connectivity issues
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// Error message for server-side errors
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// Error message for unauthorized actions
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to perform this action.'**
  String get unauthorizedError;

  /// Error message for 404 not found
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get notFoundError;

  /// Error message for validation failures
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again.'**
  String get validationError;

  /// Error message for request timeouts
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get timeoutError;

  /// Generic unknown error message
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;

  /// Try again action label
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Contact support action label
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Error code label
  ///
  /// In en, this message translates to:
  /// **'Error Code'**
  String get errorCode;

  /// Error message for connection failures
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionError;

  /// Error message when sync fails
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncError;

  /// Error message for authentication failures
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authError;

  /// Error message for permission denied
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionError;

  /// Error message for storage failures
  ///
  /// In en, this message translates to:
  /// **'Storage error'**
  String get storageError;

  /// Library tab label
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Sign up button label
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Team and workspace settings label
  ///
  /// In en, this message translates to:
  /// **'Team & Workspace'**
  String get teamAndWorkspace;

  /// Current password field label
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// Confirm new password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// Update password button label
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// Enable two-factor authentication toggle label
  ///
  /// In en, this message translates to:
  /// **'Enable 2FA'**
  String get enable2FA;

  /// Project updates notification category
  ///
  /// In en, this message translates to:
  /// **'Project updates'**
  String get projectUpdates;

  /// Feature changes notification category
  ///
  /// In en, this message translates to:
  /// **'Feature changes'**
  String get featureChanges;

  /// Health alerts notification category
  ///
  /// In en, this message translates to:
  /// **'Health alerts'**
  String get healthAlerts;

  /// System notification category
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Empty state title for notifications
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// Empty state subtitle for notifications
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNewNotifications;

  /// Themes settings label
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// Language picker dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Recommendations section label
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// Account settings section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Admin section label
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// Mentions notification category
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get mentions;

  /// All category filter label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Gender field label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Position / job title field label
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// Male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// Female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// Other gender option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// Prefer not to say gender option
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// Avatar upload success message
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get avatarUpdated;

  /// Avatar upload error message
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar'**
  String get failedToUploadAvatar;

  /// Save error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// Default team name placeholder
  ///
  /// In en, this message translates to:
  /// **'My Team'**
  String get myTeam;

  /// Default workspace name placeholder
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultWorkspace;

  /// Health score wins label
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// Health score concerns label
  ///
  /// In en, this message translates to:
  /// **'Concerns'**
  String get concerns;

  /// AI insights generation button label
  ///
  /// In en, this message translates to:
  /// **'Generate AI Insights'**
  String get generateAiInsights;

  /// Daily flow score label
  ///
  /// In en, this message translates to:
  /// **'Daily Score'**
  String get dailyScore;

  /// Daily flow component breakdown header
  ///
  /// In en, this message translates to:
  /// **'Component Breakdown'**
  String get componentBreakdown;

  /// Pomodoros component label
  ///
  /// In en, this message translates to:
  /// **'Pomodoros'**
  String get pomodoros;

  /// Zepp Scale section header in vitals
  ///
  /// In en, this message translates to:
  /// **'Zepp Scale'**
  String get zeppScale;

  /// Weight input label in kilograms
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// Body fat percentage input label
  ///
  /// In en, this message translates to:
  /// **'Body Fat (%)'**
  String get bodyFatPercent;

  /// Visceral fat input label with range
  ///
  /// In en, this message translates to:
  /// **'Visceral Fat (1–12)'**
  String get visceralFatRange;

  /// Body water percentage input label
  ///
  /// In en, this message translates to:
  /// **'Body Water (%)'**
  String get bodyWaterPercent;

  /// Search field placeholder text
  ///
  /// In en, this message translates to:
  /// **'Search everything...'**
  String get searchEverything;

  /// Browse mode empty state title
  ///
  /// In en, this message translates to:
  /// **'Browse resources'**
  String get browseResources;

  /// Browse mode empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap a category to explore'**
  String get tapCategoryToExplore;

  /// Search error state title
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// Search no-results hint text
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your query or category filter'**
  String get tryAdjustingQuery;

  /// Close search accessibility label
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// Projects category subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage workspaces and codebases'**
  String get subtitleProjects;

  /// Notes category subtitle
  ///
  /// In en, this message translates to:
  /// **'Quick notes and observations'**
  String get subtitleNotes;

  /// Agents category subtitle
  ///
  /// In en, this message translates to:
  /// **'AI agents and assistants'**
  String get subtitleAgents;

  /// Skills category subtitle
  ///
  /// In en, this message translates to:
  /// **'Slash commands and automations'**
  String get subtitleSkills;

  /// Workflows category subtitle
  ///
  /// In en, this message translates to:
  /// **'Multi-step execution pipelines'**
  String get subtitleWorkflows;

  /// Docs category subtitle
  ///
  /// In en, this message translates to:
  /// **'Documentation and references'**
  String get subtitleDocs;

  /// Delegations category subtitle
  ///
  /// In en, this message translates to:
  /// **'Cross-agent task delegation'**
  String get subtitleDelegations;

  /// Health Score category subtitle
  ///
  /// In en, this message translates to:
  /// **'Overall health metrics'**
  String get subtitleHealthScore;

  /// Vitals category subtitle
  ///
  /// In en, this message translates to:
  /// **'Heart rate, steps, and body stats'**
  String get subtitleVitals;

  /// Daily Flow category subtitle
  ///
  /// In en, this message translates to:
  /// **'Daily routines and habits'**
  String get subtitleDailyFlow;

  /// Hydration category subtitle
  ///
  /// In en, this message translates to:
  /// **'Water intake tracking'**
  String get subtitleHydration;

  /// Caffeine category subtitle
  ///
  /// In en, this message translates to:
  /// **'Caffeine intake and clean transition'**
  String get subtitleCaffeine;

  /// Nutrition category subtitle
  ///
  /// In en, this message translates to:
  /// **'Meal logging and food safety'**
  String get subtitleNutrition;

  /// Pomodoro category subtitle
  ///
  /// In en, this message translates to:
  /// **'Focus timer and work sessions'**
  String get subtitlePomodoro;

  /// Shutdown category subtitle
  ///
  /// In en, this message translates to:
  /// **'Evening shutdown ritual'**
  String get subtitleShutdown;

  /// Weight category subtitle
  ///
  /// In en, this message translates to:
  /// **'Body weight tracking'**
  String get subtitleWeight;

  /// Sleep category subtitle
  ///
  /// In en, this message translates to:
  /// **'Sleep quality and duration'**
  String get subtitleSleep;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good morning,'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon,'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening,'**
  String get goodEvening;

  /// Hidden widgets bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Hidden Widgets'**
  String get hiddenWidgets;

  /// Add action label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Switch team menu item
  ///
  /// In en, this message translates to:
  /// **'Switch Team'**
  String get switchTeam;

  /// Switch workspace menu item
  ///
  /// In en, this message translates to:
  /// **'Switch Workspace'**
  String get switchWorkspace;

  /// Personal workspace label
  ///
  /// In en, this message translates to:
  /// **'Personal Workspace'**
  String get personalWorkspace;

  /// Active count label
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// Pending count label
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get pending;

  /// Total count label
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get total;

  /// Pinned count label
  ///
  /// In en, this message translates to:
  /// **'pinned'**
  String get pinnedCount;

  /// Caffeine over limit warning
  ///
  /// In en, this message translates to:
  /// **'Over limit'**
  String get overLimit;

  /// Milligrams today caffeine label
  ///
  /// In en, this message translates to:
  /// **'mg today'**
  String get mgToday;

  /// Clean caffeine state label
  ///
  /// In en, this message translates to:
  /// **'clean'**
  String get cleanLabel;

  /// Meals count label
  ///
  /// In en, this message translates to:
  /// **'meals'**
  String get meals;

  /// Nutrition safe status
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get safe;

  /// Nutrition warning status
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Nutrition critical status
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// Focus health dimension label
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// Add 250ml water button label
  ///
  /// In en, this message translates to:
  /// **'+250 ml'**
  String get addWaterMl;

  /// Pomodoro ready status label
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @useDifferentMethod.
  ///
  /// In en, this message translates to:
  /// **'Use a different sign-in method'**
  String get useDifferentMethod;

  /// No description provided for @registerPasskey.
  ///
  /// In en, this message translates to:
  /// **'Register Passkey'**
  String get registerPasskey;

  /// No description provided for @verifyAndEnable.
  ///
  /// In en, this message translates to:
  /// **'Verify & Enable'**
  String get verifyAndEnable;

  /// No description provided for @newPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get newPasswordsDoNotMatch;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @pleaseAllPasswordFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all password fields'**
  String get pleaseAllPasswordFields;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @generateRecoveryCodes.
  ///
  /// In en, this message translates to:
  /// **'Generate Recovery Codes'**
  String get generateRecoveryCodes;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @contextLabel.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get contextLabel;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failedToDelete;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteConfirm;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Note?'**
  String get deleteNoteConfirm;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @failedToLoadAgents.
  ///
  /// In en, this message translates to:
  /// **'Failed to load agents'**
  String get failedToLoadAgents;

  /// No description provided for @failedToLoadNotes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notes'**
  String get failedToLoadNotes;

  /// No description provided for @failedToLoadSkills.
  ///
  /// In en, this message translates to:
  /// **'Failed to load skills'**
  String get failedToLoadSkills;

  /// No description provided for @failedToLoadWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Failed to load workflows'**
  String get failedToLoadWorkflows;

  /// No description provided for @failedToLoadDocs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load docs'**
  String get failedToLoadDocs;

  /// No description provided for @failedToLoadDelegations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load delegations'**
  String get failedToLoadDelegations;

  /// No description provided for @failedToLoadProjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to load projects'**
  String get failedToLoadProjects;

  /// No description provided for @failedToLoadSessions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sessions'**
  String get failedToLoadSessions;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects'**
  String get noProjects;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get noSessions;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get codeCopied;

  /// No description provided for @markdownCopied.
  ///
  /// In en, this message translates to:
  /// **'Markdown copied to clipboard'**
  String get markdownCopied;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @resetToday.
  ///
  /// In en, this message translates to:
  /// **'Reset Today'**
  String get resetToday;

  /// No description provided for @triggerAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Trigger Analysis'**
  String get triggerAnalysis;

  /// No description provided for @refreshInsights.
  ///
  /// In en, this message translates to:
  /// **'Refresh Insights'**
  String get refreshInsights;

  /// No description provided for @connectHealth.
  ///
  /// In en, this message translates to:
  /// **'Connect Health'**
  String get connectHealth;

  /// No description provided for @saveMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Save Measurements'**
  String get saveMeasurements;

  /// No description provided for @logSleep.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep'**
  String get logSleep;

  /// No description provided for @sleepLogged.
  ///
  /// In en, this message translates to:
  /// **'Sleep logged'**
  String get sleepLogged;

  /// No description provided for @logMeal.
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get logMeal;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @testSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Test successful'**
  String get testSuccessful;

  /// No description provided for @testFailed.
  ///
  /// In en, this message translates to:
  /// **'Test failed'**
  String get testFailed;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @testEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Test email sent successfully'**
  String get testEmailSent;

  /// No description provided for @submitIssue.
  ///
  /// In en, this message translates to:
  /// **'Submit Issue'**
  String get submitIssue;

  /// No description provided for @issueReported.
  ///
  /// In en, this message translates to:
  /// **'Issue reported successfully'**
  String get issueReported;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @apiKeyCreated.
  ///
  /// In en, this message translates to:
  /// **'API key created'**
  String get apiKeyCreated;

  /// No description provided for @apiKeyRevoked.
  ///
  /// In en, this message translates to:
  /// **'API key revoked'**
  String get apiKeyRevoked;

  /// No description provided for @sessionRevoked.
  ///
  /// In en, this message translates to:
  /// **'Session revoked'**
  String get sessionRevoked;

  /// No description provided for @allSessionsRevoked.
  ///
  /// In en, this message translates to:
  /// **'All other sessions revoked'**
  String get allSessionsRevoked;

  /// No description provided for @socialLinksUpdated.
  ///
  /// In en, this message translates to:
  /// **'Social links updated'**
  String get socialLinksUpdated;

  /// No description provided for @promptsSaved.
  ///
  /// In en, this message translates to:
  /// **'Prompts saved'**
  String get promptsSaved;

  /// No description provided for @downloadOrchestra.
  ///
  /// In en, this message translates to:
  /// **'Download Orchestra'**
  String get downloadOrchestra;

  /// No description provided for @extractAndInstall.
  ///
  /// In en, this message translates to:
  /// **'Extract and Install'**
  String get extractAndInstall;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @initializingWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Initializing workspace...'**
  String get initializingWorkspace;

  /// No description provided for @failedToInitWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize workspace'**
  String get failedToInitWorkspace;

  /// No description provided for @fileAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'File access is required to continue'**
  String get fileAccessRequired;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @newPage.
  ///
  /// In en, this message translates to:
  /// **'New Page'**
  String get newPage;

  /// No description provided for @editPage.
  ///
  /// In en, this message translates to:
  /// **'Edit Page'**
  String get editPage;

  /// No description provided for @deletePage.
  ///
  /// In en, this message translates to:
  /// **'Delete Page'**
  String get deletePage;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @editSponsor.
  ///
  /// In en, this message translates to:
  /// **'Edit Sponsor'**
  String get editSponsor;

  /// No description provided for @removeSponsor.
  ///
  /// In en, this message translates to:
  /// **'Remove Sponsor'**
  String get removeSponsor;

  /// No description provided for @addSponsor.
  ///
  /// In en, this message translates to:
  /// **'Add Sponsor'**
  String get addSponsor;

  /// No description provided for @deleteSubmission.
  ///
  /// In en, this message translates to:
  /// **'Delete Submission'**
  String get deleteSubmission;

  /// No description provided for @updateIssue.
  ///
  /// In en, this message translates to:
  /// **'Update Issue'**
  String get updateIssue;

  /// No description provided for @updatePostStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Post Status'**
  String get updatePostStatus;

  /// No description provided for @newFeatureFlag.
  ///
  /// In en, this message translates to:
  /// **'New Feature Flag'**
  String get newFeatureFlag;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotification;

  /// No description provided for @editTeam.
  ///
  /// In en, this message translates to:
  /// **'Edit Team'**
  String get editTeam;

  /// No description provided for @createTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// No description provided for @deleteTeamConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Team'**
  String get deleteTeamConfirm;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInvite;

  /// No description provided for @impersonate.
  ///
  /// In en, this message translates to:
  /// **'Impersonate'**
  String get impersonate;

  /// No description provided for @operational.
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get operational;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @inReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get inReview;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @viewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewer;

  /// No description provided for @teamManager.
  ///
  /// In en, this message translates to:
  /// **'Team Manager'**
  String get teamManager;

  /// No description provided for @teamOwner.
  ///
  /// In en, this message translates to:
  /// **'Team Owner'**
  String get teamOwner;

  /// No description provided for @noMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get noMembersYet;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get mostPopular;

  /// No description provided for @gold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get gold;

  /// No description provided for @silver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get silver;

  /// No description provided for @bronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get bronze;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @syncConflicts.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflicts'**
  String get syncConflicts;

  /// No description provided for @mergeEditor.
  ///
  /// In en, this message translates to:
  /// **'Merge Editor'**
  String get mergeEditor;

  /// No description provided for @sshConnection.
  ///
  /// In en, this message translates to:
  /// **'SSH Connection'**
  String get sshConnection;

  /// No description provided for @createSession.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get createSession;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @summarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get summarize;

  /// No description provided for @explain.
  ///
  /// In en, this message translates to:
  /// **'Explain'**
  String get explain;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @translate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translate;

  /// No description provided for @customPrompt.
  ///
  /// In en, this message translates to:
  /// **'Custom prompt'**
  String get customPrompt;

  /// No description provided for @aiSmartActions.
  ///
  /// In en, this message translates to:
  /// **'AI smart actions'**
  String get aiSmartActions;

  /// No description provided for @noRecentWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'No recent workspaces'**
  String get noRecentWorkspaces;

  /// No description provided for @publicLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Public link copied to clipboard'**
  String get publicLinkCopied;

  /// No description provided for @viewDemo.
  ///
  /// In en, this message translates to:
  /// **'View Demo'**
  String get viewDemo;

  /// No description provided for @cloneAndOpen.
  ///
  /// In en, this message translates to:
  /// **'Clone & Open'**
  String get cloneAndOpen;

  /// No description provided for @aboutOrchestra.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutOrchestra;

  /// No description provided for @downloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadLabel;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @orchestraAi.
  ///
  /// In en, this message translates to:
  /// **'Orchestra AI'**
  String get orchestraAi;

  /// No description provided for @aiDescription.
  ///
  /// In en, this message translates to:
  /// **'AI-powered project management for developers'**
  String get aiDescription;

  /// No description provided for @pngJpgLimit.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 2MB'**
  String get pngJpgLimit;

  /// No description provided for @markAllReadAction.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllReadAction;

  /// No description provided for @newFlag.
  ///
  /// In en, this message translates to:
  /// **'New Flag'**
  String get newFlag;

  /// No description provided for @newIssue.
  ///
  /// In en, this message translates to:
  /// **'New Issue'**
  String get newIssue;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @tableDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Table copied to clipboard'**
  String get tableDataCopied;

  /// No description provided for @claudeMdCopied.
  ///
  /// In en, this message translates to:
  /// **'CLAUDE.md copied to clipboard'**
  String get claudeMdCopied;

  /// No description provided for @projectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found'**
  String get projectNotFound;

  /// No description provided for @downloadDesktopApp.
  ///
  /// In en, this message translates to:
  /// **'Download Desktop App'**
  String get downloadDesktopApp;

  /// No description provided for @failedToUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get failedToUpdatePassword;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @addPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add Prompt'**
  String get addPrompt;

  /// No description provided for @submissionClosed.
  ///
  /// In en, this message translates to:
  /// **'Submission closed'**
  String get submissionClosed;

  /// No description provided for @markedAsReplied.
  ///
  /// In en, this message translates to:
  /// **'Marked as replied'**
  String get markedAsReplied;

  /// No description provided for @failedToLoadMembers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members'**
  String get failedToLoadMembers;

  /// No description provided for @failedToLoadTeams.
  ///
  /// In en, this message translates to:
  /// **'Failed to load teams'**
  String get failedToLoadTeams;

  /// No description provided for @failedToLoadWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Failed to load workspaces'**
  String get failedToLoadWorkspaces;

  /// No description provided for @failedToLoadIssues.
  ///
  /// In en, this message translates to:
  /// **'Failed to load issues'**
  String get failedToLoadIssues;

  /// No description provided for @connectionTestSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection test successful'**
  String get connectionTestSuccessful;

  /// No description provided for @welcomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeScreen;

  /// No description provided for @failedToCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Failed to create team'**
  String get failedToCreateTeam;

  /// No description provided for @failedToRenameTeam.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename team'**
  String get failedToRenameTeam;

  /// No description provided for @failedToDeleteTeam.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete team'**
  String get failedToDeleteTeam;

  /// No description provided for @failedToInvite.
  ///
  /// In en, this message translates to:
  /// **'Failed to invite'**
  String get failedToInvite;

  /// No description provided for @failedToRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member'**
  String get failedToRemoveMember;

  /// No description provided for @failedToRevokeApiKey.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke API key'**
  String get failedToRevokeApiKey;

  /// No description provided for @failedToCreateApiKey.
  ///
  /// In en, this message translates to:
  /// **'Failed to create API key'**
  String get failedToCreateApiKey;

  /// No description provided for @failedToRevokeSession.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke session'**
  String get failedToRevokeSession;

  /// No description provided for @failedToRevokeSessions.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke sessions'**
  String get failedToRevokeSessions;

  /// No description provided for @failedToSavePreference.
  ///
  /// In en, this message translates to:
  /// **'Failed to save preference'**
  String get failedToSavePreference;

  /// No description provided for @failedToSaveSetting.
  ///
  /// In en, this message translates to:
  /// **'Failed to save setting'**
  String get failedToSaveSetting;

  /// No description provided for @failedToSaveSocialLinks.
  ///
  /// In en, this message translates to:
  /// **'Failed to save social links'**
  String get failedToSaveSocialLinks;

  /// No description provided for @failedToSaveAiSetting.
  ///
  /// In en, this message translates to:
  /// **'Failed to save AI setting'**
  String get failedToSaveAiSetting;

  /// No description provided for @failedToDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect'**
  String get failedToDisconnect;

  /// No description provided for @pullFailed.
  ///
  /// In en, this message translates to:
  /// **'Pull failed'**
  String get pullFailed;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get yourPassword;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join Orchestra and start building'**
  String get joinSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @minEightCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get minEightCharacters;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @passwordTooShortSix.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShortSix;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a magic link to sign in.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @magicLinkSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a magic link to'**
  String get magicLinkSentTo;

  /// No description provided for @magicLinkExpiry.
  ///
  /// In en, this message translates to:
  /// **'Click the link in the email to sign in. The link expires in 15 minutes.'**
  String get magicLinkExpiry;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be at least 8 characters.'**
  String get newPasswordHint;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get repeatPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset!'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated. You can now sign in with your new password.'**
  String get passwordResetSuccessSubtitle;

  /// No description provided for @magicLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'\'ll send a one-time link to your email.'**
  String get magicLinkSubtitle;

  /// No description provided for @tapMagicLinkExpiry.
  ///
  /// In en, this message translates to:
  /// **'Tap the link in the email to sign in. The link expires in 15 minutes.'**
  String get tapMagicLinkExpiry;

  /// No description provided for @passkeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID, Touch ID, or your device PIN to authenticate.'**
  String get passkeySubtitle;

  /// No description provided for @authenticated.
  ///
  /// In en, this message translates to:
  /// **'Authenticated'**
  String get authenticated;

  /// No description provided for @authenticateWithPasskey.
  ///
  /// In en, this message translates to:
  /// **'Authenticate with Passkey'**
  String get authenticateWithPasskey;

  /// No description provided for @signInToOrchestra.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Orchestra'**
  String get signInToOrchestra;

  /// No description provided for @authCancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication was cancelled or not recognised.'**
  String get authCancelled;

  /// No description provided for @twoStepVerification.
  ///
  /// In en, this message translates to:
  /// **'Two-step verification'**
  String get twoStepVerification;

  /// No description provided for @enterCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to '**
  String get enterCodeSentTo;

  /// No description provided for @otpInputLabel.
  ///
  /// In en, this message translates to:
  /// **'One-time password input'**
  String get otpInputLabel;

  /// No description provided for @enterFullCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the full 6-digit code'**
  String get enterFullCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get enterYourEmail;

  /// No description provided for @signInWithMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in with magic link'**
  String get signInWithMagicLink;

  /// No description provided for @agentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} agents'**
  String agentsCount(int count);

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String notesCount(int count);

  /// No description provided for @skillsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} skills'**
  String skillsCount(int count);

  /// No description provided for @workflowsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} workflows'**
  String workflowsCount(int count);

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} documents'**
  String documentsCount(int count);

  /// No description provided for @delegationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} delegations'**
  String delegationsCount(int count);

  /// No description provided for @noAgentsFound.
  ///
  /// In en, this message translates to:
  /// **'No agents found'**
  String get noAgentsFound;

  /// No description provided for @agentsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Agents will appear here once configured'**
  String get agentsWillAppear;

  /// No description provided for @noSkillsFound.
  ///
  /// In en, this message translates to:
  /// **'No skills found'**
  String get noSkillsFound;

  /// No description provided for @skillsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Skills will appear here once configured'**
  String get skillsWillAppear;

  /// No description provided for @noWorkflowsFound.
  ///
  /// In en, this message translates to:
  /// **'No workflows found'**
  String get noWorkflowsFound;

  /// No description provided for @workflowsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Workflows will appear here once defined'**
  String get workflowsWillAppear;

  /// No description provided for @noDocsFound.
  ///
  /// In en, this message translates to:
  /// **'No docs found'**
  String get noDocsFound;

  /// No description provided for @docsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Documentation files will appear here'**
  String get docsWillAppear;

  /// No description provided for @noDelegationsFound.
  ///
  /// In en, this message translates to:
  /// **'No delegations found'**
  String get noDelegationsFound;

  /// No description provided for @delegatedTasksWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Delegated tasks will appear here'**
  String get delegatedTasksWillAppear;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @notesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Notes you create will appear here'**
  String get notesWillAppear;

  /// No description provided for @agentPublished.
  ///
  /// In en, this message translates to:
  /// **'Agent published'**
  String get agentPublished;

  /// No description provided for @notePublished.
  ///
  /// In en, this message translates to:
  /// **'Note published'**
  String get notePublished;

  /// No description provided for @skillPublished.
  ///
  /// In en, this message translates to:
  /// **'Skill published'**
  String get skillPublished;

  /// No description provided for @workflowPublished.
  ///
  /// In en, this message translates to:
  /// **'Workflow published'**
  String get workflowPublished;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Publish failed'**
  String get publishFailed;

  /// No description provided for @delegationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Delegation not found'**
  String get delegationNotFound;

  /// No description provided for @failedToLoadDelegation.
  ///
  /// In en, this message translates to:
  /// **'Failed to load delegation'**
  String get failedToLoadDelegation;

  /// No description provided for @failedToLoadNote.
  ///
  /// In en, this message translates to:
  /// **'Failed to load note'**
  String get failedToLoadNote;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get noContent;

  /// No description provided for @noteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Note not found'**
  String get noteNotFound;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get checkConnection;

  /// No description provided for @itemMayHaveBeenRemoved.
  ///
  /// In en, this message translates to:
  /// **'This item may have been removed or renamed'**
  String get itemMayHaveBeenRemoved;

  /// No description provided for @systemPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get systemPromptLabel;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @noteHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get noteHintTitle;

  /// No description provided for @addTagHint.
  ///
  /// In en, this message translates to:
  /// **'Add tag...'**
  String get addTagHint;

  /// No description provided for @writeMarkdownHint.
  ///
  /// In en, this message translates to:
  /// **'Write your note in Markdown...'**
  String get writeMarkdownHint;

  /// No description provided for @nothingToPreview.
  ///
  /// In en, this message translates to:
  /// **'Nothing to preview'**
  String get nothingToPreview;

  /// No description provided for @describeYourNote.
  ///
  /// In en, this message translates to:
  /// **'Describe your note'**
  String get describeYourNote;

  /// No description provided for @smartAction.
  ///
  /// In en, this message translates to:
  /// **'Smart Action'**
  String get smartAction;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @notePromptHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Meeting notes template for weekly standup'**
  String get notePromptHint;

  /// No description provided for @sendingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sending prompt to AI...'**
  String get sendingPrompt;

  /// No description provided for @aiGenerating.
  ///
  /// In en, this message translates to:
  /// **'AI is generating your note...'**
  String get aiGenerating;

  /// No description provided for @responseReceived.
  ///
  /// In en, this message translates to:
  /// **'Response received, parsing...'**
  String get responseReceived;

  /// No description provided for @failedToParse.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse AI response as JSON'**
  String get failedToParse;

  /// No description provided for @noteGenerated.
  ///
  /// In en, this message translates to:
  /// **'Note generated successfully'**
  String get noteGenerated;

  /// No description provided for @mcpNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'MCP client not available (desktop only)'**
  String get mcpNotAvailable;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get defaultBadge;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {assignee} -- {status}'**
  String assignedTo(String assignee, String status);

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @featureLabel.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get featureLabel;

  /// No description provided for @providerLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get providerLabel;

  /// No description provided for @modelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelLabel;

  /// No description provided for @commandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get commandLabel;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// No description provided for @projectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectLabel;

  /// No description provided for @initialStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial State'**
  String get initialStateLabel;

  /// No description provided for @statesLabel.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get statesLabel;

  /// No description provided for @transitionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Transitions'**
  String get transitionsLabel;

  /// No description provided for @gatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Gates'**
  String get gatesLabel;

  /// No description provided for @pathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get pathLabel;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @itemNotFound.
  ///
  /// In en, this message translates to:
  /// **'{itemType} not found'**
  String itemNotFound(String itemType);

  /// No description provided for @failedToLoadItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to load {itemType}'**
  String failedToLoadItem(String itemType);

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {itemType}?'**
  String deleteItemTitle(String itemType);

  /// No description provided for @deleteItemMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String deleteItemMessage(String name);

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get project;

  /// No description provided for @feature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get feature;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// No description provided for @skill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get skill;

  /// No description provided for @workflow.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get workflow;

  /// No description provided for @doc.
  ///
  /// In en, this message translates to:
  /// **'Doc'**
  String get doc;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @delegation.
  ///
  /// In en, this message translates to:
  /// **'Delegation'**
  String get delegation;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @wellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wellness;

  /// No description provided for @noHealthData.
  ///
  /// In en, this message translates to:
  /// **'No Health Data'**
  String get noHealthData;

  /// No description provided for @connectHealthDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to Apple Health or Health Connect to see your steps, heart rate, and other vitals here.'**
  String get connectHealthDescription;

  /// No description provided for @learnMorePermissions.
  ///
  /// In en, this message translates to:
  /// **'Learn more about permissions'**
  String get learnMorePermissions;

  /// No description provided for @installOrchestra.
  ///
  /// In en, this message translates to:
  /// **'Install Orchestra'**
  String get installOrchestra;

  /// No description provided for @orchestraBinaryNotFound.
  ///
  /// In en, this message translates to:
  /// **'The Orchestra binary was not found on your system.'**
  String get orchestraBinaryNotFound;

  /// No description provided for @downloadLatestBinary.
  ///
  /// In en, this message translates to:
  /// **'Download the latest Orchestra binary for your platform.'**
  String get downloadLatestBinary;

  /// No description provided for @extractFiles.
  ///
  /// In en, this message translates to:
  /// **'Extract Files'**
  String get extractFiles;

  /// No description provided for @extractInstallBinary.
  ///
  /// In en, this message translates to:
  /// **'Extract and install the Orchestra binary to ~/.orchestra/bin/'**
  String get extractInstallBinary;

  /// No description provided for @setupComplete.
  ///
  /// In en, this message translates to:
  /// **'Setup Complete'**
  String get setupComplete;

  /// No description provided for @orchestraInstalledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Orchestra has been installed successfully. Restart the app to continue.'**
  String get orchestraInstalledSuccessfully;

  /// No description provided for @desktopRequired.
  ///
  /// In en, this message translates to:
  /// **'Desktop Required'**
  String get desktopRequired;

  /// No description provided for @desktopRequiredDescription.
  ///
  /// In en, this message translates to:
  /// **'Orchestra needs the desktop app running to sync your data. Install and launch the desktop app first.'**
  String get desktopRequiredDescription;

  /// No description provided for @fileAccessRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'File Access Required'**
  String get fileAccessRequiredTitle;

  /// No description provided for @fileAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Orchestra needs access to your home directory to read workspace files and configuration.\n\nSelect your home folder in the next dialog to grant access.'**
  String get fileAccessDescription;

  /// No description provided for @grantFileAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant File Access'**
  String get grantFileAccess;

  /// No description provided for @fileAccessRequiredToContinue.
  ///
  /// In en, this message translates to:
  /// **'File access is required to continue'**
  String get fileAccessRequiredToContinue;

  /// No description provided for @failedToLoadConflicts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load conflicts'**
  String get failedToLoadConflicts;

  /// No description provided for @noConflicts.
  ///
  /// In en, this message translates to:
  /// **'No conflicts'**
  String get noConflicts;

  /// No description provided for @allDataInSync.
  ///
  /// In en, this message translates to:
  /// **'All your data is in sync.'**
  String get allDataInSync;

  /// No description provided for @localThisDevice.
  ///
  /// In en, this message translates to:
  /// **'LOCAL (this device)'**
  String get localThisDevice;

  /// No description provided for @remoteServer.
  ///
  /// In en, this message translates to:
  /// **'REMOTE (server)'**
  String get remoteServer;

  /// No description provided for @noDataToCompare.
  ///
  /// In en, this message translates to:
  /// **'No data to compare (both sides empty).'**
  String get noDataToCompare;

  /// No description provided for @keepLocal.
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get keepLocal;

  /// No description provided for @keepRemote.
  ///
  /// In en, this message translates to:
  /// **'Keep Remote'**
  String get keepRemote;

  /// No description provided for @mergeEditManually.
  ///
  /// In en, this message translates to:
  /// **'Merge (edit manually)'**
  String get mergeEditManually;

  /// No description provided for @useLocal.
  ///
  /// In en, this message translates to:
  /// **'Use Local'**
  String get useLocal;

  /// No description provided for @useRemote.
  ///
  /// In en, this message translates to:
  /// **'Use Remote'**
  String get useRemote;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @outdated.
  ///
  /// In en, this message translates to:
  /// **'Outdated'**
  String get outdated;

  /// No description provided for @conflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get conflicts;

  /// No description provided for @notSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get notSynced;

  /// No description provided for @noSyncedEntities.
  ///
  /// In en, this message translates to:
  /// **'No synced entities yet'**
  String get noSyncedEntities;

  /// No description provided for @noFilteredEntities.
  ///
  /// In en, this message translates to:
  /// **'No {status} entities'**
  String noFilteredEntities(String status);

  /// No description provided for @noTerminalSessions.
  ///
  /// In en, this message translates to:
  /// **'No terminal sessions'**
  String get noTerminalSessions;

  /// No description provided for @createSessionFromSidebar.
  ///
  /// In en, this message translates to:
  /// **'Create a session from the sidebar.'**
  String get createSessionFromSidebar;

  /// No description provided for @newClaudeSession.
  ///
  /// In en, this message translates to:
  /// **'New Claude Session'**
  String get newClaudeSession;

  /// No description provided for @authentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get authentication;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @hostHint.
  ///
  /// In en, this message translates to:
  /// **'example.com or 192.168.1.1'**
  String get hostHint;

  /// No description provided for @hostRequired.
  ///
  /// In en, this message translates to:
  /// **'Host is required'**
  String get hostRequired;

  /// No description provided for @userRequired.
  ///
  /// In en, this message translates to:
  /// **'User is required'**
  String get userRequired;

  /// No description provided for @portRequired.
  ///
  /// In en, this message translates to:
  /// **'Port is required'**
  String get portRequired;

  /// No description provided for @invalidPort.
  ///
  /// In en, this message translates to:
  /// **'Invalid port (1-65535)'**
  String get invalidPort;

  /// No description provided for @keyFile.
  ///
  /// In en, this message translates to:
  /// **'Key file'**
  String get keyFile;

  /// No description provided for @keyFileHint.
  ///
  /// In en, this message translates to:
  /// **'~/.ssh/id_rsa'**
  String get keyFileHint;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @searchTerminalHint.
  ///
  /// In en, this message translates to:
  /// **'Search terminal...'**
  String get searchTerminalHint;

  /// No description provided for @caseSensitive.
  ///
  /// In en, this message translates to:
  /// **'Case sensitive'**
  String get caseSensitive;

  /// No description provided for @openFolderAction.
  ///
  /// In en, this message translates to:
  /// **'Open Folder...'**
  String get openFolderAction;

  /// No description provided for @closeWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Close Workspace'**
  String get closeWorkspace;

  /// No description provided for @chooseWorkspaceFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a workspace folder'**
  String get chooseWorkspaceFolder;

  /// No description provided for @teamCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Team \"{name}\" created'**
  String teamCreatedMessage(String name);

  /// No description provided for @createNewTeam.
  ///
  /// In en, this message translates to:
  /// **'Create New Team'**
  String get createNewTeam;

  /// No description provided for @teamNameHint.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamNameHint;

  /// No description provided for @chooseYourWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Workspace'**
  String get chooseYourWorkspace;

  /// No description provided for @selectProjectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select a project folder to get started with Orchestra.'**
  String get selectProjectFolder;

  /// No description provided for @openExistingFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Existing Folder'**
  String get openExistingFolder;

  /// No description provided for @chooseProjectFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose a project folder on your machine'**
  String get chooseProjectFolder;

  /// No description provided for @cloneFromGitHub.
  ///
  /// In en, this message translates to:
  /// **'Clone from GitHub'**
  String get cloneFromGitHub;

  /// No description provided for @cloneSetWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Clone a repository and set it as workspace'**
  String get cloneSetWorkspace;

  /// No description provided for @recentWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Recent Workspaces'**
  String get recentWorkspaces;

  /// No description provided for @pleaseEnterRepoUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a repository URL'**
  String get pleaseEnterRepoUrl;

  /// No description provided for @selectFolderToClone.
  ///
  /// In en, this message translates to:
  /// **'Select folder to clone into'**
  String get selectFolderToClone;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @personNotFound.
  ///
  /// In en, this message translates to:
  /// **'Person not found'**
  String get personNotFound;

  /// No description provided for @planNotFound.
  ///
  /// In en, this message translates to:
  /// **'Plan not found'**
  String get planNotFound;

  /// No description provided for @requestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Request not found'**
  String get requestNotFound;

  /// No description provided for @smartActions.
  ///
  /// In en, this message translates to:
  /// **'Smart Actions'**
  String get smartActions;

  /// No description provided for @customPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Prompt'**
  String get customPromptTitle;

  /// No description provided for @enterYourInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your instruction...'**
  String get enterYourInstruction;

  /// No description provided for @workflowEditor.
  ///
  /// In en, this message translates to:
  /// **'Workflow Editor'**
  String get workflowEditor;

  /// No description provided for @configureWorkflowDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure skills, agents, and hooks. Toggle items on/off and reorder by dragging.'**
  String get configureWorkflowDesc;

  /// No description provided for @hooks.
  ///
  /// In en, this message translates to:
  /// **'Hooks'**
  String get hooks;

  /// No description provided for @generatedPreview.
  ///
  /// In en, this message translates to:
  /// **'Generated Preview'**
  String get generatedPreview;

  /// No description provided for @settingUpWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Setting up your workspace...'**
  String get settingUpWorkspace;

  /// No description provided for @orchestraIsReady.
  ///
  /// In en, this message translates to:
  /// **'Orchestra is ready!'**
  String get orchestraIsReady;

  /// No description provided for @installationFailed.
  ///
  /// In en, this message translates to:
  /// **'Installation failed'**
  String get installationFailed;

  /// No description provided for @changeIcon.
  ///
  /// In en, this message translates to:
  /// **'Change Icon'**
  String get changeIcon;

  /// No description provided for @changeColor.
  ///
  /// In en, this message translates to:
  /// **'Change Color'**
  String get changeColor;

  /// No description provided for @syncWithTeam.
  ///
  /// In en, this message translates to:
  /// **'Sync with Team'**
  String get syncWithTeam;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @exportToWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Export to Workspace'**
  String get exportToWorkspace;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @exportAsDocument.
  ///
  /// In en, this message translates to:
  /// **'Export as Document'**
  String get exportAsDocument;

  /// No description provided for @exportAsHtml.
  ///
  /// In en, this message translates to:
  /// **'Export as HTML'**
  String get exportAsHtml;

  /// No description provided for @exportAsMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get exportAsMarkdown;

  /// No description provided for @exportAsPlainText.
  ///
  /// In en, this message translates to:
  /// **'Export as Plain Text'**
  String get exportAsPlainText;

  /// No description provided for @enterNewName.
  ///
  /// In en, this message translates to:
  /// **'Enter new name'**
  String get enterNewName;

  /// No description provided for @shareEntityTitle.
  ///
  /// In en, this message translates to:
  /// **'Share {entityType}'**
  String shareEntityTitle(String entityType);

  /// No description provided for @selectTeamAndShare.
  ///
  /// In en, this message translates to:
  /// **'Select a team and choose who to share with'**
  String get selectTeamAndShare;

  /// No description provided for @noTeamsFound.
  ///
  /// In en, this message translates to:
  /// **'No teams found'**
  String get noTeamsFound;

  /// No description provided for @joinOrCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Join or create a team to start sharing'**
  String get joinOrCreateTeam;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @shareWithEntireTeam.
  ///
  /// In en, this message translates to:
  /// **'Share with entire team'**
  String get shareWithEntireTeam;

  /// No description provided for @searchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search members...'**
  String get searchMembers;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get noMembersFound;

  /// No description provided for @permission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// No description provided for @readPermission.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readPermission;

  /// No description provided for @writePermission.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get writePermission;

  /// No description provided for @syncConflict.
  ///
  /// In en, this message translates to:
  /// **'Sync Conflict'**
  String get syncConflict;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @pulling.
  ///
  /// In en, this message translates to:
  /// **'Pulling...'**
  String get pulling;

  /// No description provided for @pullUpdates.
  ///
  /// In en, this message translates to:
  /// **'Pull Updates'**
  String get pullUpdates;

  /// No description provided for @alreadyUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get alreadyUpToDate;

  /// No description provided for @pulledUpdatesCount.
  ///
  /// In en, this message translates to:
  /// **'Pulled {count} update(s) successfully'**
  String pulledUpdatesCount(int count);

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// No description provided for @disableWordWrap.
  ///
  /// In en, this message translates to:
  /// **'Disable word wrap'**
  String get disableWordWrap;

  /// No description provided for @enableWordWrap.
  ///
  /// In en, this message translates to:
  /// **'Enable word wrap'**
  String get enableWordWrap;

  /// No description provided for @saveAsFile.
  ///
  /// In en, this message translates to:
  /// **'Save as file'**
  String get saveAsFile;

  /// No description provided for @saveAsImage.
  ///
  /// In en, this message translates to:
  /// **'Save as image'**
  String get saveAsImage;

  /// No description provided for @convertToMermaid.
  ///
  /// In en, this message translates to:
  /// **'Convert to Mermaid'**
  String get convertToMermaid;

  /// No description provided for @copyAsText.
  ///
  /// In en, this message translates to:
  /// **'Copy as text'**
  String get copyAsText;

  /// No description provided for @exportAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportAsCsv;

  /// No description provided for @exportAsExcelTsv.
  ///
  /// In en, this message translates to:
  /// **'Export as Excel (TSV)'**
  String get exportAsExcelTsv;

  /// No description provided for @exportAsText.
  ///
  /// In en, this message translates to:
  /// **'Export as Text'**
  String get exportAsText;

  /// No description provided for @exportAsImage.
  ///
  /// In en, this message translates to:
  /// **'Export as Image'**
  String get exportAsImage;

  /// No description provided for @smartCreateType.
  ///
  /// In en, this message translates to:
  /// **'Smart Create {type}'**
  String smartCreateType(String type);

  /// No description provided for @describeWhatToCreate.
  ///
  /// In en, this message translates to:
  /// **'Describe what you want to create...'**
  String get describeWhatToCreate;

  /// No description provided for @createManually.
  ///
  /// In en, this message translates to:
  /// **'Create Manually'**
  String get createManually;

  /// No description provided for @writeMarkdownDirectly.
  ///
  /// In en, this message translates to:
  /// **'Write markdown content directly'**
  String get writeMarkdownDirectly;

  /// No description provided for @smartCreateAi.
  ///
  /// In en, this message translates to:
  /// **'Smart Create (AI)'**
  String get smartCreateAi;

  /// No description provided for @describeNeedAiGenerates.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need, AI generates it'**
  String get describeNeedAiGenerates;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @teamUpdatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Your team has {count} update(s) available'**
  String teamUpdatesAvailable(int count);

  /// No description provided for @conflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get conflict;

  /// No description provided for @exportMarkdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Export Markdown'**
  String get exportMarkdownLabel;

  /// No description provided for @selectWorkspaceFolder.
  ///
  /// In en, this message translates to:
  /// **'Select workspace folder'**
  String get selectWorkspaceFolder;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hr ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @regex.
  ///
  /// In en, this message translates to:
  /// **'Regex'**
  String get regex;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinks;

  /// No description provided for @recentUsers.
  ///
  /// In en, this message translates to:
  /// **'Recent Users'**
  String get recentUsers;

  /// No description provided for @noRecentUsers.
  ///
  /// In en, this message translates to:
  /// **'No recent users'**
  String get noRecentUsers;

  /// No description provided for @failedToLoadOverview.
  ///
  /// In en, this message translates to:
  /// **'Failed to load overview'**
  String get failedToLoadOverview;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @nCategories.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String nCategories(int count);

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategories;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @noCategoriesMatch.
  ///
  /// In en, this message translates to:
  /// **'No categories match \"{query}\"'**
  String noCategoriesMatch(String query);

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @nItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String nItems(int count);

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @nCommunityPosts.
  ///
  /// In en, this message translates to:
  /// **'{count} community posts'**
  String nCommunityPosts(int count);

  /// No description provided for @searchCommunityPosts.
  ///
  /// In en, this message translates to:
  /// **'Search community posts...'**
  String get searchCommunityPosts;

  /// No description provided for @noCommunityPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No community posts yet'**
  String get noCommunityPostsYet;

  /// No description provided for @noPostsMatch.
  ///
  /// In en, this message translates to:
  /// **'No posts match \"{query}\"'**
  String noPostsMatch(String query);

  /// No description provided for @failedToLoadCommunityPosts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load community posts'**
  String get failedToLoadCommunityPosts;

  /// No description provided for @contactSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Contact Submissions'**
  String get contactSubmissions;

  /// No description provided for @nNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String nNew(int count);

  /// No description provided for @nSubmissionsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} submissions total'**
  String nSubmissionsTotal(int count);

  /// No description provided for @searchSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Search submissions...'**
  String get searchSubmissions;

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet'**
  String get noSubmissionsYet;

  /// No description provided for @noSubmissionsMatch.
  ///
  /// In en, this message translates to:
  /// **'No submissions match \"{query}\"'**
  String noSubmissionsMatch(String query);

  /// No description provided for @failedToLoadSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load submissions'**
  String get failedToLoadSubmissions;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @noSubject.
  ///
  /// In en, this message translates to:
  /// **'No subject'**
  String get noSubject;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// No description provided for @newDocLabel.
  ///
  /// In en, this message translates to:
  /// **'New Doc'**
  String get newDocLabel;

  /// No description provided for @nSectionsNArticles.
  ///
  /// In en, this message translates to:
  /// **'{sections} sections, {articles} articles'**
  String nSectionsNArticles(int sections, int articles);

  /// No description provided for @noDocumentationYet.
  ///
  /// In en, this message translates to:
  /// **'No documentation yet'**
  String get noDocumentationYet;

  /// No description provided for @updatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedDate(String date);

  /// No description provided for @nArticles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String nArticles(int count);

  /// No description provided for @viewSection.
  ///
  /// In en, this message translates to:
  /// **'View section'**
  String get viewSection;

  /// No description provided for @featureFlags.
  ///
  /// In en, this message translates to:
  /// **'Feature Flags'**
  String get featureFlags;

  /// No description provided for @failedToLoadFeatureFlags.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feature flags'**
  String get failedToLoadFeatureFlags;

  /// No description provided for @noFeatureFlagsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No feature flags configured'**
  String get noFeatureFlagsConfigured;

  /// No description provided for @createFlagToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Create a new flag to get started.'**
  String get createFlagToGetStarted;

  /// No description provided for @nOfNFlagsEnabled.
  ///
  /// In en, this message translates to:
  /// **'{enabled} of {total} flags enabled'**
  String nOfNFlagsEnabled(int enabled, int total);

  /// No description provided for @keySnakeCase.
  ///
  /// In en, this message translates to:
  /// **'Key (snake_case)'**
  String get keySnakeCase;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @nOpen.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String nOpen(int count);

  /// No description provided for @nIssuesTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} issues total'**
  String nIssuesTotal(int count);

  /// No description provided for @searchIssues.
  ///
  /// In en, this message translates to:
  /// **'Search issues...'**
  String get searchIssues;

  /// No description provided for @noIssuesFound.
  ///
  /// In en, this message translates to:
  /// **'No issues found'**
  String get noIssuesFound;

  /// No description provided for @noIssuesMatch.
  ///
  /// In en, this message translates to:
  /// **'No issues match \"{query}\"'**
  String noIssuesMatch(String query);

  /// No description provided for @userN.
  ///
  /// In en, this message translates to:
  /// **'User #{id}'**
  String userN(String id);

  /// No description provided for @editStatusPriority.
  ///
  /// In en, this message translates to:
  /// **'Edit status / priority'**
  String get editStatusPriority;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @nStaticPages.
  ///
  /// In en, this message translates to:
  /// **'{count} static pages'**
  String nStaticPages(int count);

  /// No description provided for @noPagesYet.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get noPagesYet;

  /// No description provided for @failedToLoadPages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load pages'**
  String get failedToLoadPages;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @slug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get slug;

  /// No description provided for @editPageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit page'**
  String get editPageTooltip;

  /// No description provided for @deletePageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete page'**
  String get deletePageTooltip;

  /// No description provided for @postsLabel.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get postsLabel;

  /// No description provided for @nPostsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} posts total'**
  String nPostsTotal(int count);

  /// No description provided for @searchPosts.
  ///
  /// In en, this message translates to:
  /// **'Search posts...'**
  String get searchPosts;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @failedToLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts'**
  String get failedToLoadPosts;

  /// No description provided for @sponsors.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get sponsors;

  /// No description provided for @nSponsors.
  ///
  /// In en, this message translates to:
  /// **'{count} sponsors'**
  String nSponsors(int count);

  /// No description provided for @failedToLoadSponsors.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sponsors'**
  String get failedToLoadSponsors;

  /// No description provided for @searchSponsors.
  ///
  /// In en, this message translates to:
  /// **'Search sponsors...'**
  String get searchSponsors;

  /// No description provided for @noSponsorsFound.
  ///
  /// In en, this message translates to:
  /// **'No sponsors found'**
  String get noSponsorsFound;

  /// No description provided for @noSponsorsMatch.
  ///
  /// In en, this message translates to:
  /// **'No sponsors match \"{query}\"'**
  String noSponsorsMatch(String query);

  /// No description provided for @websiteUrl.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get websiteUrl;

  /// No description provided for @logoUrl.
  ///
  /// In en, this message translates to:
  /// **'Logo URL'**
  String get logoUrl;

  /// No description provided for @tierLabel.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get tierLabel;

  /// No description provided for @failedToLoadTeam.
  ///
  /// In en, this message translates to:
  /// **'Failed to load team'**
  String get failedToLoadTeam;

  /// No description provided for @teamIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Team ID: {id}'**
  String teamIdLabel(String id);

  /// No description provided for @backToTeams.
  ///
  /// In en, this message translates to:
  /// **'Back to teams'**
  String get backToTeams;

  /// No description provided for @failedToLoadMembersError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members: {error}'**
  String failedToLoadMembersError(String error);

  /// No description provided for @teamSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Team Settings'**
  String get teamSettingsLabel;

  /// No description provided for @defaultRole.
  ///
  /// In en, this message translates to:
  /// **'Default Role'**
  String get defaultRole;

  /// No description provided for @newMembersJoinAsMember.
  ///
  /// In en, this message translates to:
  /// **'New members join as Member'**
  String get newMembersJoinAsMember;

  /// No description provided for @visibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibilityLabel;

  /// No description provided for @teamVisibleToAll.
  ///
  /// In en, this message translates to:
  /// **'Team is visible to all organization members'**
  String get teamVisibleToAll;

  /// No description provided for @nTeamsTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} teams total'**
  String nTeamsTotal(int count);

  /// No description provided for @searchTeams.
  ///
  /// In en, this message translates to:
  /// **'Search teams...'**
  String get searchTeams;

  /// No description provided for @nMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String nMembers(int count);

  /// No description provided for @nUsersTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} users total'**
  String nUsersTotal(int count);

  /// No description provided for @failedToLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get failedToLoadUsers;

  /// No description provided for @searchNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search name or email...'**
  String get searchNameOrEmail;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get allRoles;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @noMatchingUsers.
  ///
  /// In en, this message translates to:
  /// **'No matching users'**
  String get noMatchingUsers;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get changeRole;

  /// No description provided for @newRole.
  ///
  /// In en, this message translates to:
  /// **'New Role'**
  String get newRole;

  /// No description provided for @updateRole.
  ///
  /// In en, this message translates to:
  /// **'Update Role'**
  String get updateRole;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordCannotBeEmpty;

  /// No description provided for @notificationTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Notification title'**
  String get notificationTitleHint;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @writeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get writeYourMessage;

  /// No description provided for @blockLabel.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockLabel;

  /// No description provided for @unblockLabel.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockLabel;

  /// No description provided for @blockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {name}? They will lose access until unblocked.'**
  String blockUserConfirm(String name);

  /// No description provided for @unblockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock {name}? They will regain access immediately.'**
  String unblockUserConfirm(String name);

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. The user will be permanently removed.'**
  String get deleteUserConfirm;

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteUserTitle(String name);

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'{action} {name}?'**
  String blockUserTitle(String action, String name);

  /// No description provided for @simplePricing.
  ///
  /// In en, this message translates to:
  /// **'Simple, transparent pricing'**
  String get simplePricing;

  /// No description provided for @startFreeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Start free. Upgrade when you need more.'**
  String get startFreeUpgrade;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @proLabel.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proLabel;

  /// No description provided for @teamLabel.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get teamLabel;

  /// No description provided for @getStartedFree.
  ///
  /// In en, this message translates to:
  /// **'Get started free'**
  String get getStartedFree;

  /// No description provided for @startFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'Start free trial'**
  String get startFreeTrial;

  /// No description provided for @contactSales.
  ///
  /// In en, this message translates to:
  /// **'Contact sales'**
  String get contactSales;

  /// No description provided for @forIndividuals.
  ///
  /// In en, this message translates to:
  /// **'For individuals getting started.'**
  String get forIndividuals;

  /// No description provided for @forProfessionals.
  ///
  /// In en, this message translates to:
  /// **'For professional developers.'**
  String get forProfessionals;

  /// No description provided for @forTeams.
  ///
  /// In en, this message translates to:
  /// **'For teams that ship together.'**
  String get forTeams;

  /// No description provided for @upToNProjects.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 projects'**
  String get upToNProjects;

  /// No description provided for @nAiSessions.
  ///
  /// In en, this message translates to:
  /// **'5 AI agent sessions / mo'**
  String get nAiSessions;

  /// No description provided for @basicHealthTracking.
  ///
  /// In en, this message translates to:
  /// **'Basic health tracking'**
  String get basicHealthTracking;

  /// No description provided for @communitySupport.
  ///
  /// In en, this message translates to:
  /// **'Community support'**
  String get communitySupport;

  /// No description provided for @unlimitedProjects.
  ///
  /// In en, this message translates to:
  /// **'Unlimited projects'**
  String get unlimitedProjects;

  /// No description provided for @nAiSessionsPro.
  ///
  /// In en, this message translates to:
  /// **'100 AI agent sessions / mo'**
  String get nAiSessionsPro;

  /// No description provided for @fullHealthTracking.
  ///
  /// In en, this message translates to:
  /// **'Full health & sleep tracking'**
  String get fullHealthTracking;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get prioritySupport;

  /// No description provided for @syncAcrossDevices.
  ///
  /// In en, this message translates to:
  /// **'Sync across all devices'**
  String get syncAcrossDevices;

  /// No description provided for @everythingInPro.
  ///
  /// In en, this message translates to:
  /// **'Everything in Pro'**
  String get everythingInPro;

  /// No description provided for @unlimitedTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Unlimited team members'**
  String get unlimitedTeamMembers;

  /// No description provided for @sharedWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Shared workspaces'**
  String get sharedWorkspaces;

  /// No description provided for @teamAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Team analytics'**
  String get teamAnalytics;

  /// No description provided for @ssoSaml.
  ///
  /// In en, this message translates to:
  /// **'SSO / SAML'**
  String get ssoSaml;

  /// No description provided for @dedicatedSupport.
  ///
  /// In en, this message translates to:
  /// **'Dedicated support'**
  String get dedicatedSupport;

  /// No description provided for @connectedTunnels.
  ///
  /// In en, this message translates to:
  /// **'Connected Tunnels'**
  String get connectedTunnels;

  /// No description provided for @desktopClientsConnected.
  ///
  /// In en, this message translates to:
  /// **'Desktop clients connected via QUIC mTLS tunnel'**
  String get desktopClientsConnected;

  /// No description provided for @connectNew.
  ///
  /// In en, this message translates to:
  /// **'Connect New'**
  String get connectNew;

  /// No description provided for @connectDesktopClient.
  ///
  /// In en, this message translates to:
  /// **'Connect a Desktop Client'**
  String get connectDesktopClient;

  /// No description provided for @installOrchestraDesktop.
  ///
  /// In en, this message translates to:
  /// **'1. Install Orchestra on your desktop:'**
  String get installOrchestraDesktop;

  /// No description provided for @runTunnelCommand.
  ///
  /// In en, this message translates to:
  /// **'2. Run the tunnel command:'**
  String get runTunnelCommand;

  /// No description provided for @clientAppearsAutomatically.
  ///
  /// In en, this message translates to:
  /// **'The client will appear in the dashboard automatically once connected.'**
  String get clientAppearsAutomatically;

  /// No description provided for @failedToLoadTunnels.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tunnels'**
  String get failedToLoadTunnels;

  /// No description provided for @offlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineLabel;

  /// No description provided for @degradedLabel.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get degradedLabel;

  /// No description provided for @machineInformation.
  ///
  /// In en, this message translates to:
  /// **'Machine Information'**
  String get machineInformation;

  /// No description provided for @operatingSystem.
  ///
  /// In en, this message translates to:
  /// **'Operating System'**
  String get operatingSystem;

  /// No description provided for @ipAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// No description provided for @connectedUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Connected User'**
  String get connectedUserLabel;

  /// No description provided for @latencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get latencyLabel;

  /// No description provided for @toolsAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Tools Available'**
  String get toolsAvailableLabel;

  /// No description provided for @lastActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Active'**
  String get lastActiveLabel;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get activeNow;

  /// No description provided for @recentActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Actions'**
  String get recentActionsLabel;

  /// No description provided for @noRecentActions.
  ///
  /// In en, this message translates to:
  /// **'No recent actions'**
  String get noRecentActions;

  /// No description provided for @disconnectedMachine.
  ///
  /// In en, this message translates to:
  /// **'Disconnected {name}'**
  String disconnectedMachine(String name);

  /// No description provided for @workflowMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Workflow Marketplace'**
  String get workflowMarketplace;

  /// No description provided for @discoverWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Discover and install workflow configurations shared by the community'**
  String get discoverWorkflows;

  /// No description provided for @searchWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Search workflows...'**
  String get searchWorkflows;

  /// No description provided for @contentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get contentsLabel;

  /// No description provided for @nRatings.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String nRatings(int count);

  /// No description provided for @nDownloads.
  ///
  /// In en, this message translates to:
  /// **'{count} downloads'**
  String nDownloads(int count);

  /// No description provided for @installingWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Installing \"{name}\"...'**
  String installingWorkflow(String name);

  /// No description provided for @projectManagerLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Manager'**
  String get projectManagerLabel;

  /// No description provided for @publicLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Public link copied to clipboard'**
  String get publicLinkCopiedToClipboard;

  /// No description provided for @nFeaturesDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} features done'**
  String nFeaturesDone(int done, int total);

  /// No description provided for @nNotes.
  ///
  /// In en, this message translates to:
  /// **'{count} notes'**
  String nNotes(int count);

  /// No description provided for @nDocs.
  ///
  /// In en, this message translates to:
  /// **'{count} docs'**
  String nDocs(int count);

  /// No description provided for @noNotesShared.
  ///
  /// In en, this message translates to:
  /// **'No notes shared'**
  String get noNotesShared;

  /// No description provided for @noDocsShared.
  ///
  /// In en, this message translates to:
  /// **'No docs shared'**
  String get noDocsShared;

  /// No description provided for @poweredByOrchestra.
  ///
  /// In en, this message translates to:
  /// **'Powered by Orchestra'**
  String get poweredByOrchestra;

  /// No description provided for @enterCustomInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter custom instruction...'**
  String get enterCustomInstruction;

  /// No description provided for @sentNotifications.
  ///
  /// In en, this message translates to:
  /// **'Sent Notifications'**
  String get sentNotifications;

  /// No description provided for @newNotification.
  ///
  /// In en, this message translates to:
  /// **'New Notification'**
  String get newNotification;

  /// No description provided for @notificationTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Notification title...'**
  String get notificationTitlePlaceholder;

  /// No description provided for @messagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messagePlaceholder;

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target:'**
  String get targetLabel;

  /// No description provided for @nNotificationsSent.
  ///
  /// In en, this message translates to:
  /// **'{count} notifications sent'**
  String nNotificationsSent(int count);

  /// No description provided for @failedToLoadCount.
  ///
  /// In en, this message translates to:
  /// **'Failed to load count'**
  String get failedToLoadCount;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @noNotificationsSentYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications sent yet'**
  String get noNotificationsSentYet;

  /// No description provided for @noNotificationsMatch.
  ///
  /// In en, this message translates to:
  /// **'No notifications match \"{query}\"'**
  String noNotificationsMatch(String query);

  /// No description provided for @searchNotifications.
  ///
  /// In en, this message translates to:
  /// **'Search notifications...'**
  String get searchNotifications;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @failedToLoadUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user'**
  String get failedToLoadUser;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String areYouSureDelete(String name);

  /// No description provided for @areYouSureRemove.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\"? This action cannot be undone.'**
  String areYouSureRemove(String name);

  /// No description provided for @removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeMemberConfirm(String name);

  /// No description provided for @memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String memberRemoved(String name);

  /// No description provided for @teamRenamedTo.
  ///
  /// In en, this message translates to:
  /// **'Team renamed to \"{name}\"'**
  String teamRenamedTo(String name);

  /// No description provided for @sharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shared {entityType} successfully'**
  String sharedSuccessfully(String entityType);

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorWithDetails(String details);

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// No description provided for @longBreak.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreak;

  /// No description provided for @standUp.
  ///
  /// In en, this message translates to:
  /// **'Stand Up!'**
  String get standUp;

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Great job! Daily goal reached.'**
  String get goalReached;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track — keep it up.'**
  String get onTrack;

  /// No description provided for @slightlyBehindMsg.
  ///
  /// In en, this message translates to:
  /// **'Slightly behind — have a glass now.'**
  String get slightlyBehindMsg;

  /// No description provided for @dehydratedMsg.
  ///
  /// In en, this message translates to:
  /// **'Drink water soon — you\'\'re dehydrated.'**
  String get dehydratedMsg;

  /// No description provided for @getItem.
  ///
  /// In en, this message translates to:
  /// **'Get {name}'**
  String getItem(String name);

  /// No description provided for @downloadItem.
  ///
  /// In en, this message translates to:
  /// **'Download {name}'**
  String downloadItem(String name);

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @usersNav.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersNav;

  /// No description provided for @billingNav.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingNav;

  /// No description provided for @analyticsNav.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsNav;

  /// No description provided for @logsNav.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsNav;

  /// No description provided for @pluginsNav.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get pluginsNav;

  /// No description provided for @securityNav.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityNav;

  /// No description provided for @rolesAndPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get rolesAndPermissions;

  /// No description provided for @nRolesNPermissions.
  ///
  /// In en, this message translates to:
  /// **'{roleCount} roles, {permCount} permissions'**
  String nRolesNPermissions(int roleCount, int permCount);

  /// No description provided for @nUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{user} other{users}}'**
  String nUsersLabel(int count);

  /// No description provided for @extensionMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Extension Marketplace'**
  String get extensionMarketplace;

  /// No description provided for @browseInstallManage.
  ///
  /// In en, this message translates to:
  /// **'Browse, install, and manage extensions.\nComing soon.'**
  String get browseInstallManage;

  /// No description provided for @billingTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingTitle;

  /// No description provided for @subscriptionManagement.
  ///
  /// In en, this message translates to:
  /// **'Subscription management, usage meters, and payment\nhistory will appear here once the billing API is available.'**
  String get subscriptionManagement;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// No description provided for @systemLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'System logs, audit trails, and error tracking\nwill appear here once the logging API is available.'**
  String get systemLogsDesc;

  /// No description provided for @pluginsTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get pluginsTitle;

  /// No description provided for @pluginsDesc.
  ///
  /// In en, this message translates to:
  /// **'Plugin installation, configuration, and lifecycle\nmanagement will appear here once the plugin API is available.'**
  String get pluginsDesc;

  /// No description provided for @noAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'No analytics data available'**
  String get noAnalyticsData;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @failedToLoadAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics'**
  String get failedToLoadAnalytics;

  /// No description provided for @totalUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsersLabel;

  /// No description provided for @activeUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsersLabel;

  /// No description provided for @totalProjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get totalProjectsLabel;

  /// No description provided for @totalFeaturesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Features'**
  String get totalFeaturesLabel;

  /// No description provided for @totalTeamsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Teams'**
  String get totalTeamsLabel;

  /// No description provided for @totalNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Notes'**
  String get totalNotesLabel;

  /// No description provided for @totalPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Pages'**
  String get totalPagesLabel;

  /// No description provided for @activeSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessionsLabel;

  /// No description provided for @apiKeysLabel.
  ///
  /// In en, this message translates to:
  /// **'API Keys'**
  String get apiKeysLabel;

  /// No description provided for @sponsorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get sponsorsLabel;

  /// No description provided for @openIssuesLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Issues'**
  String get openIssuesLabel;

  /// No description provided for @contactMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Messages'**
  String get contactMessagesLabel;

  /// No description provided for @storageUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get storageUsedLabel;

  /// No description provided for @apiCalls24hLabel.
  ///
  /// In en, this message translates to:
  /// **'API Calls (24h)'**
  String get apiCalls24hLabel;

  /// No description provided for @errorRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Error Rate'**
  String get errorRateLabel;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @activeSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessionsTitle;

  /// No description provided for @noActiveSessionsFound.
  ///
  /// In en, this message translates to:
  /// **'No active sessions found'**
  String get noActiveSessionsFound;

  /// No description provided for @revokeAllOtherSessions.
  ///
  /// In en, this message translates to:
  /// **'Revoke all other sessions'**
  String get revokeAllOtherSessions;

  /// No description provided for @enforceTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Enforce Two-Factor Authentication'**
  String get enforceTwoFactor;

  /// No description provided for @requireAll2fa.
  ///
  /// In en, this message translates to:
  /// **'Require all users to set up 2FA before accessing the workspace'**
  String get requireAll2fa;

  /// No description provided for @singleSignOnSso.
  ///
  /// In en, this message translates to:
  /// **'Single Sign-On (SSO)'**
  String get singleSignOnSso;

  /// No description provided for @enableSamlSso.
  ///
  /// In en, this message translates to:
  /// **'Enable SAML-based SSO with your identity provider'**
  String get enableSamlSso;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLabel;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get unknownDevice;

  /// No description provided for @revokeSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Revoke session'**
  String get revokeSessionTooltip;

  /// No description provided for @actionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTooltip;

  /// No description provided for @allUsersTarget.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsersTarget;

  /// No description provided for @adminTarget.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTarget;

  /// No description provided for @teamOwnerTarget.
  ///
  /// In en, this message translates to:
  /// **'Team Owner'**
  String get teamOwnerTarget;

  /// No description provided for @teamManagerTarget.
  ///
  /// In en, this message translates to:
  /// **'Team Manager'**
  String get teamManagerTarget;

  /// No description provided for @memberRole.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberRole;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @ownerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerRole;

  /// No description provided for @viewerRole.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get viewerRole;

  /// No description provided for @removeFromTeam.
  ///
  /// In en, this message translates to:
  /// **'Remove from team'**
  String get removeFromTeam;

  /// No description provided for @selectATeam.
  ///
  /// In en, this message translates to:
  /// **'Select a team...'**
  String get selectATeam;

  /// No description provided for @addingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get addingEllipsis;

  /// No description provided for @manageTeams.
  ///
  /// In en, this message translates to:
  /// **'Manage Teams'**
  String get manageTeams;

  /// No description provided for @removeVerification.
  ///
  /// In en, this message translates to:
  /// **'Remove Verification'**
  String get removeVerification;

  /// No description provided for @verifyUser.
  ///
  /// In en, this message translates to:
  /// **'Verify User'**
  String get verifyUser;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @notificationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and message are required'**
  String get notificationTitleRequired;

  /// No description provided for @notificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification message'**
  String get notificationMessage;

  /// No description provided for @insightConsistentHydration.
  ///
  /// In en, this message translates to:
  /// **'Consistent hydration this week'**
  String get insightConsistentHydration;

  /// No description provided for @insightPomodoroStreaks.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro streaks improving focus'**
  String get insightPomodoroStreaks;

  /// No description provided for @insightCleanCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Clean caffeine transition in progress'**
  String get insightCleanCaffeine;

  /// No description provided for @insightCortisolCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Cortisol window caffeine intake detected'**
  String get insightCortisolCaffeine;

  /// No description provided for @insightSleepBelow7h.
  ///
  /// In en, this message translates to:
  /// **'Sleep duration below 7h target'**
  String get insightSleepBelow7h;

  /// No description provided for @insightShutdownViolatedNights.
  ///
  /// In en, this message translates to:
  /// **'Shutdown violated 2 nights this week'**
  String get insightShutdownViolatedNights;

  /// No description provided for @insightDrinkWaterPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Drink 250 ml water before each pomodoro'**
  String get insightDrinkWaterPomodoro;

  /// No description provided for @insightMoveCaffeine.
  ///
  /// In en, this message translates to:
  /// **'Move caffeine intake to after 9:30 AM'**
  String get insightMoveCaffeine;

  /// No description provided for @insightStartShutdownRitual.
  ///
  /// In en, this message translates to:
  /// **'Start shutdown ritual 4h before target sleep'**
  String get insightStartShutdownRitual;

  /// No description provided for @insightNoTriggersDetected.
  ///
  /// In en, this message translates to:
  /// **'No high-risk GERD triggers detected in the last 24h. Continue avoiding raw onion and deep-fried foods.'**
  String get insightNoTriggersDetected;

  /// No description provided for @insightDailyHydrationGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Daily hydration goal reached'**
  String get insightDailyHydrationGoalReached;

  /// No description provided for @insightHydrationAtPercent.
  ///
  /// In en, this message translates to:
  /// **'Hydration at {percent}% of goal'**
  String insightHydrationAtPercent(int percent);

  /// No description provided for @insightDrinkMoreMl.
  ///
  /// In en, this message translates to:
  /// **'Drink {ml} ml more today'**
  String insightDrinkMoreMl(int ml);

  /// No description provided for @insightPomodorosCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} pomodoros completed today'**
  String insightPomodorosCompleted(int count);

  /// No description provided for @insightOnlyFocusSessions.
  ///
  /// In en, this message translates to:
  /// **'Only {count} focus sessions today'**
  String insightOnlyFocusSessions(int count);

  /// No description provided for @insightAimForPomodoros.
  ///
  /// In en, this message translates to:
  /// **'Aim for at least 4 pomodoros to reach flow state'**
  String get insightAimForPomodoros;

  /// No description provided for @insightNutritionSafetyScore.
  ///
  /// In en, this message translates to:
  /// **'Nutrition safety score: {score}%'**
  String insightNutritionSafetyScore(int score);

  /// No description provided for @insightNutritionBelowThreshold.
  ///
  /// In en, this message translates to:
  /// **'Nutrition safety score below threshold: {score}%'**
  String insightNutritionBelowThreshold(int score);

  /// No description provided for @insightShutdownCompleted.
  ///
  /// In en, this message translates to:
  /// **'Shutdown ritual completed on time'**
  String get insightShutdownCompleted;

  /// No description provided for @insightShutdownViolatedLastNight.
  ///
  /// In en, this message translates to:
  /// **'Shutdown ritual was violated last night'**
  String get insightShutdownViolatedLastNight;

  /// No description provided for @insightStartShutdownHours.
  ///
  /// In en, this message translates to:
  /// **'Start shutdown {hours}h before target sleep'**
  String insightStartShutdownHours(String hours);

  /// No description provided for @insightNoTriggerFoods72h.
  ///
  /// In en, this message translates to:
  /// **'No trigger foods detected in the last 72h.'**
  String get insightNoTriggerFoods72h;

  /// No description provided for @insightTriggerFoodsDetected.
  ///
  /// In en, this message translates to:
  /// **'Trigger foods detected: {foods}. Monitor for GERD symptoms over the next 24h.'**
  String insightTriggerFoodsDetected(String foods);

  /// No description provided for @shutdownViolated.
  ///
  /// In en, this message translates to:
  /// **'Shutdown violated'**
  String get shutdownViolated;

  /// No description provided for @shutdownViolatedDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'\'ve stayed up past your shutdown time. Late nights reduce sleep quality and increase next-day fatigue. Try to get to bed as soon as possible.'**
  String get shutdownViolatedDescription;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @heartAndBody.
  ///
  /// In en, this message translates to:
  /// **'Heart & Body'**
  String get heartAndBody;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routines;

  /// No description provided for @trackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trackLabel;

  /// No description provided for @restLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restLabel;

  /// No description provided for @caffeineNoIntake.
  ///
  /// In en, this message translates to:
  /// **'No intake'**
  String get caffeineNoIntake;

  /// No description provided for @caffeineClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get caffeineClean;

  /// No description provided for @caffeineTransitioning.
  ///
  /// In en, this message translates to:
  /// **'Transitioning'**
  String get caffeineTransitioning;

  /// No description provided for @caffeineRedBullDep.
  ///
  /// In en, this message translates to:
  /// **'Red Bull dep.'**
  String get caffeineRedBullDep;

  /// No description provided for @shutdownInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get shutdownInactive;

  /// No description provided for @shutdownActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get shutdownActive;

  /// No description provided for @shutdownPhaseViolated.
  ///
  /// In en, this message translates to:
  /// **'Violated'**
  String get shutdownPhaseViolated;

  /// No description provided for @mealsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} meals · {score}% safe'**
  String mealsCount(int count, String score);

  /// No description provided for @caffeineMgStatus.
  ///
  /// In en, this message translates to:
  /// **'{mg} mg · {status}'**
  String caffeineMgStatus(int mg, String status);

  /// No description provided for @bloodOxygen.
  ///
  /// In en, this message translates to:
  /// **'Blood O₂'**
  String get bloodOxygen;

  /// No description provided for @breathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get breathing;

  /// No description provided for @unitBpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get unitBpm;

  /// No description provided for @unitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unitKcal;

  /// No description provided for @unitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get unitHours;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitBreathsPerMin.
  ///
  /// In en, this message translates to:
  /// **'br/min'**
  String get unitBreathsPerMin;

  /// No description provided for @unitPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get unitPercent;

  /// No description provided for @unitYears.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get unitYears;

  /// No description provided for @noRangeData.
  ///
  /// In en, this message translates to:
  /// **'No range data'**
  String get noRangeData;

  /// No description provided for @heartRateRange.
  ///
  /// In en, this message translates to:
  /// **'Min {min}  Max {max}'**
  String heartRateRange(int min, int max);

  /// No description provided for @connectHealthService.
  ///
  /// In en, this message translates to:
  /// **'Connect to health service'**
  String get connectHealthService;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @insightLowFocus.
  ///
  /// In en, this message translates to:
  /// **'Your focus sessions are low today. Try starting a pomodoro to build momentum.'**
  String get insightLowFocus;

  /// No description provided for @insightLowHydration.
  ///
  /// In en, this message translates to:
  /// **'You are behind on hydration. Have a glass of water now to catch up.'**
  String get insightLowHydration;

  /// No description provided for @insightTriggerFoods.
  ///
  /// In en, this message translates to:
  /// **'Some of today\'\'s meals included trigger foods. Consider safer alternatives.'**
  String get insightTriggerFoods;

  /// No description provided for @insightShutdownNotActive.
  ///
  /// In en, this message translates to:
  /// **'Shutdown routine is not active yet. Set a target sleep time to stay on track.'**
  String get insightShutdownNotActive;

  /// No description provided for @insightKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going — every component adds up.'**
  String get insightKeepGoing;

  /// No description provided for @mlUnit.
  ///
  /// In en, this message translates to:
  /// **'{total} / {goal} ml'**
  String mlUnit(int total, int goal);

  /// No description provided for @plusMl.
  ///
  /// In en, this message translates to:
  /// **'+{ml} ml'**
  String plusMl(int ml);

  /// No description provided for @mlLabel.
  ///
  /// In en, this message translates to:
  /// **'{ml}ml'**
  String mlLabel(int ml);

  /// No description provided for @retryLoadingHydration.
  ///
  /// In en, this message translates to:
  /// **'Retry loading hydration data'**
  String get retryLoadingHydration;

  /// No description provided for @goutFlushDescription.
  ///
  /// In en, this message translates to:
  /// **'Drink at least 1500 ml daily to help flush uric acid and reduce gout flare risk.'**
  String get goutFlushDescription;

  /// No description provided for @hoursMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m ago'**
  String hoursMinutesAgo(int h, int m);

  /// No description provided for @lastDrink.
  ///
  /// In en, this message translates to:
  /// **'Last drink: {time}'**
  String lastDrink(String time);

  /// No description provided for @addMlWater.
  ///
  /// In en, this message translates to:
  /// **'Add {ml} millilitres of water'**
  String addMlWater(int ml);

  /// No description provided for @goalReachedChip.
  ///
  /// In en, this message translates to:
  /// **'Goal Reached'**
  String get goalReachedChip;

  /// No description provided for @onTrackChip.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get onTrackChip;

  /// No description provided for @slightlyBehindChip.
  ///
  /// In en, this message translates to:
  /// **'Slightly Behind'**
  String get slightlyBehindChip;

  /// No description provided for @dehydratedChip.
  ///
  /// In en, this message translates to:
  /// **'Dehydrated'**
  String get dehydratedChip;

  /// No description provided for @caffeineEspresso.
  ///
  /// In en, this message translates to:
  /// **'Espresso'**
  String get caffeineEspresso;

  /// No description provided for @caffeineBlackCoffee.
  ///
  /// In en, this message translates to:
  /// **'Black Coffee'**
  String get caffeineBlackCoffee;

  /// No description provided for @caffeineBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get caffeineBlack;

  /// No description provided for @caffeineColdBrew.
  ///
  /// In en, this message translates to:
  /// **'Cold Brew'**
  String get caffeineColdBrew;

  /// No description provided for @caffeineMatcha.
  ///
  /// In en, this message translates to:
  /// **'Matcha'**
  String get caffeineMatcha;

  /// No description provided for @caffeineGreenTea.
  ///
  /// In en, this message translates to:
  /// **'Green Tea'**
  String get caffeineGreenTea;

  /// No description provided for @caffeineRedBull.
  ///
  /// In en, this message translates to:
  /// **'Red Bull'**
  String get caffeineRedBull;

  /// No description provided for @caffeineOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get caffeineOther;

  /// No description provided for @mgLimit.
  ///
  /// In en, this message translates to:
  /// **'{limit} mg limit'**
  String mgLimit(int limit);

  /// No description provided for @drinksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 drink} other{{count} drinks}}'**
  String drinksCount(int count);

  /// No description provided for @plusMg.
  ///
  /// In en, this message translates to:
  /// **'+{mg} mg'**
  String plusMg(int mg);

  /// No description provided for @moreEntries.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreEntries(int count);

  /// No description provided for @logDrinkSemantic.
  ///
  /// In en, this message translates to:
  /// **'Log {name}, {mg} milligrams'**
  String logDrinkSemantic(String name, int mg);

  /// No description provided for @mgValue.
  ///
  /// In en, this message translates to:
  /// **'{mg} mg'**
  String mgValue(int mg);

  /// No description provided for @noRedBullToday.
  ///
  /// In en, this message translates to:
  /// **'No Red Bull today'**
  String get noRedBullToday;

  /// No description provided for @noRedBullSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Great job staying clean. Keep it going.'**
  String get noRedBullSubtitle;

  /// No description provided for @switchToMatchaRedBull.
  ///
  /// In en, this message translates to:
  /// **'Consider switching to matcha'**
  String get switchToMatchaRedBull;

  /// No description provided for @switchToMatchaRedBullSub.
  ///
  /// In en, this message translates to:
  /// **'Matcha offers sustained energy without the sugar crash.'**
  String get switchToMatchaRedBullSub;

  /// No description provided for @switchToMatcha.
  ///
  /// In en, this message translates to:
  /// **'Switch to matcha'**
  String get switchToMatcha;

  /// No description provided for @switchToMatchaSub.
  ///
  /// In en, this message translates to:
  /// **'L-theanine in matcha pairs with caffeine for calm focus.'**
  String get switchToMatchaSub;

  /// No description provided for @overDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Over the daily limit'**
  String get overDailyLimit;

  /// No description provided for @overDailyLimitSub.
  ///
  /// In en, this message translates to:
  /// **'Consider stopping for today. Your body needs a break.'**
  String get overDailyLimitSub;

  /// No description provided for @pomodoroCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get pomodoroCompleted;

  /// No description provided for @pomodoroTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get pomodoroTarget;

  /// No description provided for @pomodoroCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get pomodoroCycle;

  /// No description provided for @standAlertInstruction.
  ///
  /// In en, this message translates to:
  /// **'Stretch, walk around, and rest your eyes for a moment.'**
  String get standAlertInstruction;

  /// No description provided for @phaseReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get phaseReady;

  /// No description provided for @phaseFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get phaseFocus;

  /// No description provided for @phaseStandUp.
  ///
  /// In en, this message translates to:
  /// **'Stand Up!'**
  String get phaseStandUp;

  /// No description provided for @phaseShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get phaseShortBreak;

  /// No description provided for @phaseLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get phaseLongBreak;

  /// No description provided for @resetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTooltip;

  /// No description provided for @skipToBreak.
  ///
  /// In en, this message translates to:
  /// **'Skip to break'**
  String get skipToBreak;

  /// No description provided for @targetReached.
  ///
  /// In en, this message translates to:
  /// **'Target Reached!'**
  String get targetReached;

  /// No description provided for @targetReachedMsg.
  ///
  /// In en, this message translates to:
  /// **'You completed {count} sessions today. Outstanding focus!'**
  String targetReachedMsg(int count);

  /// No description provided for @readyToFocus.
  ///
  /// In en, this message translates to:
  /// **'Ready to Focus'**
  String get readyToFocus;

  /// No description provided for @readyToFocusMsg.
  ///
  /// In en, this message translates to:
  /// **'Start your first session to build momentum today.'**
  String get readyToFocusMsg;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost There!'**
  String get almostThere;

  /// No description provided for @almostThereMsg.
  ///
  /// In en, this message translates to:
  /// **'Just 1 more session to hit your daily target.'**
  String get almostThereMsg;

  /// No description provided for @strongProgress.
  ///
  /// In en, this message translates to:
  /// **'Strong Progress'**
  String get strongProgress;

  /// No description provided for @strongProgressMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} more to reach your target. Keep going!'**
  String strongProgressMsg(int count);

  /// No description provided for @deepFocus.
  ///
  /// In en, this message translates to:
  /// **'Deep Focus'**
  String get deepFocus;

  /// No description provided for @deepFocusMsg.
  ///
  /// In en, this message translates to:
  /// **'Stay in the zone. {count} sessions left for today.'**
  String deepFocusMsg(int count);

  /// No description provided for @recharging.
  ///
  /// In en, this message translates to:
  /// **'Recharging'**
  String get recharging;

  /// No description provided for @rechargingMsg.
  ///
  /// In en, this message translates to:
  /// **'Good rest makes better focus. {count} sessions remain.'**
  String rechargingMsg(int count);

  /// No description provided for @stayConsistent.
  ///
  /// In en, this message translates to:
  /// **'Stay Consistent'**
  String get stayConsistent;

  /// No description provided for @stayConsistentMsg.
  ///
  /// In en, this message translates to:
  /// **'{count} more sessions to reach your daily target.'**
  String stayConsistentMsg(int count);

  /// Warning shown when rice portion exceeds 5 spoons
  ///
  /// In en, this message translates to:
  /// **'Max rice rule triggered (>5 spoons)'**
  String get maxRiceRuleTriggered;

  /// Number of nutrition items logged today
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item logged today} other{{count} items logged today}}'**
  String itemsLoggedToday(int count);

  /// Denominator label for the safety score gauge
  ///
  /// In en, this message translates to:
  /// **'/100'**
  String get outOf100;

  /// Status label when nutrition safety score is high
  ///
  /// In en, this message translates to:
  /// **'All Safe'**
  String get nutritionAllSafe;

  /// Status label when nutrition safety score is medium
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get nutritionWarning;

  /// Status label when nutrition safety score is low
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get nutritionCritical;

  /// Label for irritable bowel syndrome trigger condition
  ///
  /// In en, this message translates to:
  /// **'IBS'**
  String get conditionIbs;

  /// Label for gastroesophageal reflux disease trigger condition
  ///
  /// In en, this message translates to:
  /// **'GERD'**
  String get conditionGerd;

  /// Label for gout trigger condition
  ///
  /// In en, this message translates to:
  /// **'Gout'**
  String get conditionGout;

  /// Label for fatty liver trigger condition
  ///
  /// In en, this message translates to:
  /// **'Fatty Liver'**
  String get conditionFattyLiver;

  /// Nutrition category label for protein
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get categoryProtein;

  /// Nutrition category label for carbohydrates
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get categoryCarbs;

  /// Nutrition category label for fats
  ///
  /// In en, this message translates to:
  /// **'Fats'**
  String get categoryFats;

  /// Nutrition category label for drinks
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get categoryDrinks;

  /// Nutrition category label for snacks
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnacks;

  /// Portion size in spoons for meal logging
  ///
  /// In en, this message translates to:
  /// **'Portion: {spoons} spoons'**
  String portionSpoons(String spoons);

  /// Pluralized item count used in nutrition category breakdown
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String nItemsPlural(int count);

  /// No description provided for @routineStopScreens.
  ///
  /// In en, this message translates to:
  /// **'Stop screens'**
  String get routineStopScreens;

  /// No description provided for @routineStopScreensSub.
  ///
  /// In en, this message translates to:
  /// **'Put away phone, close laptop'**
  String get routineStopScreensSub;

  /// No description provided for @routineJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get routineJournal;

  /// No description provided for @routineJournalSub.
  ///
  /// In en, this message translates to:
  /// **'Write down 3 things you are grateful for'**
  String get routineJournalSub;

  /// No description provided for @routineStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get routineStretch;

  /// No description provided for @routinePrepareClothes.
  ///
  /// In en, this message translates to:
  /// **'Prepare clothes'**
  String get routinePrepareClothes;

  /// No description provided for @routinePrepareClotheseSub.
  ///
  /// In en, this message translates to:
  /// **'Set out tomorrow\'\'s outfit'**
  String get routinePrepareClotheseSub;

  /// No description provided for @routineDimLights.
  ///
  /// In en, this message translates to:
  /// **'Dim lights'**
  String get routineDimLights;

  /// No description provided for @routineDimLightsSub.
  ///
  /// In en, this message translates to:
  /// **'Switch to warm, low lighting'**
  String get routineDimLightsSub;

  /// No description provided for @routineBrushTeeth.
  ///
  /// In en, this message translates to:
  /// **'Brush teeth'**
  String get routineBrushTeeth;

  /// No description provided for @routineBrushTeethSub.
  ///
  /// In en, this message translates to:
  /// **'Oral hygiene before bed'**
  String get routineBrushTeethSub;

  /// No description provided for @routineHerbalTea.
  ///
  /// In en, this message translates to:
  /// **'Herbal tea'**
  String get routineHerbalTea;

  /// No description provided for @routineHerbalTeaSub.
  ///
  /// In en, this message translates to:
  /// **'Chamomile or anise tea'**
  String get routineHerbalTeaSub;

  /// No description provided for @routineRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get routineRead;

  /// No description provided for @highFlareRisk.
  ///
  /// In en, this message translates to:
  /// **'High flare risk -- avoid lying down for 3 hours after eating.'**
  String get highFlareRisk;

  /// No description provided for @moderateFlareRisk.
  ///
  /// In en, this message translates to:
  /// **'Moderate flare risk -- monitor symptoms.'**
  String get moderateFlareRisk;

  /// No description provided for @shutdownEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Start your shutdown routine to prepare for restful sleep. The checklist below will guide you through each step.'**
  String get shutdownEmptyState;

  /// No description provided for @shutdownNotActive.
  ///
  /// In en, this message translates to:
  /// **'Not Active'**
  String get shutdownNotActive;

  /// No description provided for @shutdownActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Shutdown Active'**
  String get shutdownActiveLabel;

  /// No description provided for @shutdownViolatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Violated'**
  String get shutdownViolatedLabel;

  /// BMI category for underweight
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiUnderweight;

  /// BMI category for normal weight
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bmiNormal;

  /// BMI category for overweight
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiOverweight;

  /// BMI category for obese
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get bmiObese;

  /// Body Mass Index label
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmiLabel;

  /// Height input label in centimeters
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// Hint when HealthKit is not connected
  ///
  /// In en, this message translates to:
  /// **'You can still log weight manually below.'**
  String get logWeightManually;

  /// Caption under HealthKit weight value
  ///
  /// In en, this message translates to:
  /// **'Latest reading from Apple Health'**
  String get latestFromAppleHealth;

  /// Trends feature pill label
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// Weight trend label when weight is stable
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get trendStable;

  /// Minimum statistic label
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get statMin;

  /// Maximum statistic label
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get statMax;

  /// Average statistic label
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get statAvg;

  /// Entry count statistic label
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get statEntries;

  /// Sleep quality rating 1
  ///
  /// In en, this message translates to:
  /// **'Very Poor'**
  String get sleepVeryPoor;

  /// Sleep quality rating 2
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepPoor;

  /// Sleep quality rating 3
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get sleepFair;

  /// Sleep quality rating 4
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get sleepGood;

  /// Sleep quality rating 5
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get sleepExcellent;

  /// HealthKit sleep label for 7-9 hours
  ///
  /// In en, this message translates to:
  /// **'Good rest'**
  String get goodRest;

  /// HealthKit sleep label for 6-7 hours
  ///
  /// In en, this message translates to:
  /// **'Could be better'**
  String get couldBeBetter;

  /// HealthKit sleep label for under 6 hours
  ///
  /// In en, this message translates to:
  /// **'Sleep deficit'**
  String get sleepDeficit;

  /// Empty state instruction for sleep tab
  ///
  /// In en, this message translates to:
  /// **'Set your bedtime and wake time above, then tap\n\"Log Sleep\" to start tracking your rest patterns.'**
  String get sleepEmptyState;

  /// Sleep schedule consistency label for high score
  ///
  /// In en, this message translates to:
  /// **'Consistent'**
  String get scheduleConsistent;

  /// Sleep schedule consistency label for medium score
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get scheduleVariable;

  /// Sleep schedule consistency label for low score
  ///
  /// In en, this message translates to:
  /// **'Irregular'**
  String get scheduleIrregular;

  /// Insight text for consistent sleep schedule
  ///
  /// In en, this message translates to:
  /// **'Your sleep and wake times are very consistent. This supports a strong circadian rhythm.'**
  String get scheduleConsistentMsg;

  /// Insight text for variable sleep schedule
  ///
  /// In en, this message translates to:
  /// **'Your schedule varies moderately. Try to go to bed and wake up at the same time each day.'**
  String get scheduleVariableMsg;

  /// Insight text for irregular sleep schedule
  ///
  /// In en, this message translates to:
  /// **'Your sleep schedule is quite irregular. Inconsistent timing can reduce sleep quality.'**
  String get scheduleIrregularMsg;

  /// Average duration statistic label
  ///
  /// In en, this message translates to:
  /// **'Avg Duration'**
  String get avgDuration;

  /// Average quality statistic label
  ///
  /// In en, this message translates to:
  /// **'Avg Quality'**
  String get avgQuality;

  /// Duration quality label for 7-9 hours
  ///
  /// In en, this message translates to:
  /// **'Optimal sleep duration'**
  String get optimalSleep;

  /// Duration quality label for 6-7 hours
  ///
  /// In en, this message translates to:
  /// **'Slightly below recommended'**
  String get belowRecommended;

  /// Duration quality label for under 6 hours
  ///
  /// In en, this message translates to:
  /// **'Too little sleep'**
  String get tooLittleSleep;

  /// Duration quality label for over 9 hours
  ///
  /// In en, this message translates to:
  /// **'More than needed'**
  String get moreThanNeeded;

  /// No description provided for @routineStretchSub.
  ///
  /// In en, this message translates to:
  /// **'5-minute gentle stretching routine'**
  String get routineStretchSub;

  /// No description provided for @routineReadSub.
  ///
  /// In en, this message translates to:
  /// **'10-15 minutes of light reading'**
  String get routineReadSub;

  /// No description provided for @drinkWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get drinkWater;

  /// No description provided for @drinkChamomileTea.
  ///
  /// In en, this message translates to:
  /// **'Chamomile Tea'**
  String get drinkChamomileTea;

  /// No description provided for @drinkAniseTea.
  ///
  /// In en, this message translates to:
  /// **'Anise Tea'**
  String get drinkAniseTea;

  /// No description provided for @logAtLeast2Entries.
  ///
  /// In en, this message translates to:
  /// **'Log at least 2 entries to see trends'**
  String get logAtLeast2Entries;

  /// No description provided for @weightEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Track your weight over time to see trends, BMI changes, and weekly insights.'**
  String get weightEmptyDescription;

  /// No description provided for @sleepTarget.
  ///
  /// In en, this message translates to:
  /// **'target: {hours}h'**
  String sleepTarget(int hours);

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get planned;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get archived;

  /// No description provided for @projectsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} projects'**
  String projectsCount(int count);

  /// No description provided for @noFeatures.
  ///
  /// In en, this message translates to:
  /// **'No features'**
  String get noFeatures;

  /// No description provided for @noPlans.
  ///
  /// In en, this message translates to:
  /// **'No plans'**
  String get noPlans;

  /// No description provided for @noRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get noRequests;

  /// No description provided for @noPersons.
  ///
  /// In en, this message translates to:
  /// **'No persons'**
  String get noPersons;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionChangeIcon.
  ///
  /// In en, this message translates to:
  /// **'Change Icon'**
  String get actionChangeIcon;

  /// No description provided for @actionChangeColor.
  ///
  /// In en, this message translates to:
  /// **'Change Color'**
  String get actionChangeColor;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get actionPublish;

  /// No description provided for @actionExportToWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Export to Workspace'**
  String get actionExportToWorkspace;

  /// No description provided for @actionExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get actionExportPdf;

  /// No description provided for @actionExportDocument.
  ///
  /// In en, this message translates to:
  /// **'Export as Document'**
  String get actionExportDocument;

  /// No description provided for @actionExportHtml.
  ///
  /// In en, this message translates to:
  /// **'Export as HTML'**
  String get actionExportHtml;

  /// No description provided for @actionExportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export Markdown'**
  String get actionExportMarkdown;

  /// No description provided for @actionExportPlainText.
  ///
  /// In en, this message translates to:
  /// **'Export as Plain Text'**
  String get actionExportPlainText;

  /// No description provided for @actionSyncWithTeam.
  ///
  /// In en, this message translates to:
  /// **'Sync with Team'**
  String get actionSyncWithTeam;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose Icon'**
  String get chooseIcon;

  /// No description provided for @chooseColour.
  ///
  /// In en, this message translates to:
  /// **'Choose Colour'**
  String get chooseColour;

  /// Hint text for searching agents
  ///
  /// In en, this message translates to:
  /// **'Search agents...'**
  String get searchAgents;

  /// Hint text for searching skills
  ///
  /// In en, this message translates to:
  /// **'Search skills...'**
  String get searchSkills;

  /// Hint text for searching documents
  ///
  /// In en, this message translates to:
  /// **'Search docs...'**
  String get searchDocs;

  /// Hint text for searching delegations
  ///
  /// In en, this message translates to:
  /// **'Search delegations...'**
  String get searchDelegations;

  /// Message shown when search yields no results
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noSearchResults(String query);

  /// No description provided for @adminProfileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminProfileName;

  /// No description provided for @adminProfileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get adminProfileNameHint;

  /// No description provided for @adminProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminProfileEmail;

  /// No description provided for @adminProfileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get adminProfileBio;

  /// No description provided for @adminProfileBioHint.
  ///
  /// In en, this message translates to:
  /// **'A short bio...'**
  String get adminProfileBioHint;

  /// No description provided for @adminGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get adminGeneral;

  /// No description provided for @adminSiteName.
  ///
  /// In en, this message translates to:
  /// **'Site Name'**
  String get adminSiteName;

  /// No description provided for @adminSiteNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your site name'**
  String get adminSiteNameHint;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// No description provided for @adminDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'A short description of your site...'**
  String get adminDescriptionHint;

  /// No description provided for @adminSiteUrl.
  ///
  /// In en, this message translates to:
  /// **'Site URL'**
  String get adminSiteUrl;

  /// No description provided for @adminSiteUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get adminSiteUrlHint;

  /// No description provided for @adminSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get adminSupportEmail;

  /// No description provided for @adminSupportEmailHint.
  ///
  /// In en, this message translates to:
  /// **'support@example.com'**
  String get adminSupportEmailHint;

  /// No description provided for @adminTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get adminTimezone;

  /// No description provided for @adminLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get adminLanguage;

  /// No description provided for @adminBranding.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get adminBranding;

  /// No description provided for @adminLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get adminLogo;

  /// No description provided for @adminUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo'**
  String get adminUploadLogo;

  /// No description provided for @adminFavicon.
  ///
  /// In en, this message translates to:
  /// **'Favicon'**
  String get adminFavicon;

  /// No description provided for @adminUploadFavicon.
  ///
  /// In en, this message translates to:
  /// **'Upload Favicon'**
  String get adminUploadFavicon;

  /// No description provided for @adminUploadHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG up to 2MB'**
  String get adminUploadHint;

  /// No description provided for @adminAiConfig.
  ///
  /// In en, this message translates to:
  /// **'AI Configuration'**
  String get adminAiConfig;

  /// No description provided for @adminDefaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default AI Model'**
  String get adminDefaultModel;

  /// No description provided for @adminSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get adminSystemPrompt;

  /// No description provided for @adminSystemPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Default system prompt for agents...'**
  String get adminSystemPromptHint;

  /// No description provided for @adminMaxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max Tokens'**
  String get adminMaxTokens;

  /// No description provided for @adminTemperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get adminTemperature;

  /// No description provided for @adminContactSettings.
  ///
  /// In en, this message translates to:
  /// **'Contact Settings'**
  String get adminContactSettings;

  /// No description provided for @adminContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get adminContactEmail;

  /// No description provided for @adminPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get adminPhone;

  /// No description provided for @adminPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+1 234 567 890'**
  String get adminPhoneHint;

  /// No description provided for @adminAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get adminAddress;

  /// No description provided for @adminAddressHint.
  ///
  /// In en, this message translates to:
  /// **'123 Main St, City, Country'**
  String get adminAddressHint;

  /// No description provided for @adminDisplayOptions.
  ///
  /// In en, this message translates to:
  /// **'Display Options'**
  String get adminDisplayOptions;

  /// No description provided for @adminShowContactForm.
  ///
  /// In en, this message translates to:
  /// **'Show Contact Form'**
  String get adminShowContactForm;

  /// No description provided for @adminShowMap.
  ///
  /// In en, this message translates to:
  /// **'Show Map'**
  String get adminShowMap;

  /// No description provided for @adminDiscordIntegration.
  ///
  /// In en, this message translates to:
  /// **'Discord Integration'**
  String get adminDiscordIntegration;

  /// No description provided for @adminEnableDiscordBot.
  ///
  /// In en, this message translates to:
  /// **'Enable Discord Bot'**
  String get adminEnableDiscordBot;

  /// No description provided for @adminBotToken.
  ///
  /// In en, this message translates to:
  /// **'Bot Token'**
  String get adminBotToken;

  /// No description provided for @adminDiscordBotTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Discord bot token'**
  String get adminDiscordBotTokenHint;

  /// No description provided for @adminServerGuildId.
  ///
  /// In en, this message translates to:
  /// **'Server / Guild ID'**
  String get adminServerGuildId;

  /// No description provided for @adminDefaultChannelId.
  ///
  /// In en, this message translates to:
  /// **'Default Channel ID'**
  String get adminDefaultChannelId;

  /// No description provided for @adminWebhookUrl.
  ///
  /// In en, this message translates to:
  /// **'Webhook URL'**
  String get adminWebhookUrl;

  /// No description provided for @adminDiscordWebhookHint.
  ///
  /// In en, this message translates to:
  /// **'https://discord.com/api/webhooks/...'**
  String get adminDiscordWebhookHint;

  /// No description provided for @adminDownloadUrls.
  ///
  /// In en, this message translates to:
  /// **'Download URLs'**
  String get adminDownloadUrls;

  /// No description provided for @adminPlatformMacos.
  ///
  /// In en, this message translates to:
  /// **'macOS'**
  String get adminPlatformMacos;

  /// No description provided for @adminPlatformWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get adminPlatformWindows;

  /// No description provided for @adminPlatformLinux.
  ///
  /// In en, this message translates to:
  /// **'Linux'**
  String get adminPlatformLinux;

  /// No description provided for @adminReleaseInfo.
  ///
  /// In en, this message translates to:
  /// **'Release Info'**
  String get adminReleaseInfo;

  /// No description provided for @adminVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get adminVersion;

  /// No description provided for @adminReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get adminReleaseNotes;

  /// No description provided for @adminReleaseNotesHint.
  ///
  /// In en, this message translates to:
  /// **'What changed in this release...'**
  String get adminReleaseNotesHint;

  /// No description provided for @adminSmtpConfig.
  ///
  /// In en, this message translates to:
  /// **'SMTP Configuration'**
  String get adminSmtpConfig;

  /// No description provided for @adminSmtpHost.
  ///
  /// In en, this message translates to:
  /// **'SMTP Host'**
  String get adminSmtpHost;

  /// No description provided for @adminSmtpHostHint.
  ///
  /// In en, this message translates to:
  /// **'smtp.example.com'**
  String get adminSmtpHostHint;

  /// No description provided for @adminPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get adminPort;

  /// No description provided for @adminUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get adminUsername;

  /// No description provided for @adminUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'SMTP username'**
  String get adminUsernameHint;

  /// No description provided for @adminPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get adminPasswordLabel;

  /// No description provided for @adminPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'SMTP password'**
  String get adminPasswordHint;

  /// No description provided for @adminSender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get adminSender;

  /// No description provided for @adminFromName.
  ///
  /// In en, this message translates to:
  /// **'From Name'**
  String get adminFromName;

  /// No description provided for @adminFromEmail.
  ///
  /// In en, this message translates to:
  /// **'From Email'**
  String get adminFromEmail;

  /// No description provided for @adminFromEmailHint.
  ///
  /// In en, this message translates to:
  /// **'noreply@example.com'**
  String get adminFromEmailHint;

  /// No description provided for @adminEnableTls.
  ///
  /// In en, this message translates to:
  /// **'Enable TLS'**
  String get adminEnableTls;

  /// No description provided for @adminFeatureFlags.
  ///
  /// In en, this message translates to:
  /// **'Feature Flags'**
  String get adminFeatureFlags;

  /// No description provided for @adminFeatureFlagsDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable platform features globally.'**
  String get adminFeatureFlagsDesc;

  /// No description provided for @adminFlagRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Registrations'**
  String get adminFlagRegistrations;

  /// No description provided for @adminFlagRegistrationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow new user registrations'**
  String get adminFlagRegistrationsDesc;

  /// No description provided for @adminFlagApiAccess.
  ///
  /// In en, this message translates to:
  /// **'API Access'**
  String get adminFlagApiAccess;

  /// No description provided for @adminFlagApiAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable public API access'**
  String get adminFlagApiAccessDesc;

  /// No description provided for @adminFlagDelegations.
  ///
  /// In en, this message translates to:
  /// **'Delegations'**
  String get adminFlagDelegations;

  /// No description provided for @adminFlagDelegationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Multi-agent delegation workflows'**
  String get adminFlagDelegationsDesc;

  /// No description provided for @adminFlagAiSessions.
  ///
  /// In en, this message translates to:
  /// **'AI Sessions'**
  String get adminFlagAiSessions;

  /// No description provided for @adminFlagAiSessionsDesc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered chat sessions'**
  String get adminFlagAiSessionsDesc;

  /// No description provided for @adminFlagHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get adminFlagHealth;

  /// No description provided for @adminFlagHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'System health monitoring'**
  String get adminFlagHealthDesc;

  /// No description provided for @adminFlagRag.
  ///
  /// In en, this message translates to:
  /// **'RAG'**
  String get adminFlagRag;

  /// No description provided for @adminFlagRagDesc.
  ///
  /// In en, this message translates to:
  /// **'Retrieval-augmented generation engine'**
  String get adminFlagRagDesc;

  /// No description provided for @adminFlagMultiAgent.
  ///
  /// In en, this message translates to:
  /// **'Multi-Agent'**
  String get adminFlagMultiAgent;

  /// No description provided for @adminFlagMultiAgentDesc.
  ///
  /// In en, this message translates to:
  /// **'Multi-agent orchestration workflows'**
  String get adminFlagMultiAgentDesc;

  /// No description provided for @adminFlagMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get adminFlagMarketplace;

  /// No description provided for @adminFlagMarketplaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Pack and plugin marketplace'**
  String get adminFlagMarketplaceDesc;

  /// No description provided for @adminFlagQuicBridge.
  ///
  /// In en, this message translates to:
  /// **'QUIC Bridge'**
  String get adminFlagQuicBridge;

  /// No description provided for @adminFlagQuicBridgeDesc.
  ///
  /// In en, this message translates to:
  /// **'QUIC transport for remote plugins'**
  String get adminFlagQuicBridgeDesc;

  /// No description provided for @adminFlagWebGateway.
  ///
  /// In en, this message translates to:
  /// **'Web Gateway'**
  String get adminFlagWebGateway;

  /// No description provided for @adminFlagWebGatewayDesc.
  ///
  /// In en, this message translates to:
  /// **'Public web gateway for external access'**
  String get adminFlagWebGatewayDesc;

  /// No description provided for @adminFlagPacks.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get adminFlagPacks;

  /// No description provided for @adminFlagPacksDesc.
  ///
  /// In en, this message translates to:
  /// **'Installable skill and agent packs'**
  String get adminFlagPacksDesc;

  /// No description provided for @adminFlagProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get adminFlagProjects;

  /// No description provided for @adminFlagProjectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Project management with feature workflow'**
  String get adminFlagProjectsDesc;

  /// No description provided for @adminFlagNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get adminFlagNotes;

  /// No description provided for @adminFlagNotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Markdown notes and quick capture'**
  String get adminFlagNotesDesc;

  /// No description provided for @adminFlagWiki.
  ///
  /// In en, this message translates to:
  /// **'Wiki'**
  String get adminFlagWiki;

  /// No description provided for @adminFlagWikiDesc.
  ///
  /// In en, this message translates to:
  /// **'Collaborative wiki pages'**
  String get adminFlagWikiDesc;

  /// No description provided for @adminFlagDevTools.
  ///
  /// In en, this message translates to:
  /// **'DevTools'**
  String get adminFlagDevTools;

  /// No description provided for @adminFlagDevToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Developer tools and terminal integration'**
  String get adminFlagDevToolsDesc;

  /// No description provided for @adminFlagSponsors.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get adminFlagSponsors;

  /// No description provided for @adminFlagSponsorsDesc.
  ///
  /// In en, this message translates to:
  /// **'Sponsorship and funding display'**
  String get adminFlagSponsorsDesc;

  /// No description provided for @adminFlagCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get adminFlagCommunity;

  /// No description provided for @adminFlagCommunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Community forum and discussions'**
  String get adminFlagCommunityDesc;

  /// No description provided for @adminFlagIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get adminFlagIssues;

  /// No description provided for @adminFlagIssuesDesc.
  ///
  /// In en, this message translates to:
  /// **'Issue tracking and bug reports'**
  String get adminFlagIssuesDesc;

  /// No description provided for @adminGithubIntegration.
  ///
  /// In en, this message translates to:
  /// **'GitHub Integration'**
  String get adminGithubIntegration;

  /// No description provided for @adminEnableGithub.
  ///
  /// In en, this message translates to:
  /// **'Enable GitHub Integration'**
  String get adminEnableGithub;

  /// No description provided for @adminAppId.
  ///
  /// In en, this message translates to:
  /// **'App ID'**
  String get adminAppId;

  /// No description provided for @adminAppIdHint.
  ///
  /// In en, this message translates to:
  /// **'GitHub App ID'**
  String get adminAppIdHint;

  /// No description provided for @adminClientId.
  ///
  /// In en, this message translates to:
  /// **'Client ID'**
  String get adminClientId;

  /// No description provided for @adminClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Client Secret'**
  String get adminClientSecret;

  /// No description provided for @adminClientSecretHint.
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get adminClientSecretHint;

  /// No description provided for @adminWebhookSecret.
  ///
  /// In en, this message translates to:
  /// **'Webhook Secret'**
  String get adminWebhookSecret;

  /// No description provided for @adminWebhookSecretHint.
  ///
  /// In en, this message translates to:
  /// **'Webhook signing secret'**
  String get adminWebhookSecretHint;

  /// No description provided for @adminOauthProviders.
  ///
  /// In en, this message translates to:
  /// **'OAuth Providers'**
  String get adminOauthProviders;

  /// No description provided for @adminOauthProvidersDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure OAuth integrations for user authentication.'**
  String get adminOauthProvidersDesc;

  /// No description provided for @adminEnterClientId.
  ///
  /// In en, this message translates to:
  /// **'Enter client ID'**
  String get adminEnterClientId;

  /// No description provided for @adminEnterClientSecret.
  ///
  /// In en, this message translates to:
  /// **'Enter client secret'**
  String get adminEnterClientSecret;

  /// No description provided for @adminCallbackUrl.
  ///
  /// In en, this message translates to:
  /// **'Callback URL'**
  String get adminCallbackUrl;

  /// No description provided for @adminPricingPlans.
  ///
  /// In en, this message translates to:
  /// **'Pricing Plans'**
  String get adminPricingPlans;

  /// No description provided for @adminPricingPlansDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure the pricing plans displayed on the website.'**
  String get adminPricingPlansDesc;

  /// No description provided for @adminFreePlanName.
  ///
  /// In en, this message translates to:
  /// **'Free Plan Name'**
  String get adminFreePlanName;

  /// No description provided for @adminProPlanName.
  ///
  /// In en, this message translates to:
  /// **'Pro Plan Name'**
  String get adminProPlanName;

  /// No description provided for @adminProPrice.
  ///
  /// In en, this message translates to:
  /// **'Pro Price'**
  String get adminProPrice;

  /// No description provided for @adminEnterprisePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Enterprise Price'**
  String get adminEnterprisePriceLabel;

  /// No description provided for @adminBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get adminBilling;

  /// No description provided for @adminBillingUrl.
  ///
  /// In en, this message translates to:
  /// **'Billing URL'**
  String get adminBillingUrl;

  /// No description provided for @adminBillingUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://billing.example.com'**
  String get adminBillingUrlHint;

  /// No description provided for @adminSmartActionPrompts.
  ///
  /// In en, this message translates to:
  /// **'Smart Action Prompts'**
  String get adminSmartActionPrompts;

  /// No description provided for @adminPromptsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure the system prompts used by the AI Smart Action when generating entities. Each entity type can have a custom prompt that controls the AI output format.'**
  String get adminPromptsDesc;

  /// No description provided for @adminNewPrompt.
  ///
  /// In en, this message translates to:
  /// **'New Prompt'**
  String get adminNewPrompt;

  /// No description provided for @adminPromptKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get adminPromptKey;

  /// No description provided for @adminPromptKeyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. agent'**
  String get adminPromptKeyHint;

  /// No description provided for @adminPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get adminPromptLabel;

  /// No description provided for @adminPromptLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Agent'**
  String get adminPromptLabelHint;

  /// No description provided for @adminPromptDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminPromptDescription;

  /// No description provided for @adminPromptDescHint.
  ///
  /// In en, this message translates to:
  /// **'What this prompt does...'**
  String get adminPromptDescHint;

  /// No description provided for @adminPromptSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get adminPromptSystemPrompt;

  /// No description provided for @adminPromptSystemPromptHint.
  ///
  /// In en, this message translates to:
  /// **'The system prompt sent to the AI...'**
  String get adminPromptSystemPromptHint;

  /// No description provided for @adminMetaTags.
  ///
  /// In en, this message translates to:
  /// **'Meta Tags'**
  String get adminMetaTags;

  /// No description provided for @adminMetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Meta Title'**
  String get adminMetaTitle;

  /// No description provided for @adminMetaTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Page title for search engines'**
  String get adminMetaTitleHint;

  /// No description provided for @adminMetaDescription.
  ///
  /// In en, this message translates to:
  /// **'Meta Description'**
  String get adminMetaDescription;

  /// No description provided for @adminMetaDescHint.
  ///
  /// In en, this message translates to:
  /// **'Page description for search engines...'**
  String get adminMetaDescHint;

  /// No description provided for @adminOgImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Open Graph Image URL'**
  String get adminOgImageUrl;

  /// No description provided for @adminSitemap.
  ///
  /// In en, this message translates to:
  /// **'Sitemap'**
  String get adminSitemap;

  /// No description provided for @adminAutoGenerateSitemap.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate Sitemap'**
  String get adminAutoGenerateSitemap;

  /// No description provided for @adminRobotsTxt.
  ///
  /// In en, this message translates to:
  /// **'robots.txt'**
  String get adminRobotsTxt;

  /// No description provided for @adminSlackIntegration.
  ///
  /// In en, this message translates to:
  /// **'Slack Integration'**
  String get adminSlackIntegration;

  /// No description provided for @adminEnableSlackBot.
  ///
  /// In en, this message translates to:
  /// **'Enable Slack Bot'**
  String get adminEnableSlackBot;

  /// No description provided for @adminSlackBotTokenHint.
  ///
  /// In en, this message translates to:
  /// **'xoxb-...'**
  String get adminSlackBotTokenHint;

  /// No description provided for @adminSigningSecret.
  ///
  /// In en, this message translates to:
  /// **'Signing Secret'**
  String get adminSigningSecret;

  /// No description provided for @adminSigningSecretHint.
  ///
  /// In en, this message translates to:
  /// **'Slack signing secret'**
  String get adminSigningSecretHint;

  /// No description provided for @adminSlackWebhookHint.
  ///
  /// In en, this message translates to:
  /// **'https://hooks.slack.com/services/...'**
  String get adminSlackWebhookHint;

  /// No description provided for @adminSocialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get adminSocialLinks;

  /// No description provided for @adminSocialLinksDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage social platform links displayed on the website.'**
  String get adminSocialLinksDesc;

  /// No description provided for @adminHeroSection.
  ///
  /// In en, this message translates to:
  /// **'Hero Section'**
  String get adminHeroSection;

  /// No description provided for @adminHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Hero Title'**
  String get adminHeroTitle;

  /// No description provided for @adminHeroTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Main headline'**
  String get adminHeroTitleHint;

  /// No description provided for @adminHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hero Subtitle'**
  String get adminHeroSubtitle;

  /// No description provided for @adminHeroSubtitleHint.
  ///
  /// In en, this message translates to:
  /// **'Supporting text...'**
  String get adminHeroSubtitleHint;

  /// No description provided for @adminCallToAction.
  ///
  /// In en, this message translates to:
  /// **'Call to Action'**
  String get adminCallToAction;

  /// No description provided for @adminButtonText.
  ///
  /// In en, this message translates to:
  /// **'Button Text'**
  String get adminButtonText;

  /// No description provided for @adminButtonTextHint.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get adminButtonTextHint;

  /// No description provided for @adminButtonUrl.
  ///
  /// In en, this message translates to:
  /// **'Button URL'**
  String get adminButtonUrl;

  /// No description provided for @adminSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get adminSections;

  /// No description provided for @adminShowFeaturesSection.
  ///
  /// In en, this message translates to:
  /// **'Show Features Section'**
  String get adminShowFeaturesSection;

  /// No description provided for @adminShowTestimonialsSection.
  ///
  /// In en, this message translates to:
  /// **'Show Testimonials Section'**
  String get adminShowTestimonialsSection;

  /// No description provided for @adminHeroImage.
  ///
  /// In en, this message translates to:
  /// **'Hero Image'**
  String get adminHeroImage;

  /// No description provided for @adminUploadHeroImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Hero Image'**
  String get adminUploadHeroImage;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsPasswordNav.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPasswordNav;

  /// No description provided for @settingsSocialNav.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get settingsSocialNav;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsTwoFactor.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Auth'**
  String get settingsTwoFactor;

  /// No description provided for @settingsPasskeys.
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get settingsPasskeys;

  /// No description provided for @settingsSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get settingsSessions;

  /// No description provided for @settingsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get settingsFeatures;

  /// No description provided for @settingsNotificationsNav.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsNav;

  /// No description provided for @settingsHealthNav.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get settingsHealthNav;

  /// No description provided for @settingsIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsIntegrations;

  /// No description provided for @settingsDesktop.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get settingsDesktop;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// No description provided for @settingsApiTokens.
  ///
  /// In en, this message translates to:
  /// **'API Tokens'**
  String get settingsApiTokens;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get settingsReportIssue;

  /// No description provided for @settingsAgentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Agent Instructions'**
  String get settingsAgentInstructions;

  /// No description provided for @settingsAgentInstructionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage CLAUDE.md sections for AI agent behavior'**
  String get settingsAgentInstructionsDesc;

  /// No description provided for @settingsClaudeSettings.
  ///
  /// In en, this message translates to:
  /// **'Claude Settings'**
  String get settingsClaudeSettings;

  /// No description provided for @settingsClaudeSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure .claude/settings.json for Claude Code'**
  String get settingsClaudeSettingsDesc;

  /// No description provided for @agentInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agent Instructions'**
  String get agentInstructionsTitle;

  /// No description provided for @agentInstructionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No CLAUDE.md found. Add a section to get started.'**
  String get agentInstructionsEmpty;

  /// No description provided for @agentInstructionsSaved.
  ///
  /// In en, this message translates to:
  /// **'Agent instructions saved'**
  String get agentInstructionsSaved;

  /// No description provided for @agentInstructionsAddSection.
  ///
  /// In en, this message translates to:
  /// **'Add section'**
  String get agentInstructionsAddSection;

  /// No description provided for @agentInstructionsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Section title'**
  String get agentInstructionsSectionTitle;

  /// No description provided for @agentInstructionsContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content (markdown)'**
  String get agentInstructionsContentLabel;

  /// No description provided for @claudeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Claude Settings'**
  String get claudeSettingsTitle;

  /// No description provided for @claudeSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Claude settings saved'**
  String get claudeSettingsSaved;

  /// No description provided for @claudeSettingsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get claudeSettingsModel;

  /// No description provided for @claudeSettingsMaxTurns.
  ///
  /// In en, this message translates to:
  /// **'Max turns'**
  String get claudeSettingsMaxTurns;

  /// No description provided for @claudeSettingsPermissions.
  ///
  /// In en, this message translates to:
  /// **'Tool Permissions'**
  String get claudeSettingsPermissions;

  /// No description provided for @claudeSettingsAllowedTools.
  ///
  /// In en, this message translates to:
  /// **'Allowed Tools'**
  String get claudeSettingsAllowedTools;

  /// No description provided for @claudeSettingsNoRestrictions.
  ///
  /// In en, this message translates to:
  /// **'No tool restrictions (all tools allowed)'**
  String get claudeSettingsNoRestrictions;

  /// No description provided for @claudeSettingsAddTool.
  ///
  /// In en, this message translates to:
  /// **'Add tool'**
  String get claudeSettingsAddTool;

  /// No description provided for @claudeSettingsAddToolTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Allowed Tool'**
  String get claudeSettingsAddToolTitle;

  /// No description provided for @claudeSettingsAddToolHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. mcp__orchestra__*'**
  String get claudeSettingsAddToolHint;

  /// No description provided for @userSettingsSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings Sync'**
  String get userSettingsSyncTitle;

  /// No description provided for @userSettingsSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Your settings sync across all devices via PowerSync'**
  String get userSettingsSyncDesc;

  /// No description provided for @settingsAdministration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get settingsAdministration;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsHomepage.
  ///
  /// In en, this message translates to:
  /// **'Homepage'**
  String get settingsHomepage;

  /// No description provided for @settingsAiAgents.
  ///
  /// In en, this message translates to:
  /// **'AI Agents'**
  String get settingsAiAgents;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get settingsContact;

  /// No description provided for @settingsPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get settingsPricing;

  /// No description provided for @settingsDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsDownloads;

  /// No description provided for @settingsSeo.
  ///
  /// In en, this message translates to:
  /// **'SEO'**
  String get settingsSeo;

  /// No description provided for @settingsSmartPrompts.
  ///
  /// In en, this message translates to:
  /// **'Smart Prompts'**
  String get settingsSmartPrompts;

  /// No description provided for @settingsOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get settingsOther;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @adminPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get adminPeople;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminRolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get adminRolesPermissions;

  /// No description provided for @adminTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get adminTeams;

  /// No description provided for @adminContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get adminContent;

  /// No description provided for @adminPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get adminPosts;

  /// No description provided for @adminPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get adminPages;

  /// No description provided for @adminDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get adminDocumentation;

  /// No description provided for @adminCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get adminCategories;

  /// No description provided for @adminCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get adminCommunity;

  /// No description provided for @adminContactNav.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get adminContactNav;

  /// No description provided for @adminIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get adminIssues;

  /// No description provided for @adminMarketplaceNav.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get adminMarketplaceNav;

  /// No description provided for @adminSponsors.
  ///
  /// In en, this message translates to:
  /// **'Sponsors'**
  String get adminSponsors;

  /// No description provided for @adminSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get adminSystem;

  /// No description provided for @adminNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get adminNotifications;

  /// No description provided for @healthSettingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get healthSettingsNotifications;

  /// No description provided for @healthSettingsSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get healthSettingsSleep;

  /// No description provided for @healthSettingsFailedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load health profile'**
  String get healthSettingsFailedToLoadProfile;

  /// No description provided for @healthSettingsWeightCheckin.
  ///
  /// In en, this message translates to:
  /// **'Weight Check-in'**
  String get healthSettingsWeightCheckin;

  /// No description provided for @healthSettingsWeightCheckinSub.
  ///
  /// In en, this message translates to:
  /// **'Daily weight reminder'**
  String get healthSettingsWeightCheckinSub;

  /// No description provided for @healthSettingsAlertTime.
  ///
  /// In en, this message translates to:
  /// **'Alert Time'**
  String get healthSettingsAlertTime;

  /// No description provided for @healthSettingsAlertTimeSub.
  ///
  /// In en, this message translates to:
  /// **'When to remind you'**
  String get healthSettingsAlertTimeSub;

  /// No description provided for @healthSettingsDelayDays.
  ///
  /// In en, this message translates to:
  /// **'Delay Days'**
  String get healthSettingsDelayDays;

  /// No description provided for @healthSettingsDelayDaysSub.
  ///
  /// In en, this message translates to:
  /// **'Days between reminders'**
  String get healthSettingsDelayDaysSub;

  /// No description provided for @healthSettingsDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get healthSettingsDaysUnit;

  /// No description provided for @healthSettingsHygieneReminder.
  ///
  /// In en, this message translates to:
  /// **'Hygiene Reminder'**
  String get healthSettingsHygieneReminder;

  /// No description provided for @healthSettingsHygieneReminderSub.
  ///
  /// In en, this message translates to:
  /// **'Personal hygiene check-in'**
  String get healthSettingsHygieneReminderSub;

  /// No description provided for @healthSettingsPomodoroStartAlert.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Start Alert'**
  String get healthSettingsPomodoroStartAlert;

  /// No description provided for @healthSettingsPomodoroStartAlertSub.
  ///
  /// In en, this message translates to:
  /// **'Heads-up before focus session'**
  String get healthSettingsPomodoroStartAlertSub;

  /// No description provided for @healthSettingsLeadTime.
  ///
  /// In en, this message translates to:
  /// **'Lead Time'**
  String get healthSettingsLeadTime;

  /// No description provided for @healthSettingsLeadTimeStartSub.
  ///
  /// In en, this message translates to:
  /// **'Minutes before session starts'**
  String get healthSettingsLeadTimeStartSub;

  /// No description provided for @healthSettingsMinUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get healthSettingsMinUnit;

  /// No description provided for @healthSettingsPomodoroEndAlert.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro End Alert'**
  String get healthSettingsPomodoroEndAlert;

  /// No description provided for @healthSettingsPomodoroEndAlertSub.
  ///
  /// In en, this message translates to:
  /// **'Heads-up before session ends'**
  String get healthSettingsPomodoroEndAlertSub;

  /// No description provided for @healthSettingsLeadTimeEndSub.
  ///
  /// In en, this message translates to:
  /// **'Minutes before session ends'**
  String get healthSettingsLeadTimeEndSub;

  /// No description provided for @healthSettingsHeartRateHigh.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate High'**
  String get healthSettingsHeartRateHigh;

  /// No description provided for @healthSettingsHeartRateHighSub.
  ///
  /// In en, this message translates to:
  /// **'Upper threshold alert'**
  String get healthSettingsHeartRateHighSub;

  /// No description provided for @healthSettingsBpmUnit.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get healthSettingsBpmUnit;

  /// No description provided for @healthSettingsHeartRateLow.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate Low'**
  String get healthSettingsHeartRateLow;

  /// No description provided for @healthSettingsHeartRateLowSub.
  ///
  /// In en, this message translates to:
  /// **'Lower threshold alert'**
  String get healthSettingsHeartRateLowSub;

  /// No description provided for @healthSettingsMealReminder.
  ///
  /// In en, this message translates to:
  /// **'Meal Reminder'**
  String get healthSettingsMealReminder;

  /// No description provided for @healthSettingsMealReminderSub.
  ///
  /// In en, this message translates to:
  /// **'Remember to log your meals'**
  String get healthSettingsMealReminderSub;

  /// No description provided for @healthSettingsCoffeeTime.
  ///
  /// In en, this message translates to:
  /// **'Coffee Time'**
  String get healthSettingsCoffeeTime;

  /// No description provided for @healthSettingsCoffeeTimeSub.
  ///
  /// In en, this message translates to:
  /// **'Caffeine cutoff alert'**
  String get healthSettingsCoffeeTimeSub;

  /// No description provided for @healthSettingsCutoffTime.
  ///
  /// In en, this message translates to:
  /// **'Cutoff Time'**
  String get healthSettingsCutoffTime;

  /// No description provided for @healthSettingsCutoffTimeSub.
  ///
  /// In en, this message translates to:
  /// **'Last coffee of the day'**
  String get healthSettingsCutoffTimeSub;

  /// No description provided for @healthSettingsHydrationAlert.
  ///
  /// In en, this message translates to:
  /// **'Hydration Alert'**
  String get healthSettingsHydrationAlert;

  /// No description provided for @healthSettingsHydrationAlertSub.
  ///
  /// In en, this message translates to:
  /// **'Periodic water reminders'**
  String get healthSettingsHydrationAlertSub;

  /// No description provided for @healthSettingsAlertGap.
  ///
  /// In en, this message translates to:
  /// **'Alert Gap'**
  String get healthSettingsAlertGap;

  /// No description provided for @healthSettingsAlertGapSub.
  ///
  /// In en, this message translates to:
  /// **'Minutes between reminders'**
  String get healthSettingsAlertGapSub;

  /// No description provided for @healthSettingsMovementAlert.
  ///
  /// In en, this message translates to:
  /// **'Movement Alert'**
  String get healthSettingsMovementAlert;

  /// No description provided for @healthSettingsMovementAlertSub.
  ///
  /// In en, this message translates to:
  /// **'Stand up and stretch'**
  String get healthSettingsMovementAlertSub;

  /// No description provided for @healthSettingsInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get healthSettingsInterval;

  /// No description provided for @healthSettingsIntervalSub.
  ///
  /// In en, this message translates to:
  /// **'Minutes between movement prompts'**
  String get healthSettingsIntervalSub;

  /// No description provided for @healthSettingsGerdWarning.
  ///
  /// In en, this message translates to:
  /// **'GERD Warning'**
  String get healthSettingsGerdWarning;

  /// No description provided for @healthSettingsGerdWarningSub.
  ///
  /// In en, this message translates to:
  /// **'Minutes before shutdown to warn'**
  String get healthSettingsGerdWarningSub;

  /// No description provided for @healthSettingsBedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get healthSettingsBedtime;

  /// No description provided for @healthSettingsBedtimeSub.
  ///
  /// In en, this message translates to:
  /// **'Target sleep time'**
  String get healthSettingsBedtimeSub;

  /// No description provided for @healthSettingsShutdownWindow.
  ///
  /// In en, this message translates to:
  /// **'Shutdown Window'**
  String get healthSettingsShutdownWindow;

  /// No description provided for @healthSettingsShutdownWindowSub.
  ///
  /// In en, this message translates to:
  /// **'Hours before bedtime to start winding down'**
  String get healthSettingsShutdownWindowSub;

  /// No description provided for @healthSettingsHrsUnit.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get healthSettingsHrsUnit;

  /// No description provided for @notifSettingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notifSettingsPushNotifications;

  /// No description provided for @notifSettingsPushNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts on this device'**
  String get notifSettingsPushNotificationsSub;

  /// No description provided for @notifSettingsSyncNotifications.
  ///
  /// In en, this message translates to:
  /// **'Sync notifications'**
  String get notifSettingsSyncNotifications;

  /// No description provided for @notifSettingsSyncNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Alerts when team members update shared entities'**
  String get notifSettingsSyncNotificationsSub;

  /// No description provided for @notifSettingsEmailDigests.
  ///
  /// In en, this message translates to:
  /// **'Email digests'**
  String get notifSettingsEmailDigests;

  /// No description provided for @notifSettingsEmailDigestsSub.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary of activity'**
  String get notifSettingsEmailDigestsSub;

  /// No description provided for @notifSettingsHealthReminders.
  ///
  /// In en, this message translates to:
  /// **'Health reminders'**
  String get notifSettingsHealthReminders;

  /// No description provided for @notifSettingsHealthRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Water, posture and movement prompts'**
  String get notifSettingsHealthRemindersSub;

  /// No description provided for @notifSettingsPomodoroAlerts.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro alerts'**
  String get notifSettingsPomodoroAlerts;

  /// No description provided for @notifSettingsPomodoroAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Session start, break and end sounds'**
  String get notifSettingsPomodoroAlertsSub;

  /// No description provided for @notifSettingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifSettingsNotifications;

  /// No description provided for @notifSettingsAiAgent.
  ///
  /// In en, this message translates to:
  /// **'AI Agent'**
  String get notifSettingsAiAgent;

  /// No description provided for @notifSettingsFailedToLoadPreferences.
  ///
  /// In en, this message translates to:
  /// **'Failed to load preferences'**
  String get notifSettingsFailedToLoadPreferences;

  /// No description provided for @notifSettingsAiPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'AI push notifications'**
  String get notifSettingsAiPushNotifications;

  /// No description provided for @notifSettingsAiPushNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Desktop alerts when agent needs attention'**
  String get notifSettingsAiPushNotificationsSub;

  /// No description provided for @notifSettingsAiVoiceAlerts.
  ///
  /// In en, this message translates to:
  /// **'AI voice alerts'**
  String get notifSettingsAiVoiceAlerts;

  /// No description provided for @notifSettingsAiVoiceAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Speak notifications aloud via TTS'**
  String get notifSettingsAiVoiceAlertsSub;

  /// No description provided for @notifSettingsPushToConnectedApps.
  ///
  /// In en, this message translates to:
  /// **'Push to connected apps'**
  String get notifSettingsPushToConnectedApps;

  /// No description provided for @notifSettingsPushToConnectedAppsSub.
  ///
  /// In en, this message translates to:
  /// **'Send notifications to mobile & web via tunnel'**
  String get notifSettingsPushToConnectedAppsSub;

  /// No description provided for @notifSettingsCouldNotLoadAiSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not load AI settings'**
  String get notifSettingsCouldNotLoadAiSettings;

  /// No description provided for @notifSettingsVoiceAndSchedule.
  ///
  /// In en, this message translates to:
  /// **'Voice & Schedule'**
  String get notifSettingsVoiceAndSchedule;

  /// No description provided for @notifSettingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get notifSettingsVoice;

  /// No description provided for @notifSettingsSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get notifSettingsSystemDefault;

  /// No description provided for @notifSettingsSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get notifSettingsSpeed;

  /// No description provided for @notifSettingsSpeedDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notifSettingsSpeedDefault;

  /// No description provided for @notifSettingsSpeedWpm.
  ///
  /// In en, this message translates to:
  /// **'{speed} wpm'**
  String notifSettingsSpeedWpm(String speed);

  /// No description provided for @notifSettingsQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifSettingsQuietHours;

  /// No description provided for @notifSettingsQuietHoursOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifSettingsQuietHoursOff;

  /// No description provided for @notifSettingsQuietHoursRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String notifSettingsQuietHoursRange(String start, String end);

  /// No description provided for @aboutSettingsAppInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get aboutSettingsAppInfo;

  /// No description provided for @aboutSettingsOrchestra.
  ///
  /// In en, this message translates to:
  /// **'Orchestra'**
  String get aboutSettingsOrchestra;

  /// No description provided for @aboutSettingsAiAgenticFirstIde.
  ///
  /// In en, this message translates to:
  /// **'AI Agentic First IDE'**
  String get aboutSettingsAiAgenticFirstIde;

  /// No description provided for @aboutSettingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutSettingsVersion;

  /// No description provided for @aboutSettingsBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutSettingsBuild;

  /// No description provided for @aboutSettingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get aboutSettingsSupport;

  /// No description provided for @aboutSettingsIssueHistory.
  ///
  /// In en, this message translates to:
  /// **'Issue History'**
  String get aboutSettingsIssueHistory;

  /// No description provided for @aboutSettingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get aboutSettingsLegal;

  /// No description provided for @aboutSettingsOpenSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get aboutSettingsOpenSourceLicenses;

  /// No description provided for @aboutSettingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutSettingsPrivacyPolicy;

  /// No description provided for @aboutSettingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutSettingsTermsOfService;

  /// No description provided for @aboutSettingsNoIssuesReported.
  ///
  /// In en, this message translates to:
  /// **'No issues reported yet.'**
  String get aboutSettingsNoIssuesReported;

  /// No description provided for @aboutSettingsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get aboutSettingsUpToDate;

  /// No description provided for @aboutSettingsCheckingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get aboutSettingsCheckingForUpdates;

  /// No description provided for @aboutSettingsVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'v{version} available'**
  String aboutSettingsVersionAvailable(String version);

  /// No description provided for @aboutSettingsDownloadingVersion.
  ///
  /// In en, this message translates to:
  /// **'Downloading v{version}...'**
  String aboutSettingsDownloadingVersion(String version);

  /// No description provided for @aboutSettingsReadyToInstall.
  ///
  /// In en, this message translates to:
  /// **'v{version} ready — restart to apply'**
  String aboutSettingsReadyToInstall(String version);

  /// No description provided for @aboutSettingsUpdateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get aboutSettingsUpdateCheckFailed;

  /// No description provided for @appearanceSettingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get appearanceSettingsEnglish;

  /// No description provided for @appearanceSettingsArabicRtl.
  ///
  /// In en, this message translates to:
  /// **'Arabic (RTL)'**
  String get appearanceSettingsArabicRtl;

  /// Default username fallback on summary screen
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get summaryUser;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'Welcome to Orchestra'**
  String get onboardingWelcomeTitle;

  /// Onboarding page 1 subtitle
  ///
  /// In en, this message translates to:
  /// **'Your intelligent workspace for managing projects, agents, and\nworkflows — all in one place.'**
  String get onboardingWelcomeSubtitle;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'Powerful Features'**
  String get onboardingFeaturesTitle;

  /// Onboarding page 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Create features, track progress through gated phases, and let\nAI agents handle the heavy lifting.'**
  String get onboardingFeaturesSubtitle;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'Stay Healthy'**
  String get onboardingHealthTitle;

  /// Onboarding page 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Orchestra monitors your focus sessions and reminds you to\ntake breaks, hydrate, and move.'**
  String get onboardingHealthSubtitle;

  /// Onboarding page 4 title
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStartedTitle;

  /// Onboarding page 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to begin. Your data stays\nsecure and synced across all your devices.'**
  String get onboardingGetStartedSubtitle;

  /// Skip button on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Accessibility label for skip onboarding button
  ///
  /// In en, this message translates to:
  /// **'Skip onboarding'**
  String get onboardingSkipAccessibility;

  /// Accessibility label for back button on onboarding
  ///
  /// In en, this message translates to:
  /// **'Go to previous page'**
  String get onboardingPreviousPageAccessibility;

  /// Accessibility label for next button on onboarding
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get onboardingNextPageAccessibility;

  /// Accessibility label for get started button on onboarding
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStartedAccessibility;

  /// Accessibility label for page indicator dots
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageIndicator(int current, int total);

  /// Empty state when terminal search yields no results
  ///
  /// In en, this message translates to:
  /// **'No matching sessions'**
  String get terminalNoMatchingSessions;

  /// Terminal session type label for local shell
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get terminalTypeLocal;

  /// Terminal session type label for SSH
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get terminalTypeSsh;

  /// Terminal session type label for Claude AI
  ///
  /// In en, this message translates to:
  /// **'Claude'**
  String get terminalTypeClaude;

  /// Terminal session type label for remote connection
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get terminalTypeRemote;

  /// Empty state subtitle on terminal screen
  ///
  /// In en, this message translates to:
  /// **'Create a session to get started'**
  String get terminalCreateToStart;

  /// Snackbar message when no remote machines are available
  ///
  /// In en, this message translates to:
  /// **'No machines online. Start Orchestra on your desktop.'**
  String get terminalNoMachinesOnline;

  /// Snackbar message when remote terminal connection fails
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String terminalConnectionFailed(String error);

  /// Title for local terminal option in create sheet
  ///
  /// In en, this message translates to:
  /// **'Local Terminal'**
  String get terminalLocalTitle;

  /// Subtitle for local terminal option in create sheet
  ///
  /// In en, this message translates to:
  /// **'Shell on this machine'**
  String get terminalLocalSubtitle;

  /// Subtitle for SSH option in create sheet
  ///
  /// In en, this message translates to:
  /// **'Connect to a remote host'**
  String get terminalSshSubtitle;

  /// Title for Claude Code option in create sheet
  ///
  /// In en, this message translates to:
  /// **'Claude Code'**
  String get terminalClaudeTitle;

  /// Subtitle for Claude Code option in create sheet
  ///
  /// In en, this message translates to:
  /// **'AI coding assistant'**
  String get terminalClaudeSubtitle;

  /// Title for remote terminal option in create sheet
  ///
  /// In en, this message translates to:
  /// **'Remote Terminal'**
  String get terminalRemoteTitle;

  /// Subtitle for remote terminal option in create sheet
  ///
  /// In en, this message translates to:
  /// **'Auto-detect: local WiFi or cloud tunnel'**
  String get terminalRemoteSubtitle;

  /// No description provided for @syncConflictLocalVersion.
  ///
  /// In en, this message translates to:
  /// **'Local v{version}'**
  String syncConflictLocalVersion(int version);

  /// No description provided for @syncConflictRemoteVersion.
  ///
  /// In en, this message translates to:
  /// **'Remote v{version}'**
  String syncConflictRemoteVersion(int version);

  /// No description provided for @syncConflictEmpty.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get syncConflictEmpty;

  /// No description provided for @syncConflictText.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get syncConflictText;

  /// No description provided for @updateBannerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Orchestra v{version} is available'**
  String updateBannerAvailable(String version);

  /// No description provided for @updateBannerDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading v{version}...'**
  String updateBannerDownloading(String version);

  /// No description provided for @updateBannerReady.
  ///
  /// In en, this message translates to:
  /// **'v{version} downloaded — restart to apply'**
  String updateBannerReady(String version);

  /// No description provided for @updateBannerRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get updateBannerRestart;

  /// No description provided for @updateBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get updateBannerDismiss;

  /// No description provided for @iconPickerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Icon picker'**
  String get iconPickerSemantics;

  /// No description provided for @iconPickerOptionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Icon option'**
  String get iconPickerOptionSemantics;

  /// No description provided for @colorPickerSemantics.
  ///
  /// In en, this message translates to:
  /// **'Colour picker'**
  String get colorPickerSemantics;

  /// No description provided for @colorPickerSwatchSemantics.
  ///
  /// In en, this message translates to:
  /// **'Colour swatch'**
  String get colorPickerSwatchSemantics;

  /// No description provided for @terminalSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terminal session'**
  String get terminalSessionSubtitle;

  /// No description provided for @markAllNotificationsReadSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mark all notifications as read'**
  String get markAllNotificationsReadSemantics;

  /// No description provided for @notificationRead.
  ///
  /// In en, this message translates to:
  /// **'read'**
  String get notificationRead;

  /// No description provided for @notificationUnread.
  ///
  /// In en, this message translates to:
  /// **'unread'**
  String get notificationUnread;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityNoActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get activityNoActivityYet;

  /// No description provided for @activityMcpToolCalls.
  ///
  /// In en, this message translates to:
  /// **'MCP tool calls will appear here'**
  String get activityMcpToolCalls;

  /// No description provided for @activityActionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} actions'**
  String activityActionsCount(int count);

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityFilterAll;

  /// No description provided for @activityJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get activityJustNow;

  /// No description provided for @activityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String activityMinutesAgo(int minutes);

  /// No description provided for @activityHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String activityHoursAgo(int hours);

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddressHint;

  /// No description provided for @noTeamSelected.
  ///
  /// In en, this message translates to:
  /// **'No team selected'**
  String get noTeamSelected;

  /// No description provided for @createOrJoinTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Create or join a team to manage settings here.'**
  String get createOrJoinTeamHint;

  /// No description provided for @membersSection.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersSection;

  /// No description provided for @dangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZoneTitle;

  /// No description provided for @deleteTeamPermanentlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this team and all its data'**
  String get deleteTeamPermanentlyDesc;

  /// No description provided for @removeThisWillRemoveFromTeam.
  ///
  /// In en, this message translates to:
  /// **'This will remove them from the team.'**
  String get removeThisWillRemoveFromTeam;

  /// No description provided for @deleteTeamAllDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the team and all its data. This action cannot be undone.'**
  String get deleteTeamAllDataWarning;

  /// No description provided for @orchestraLogoSemantics.
  ///
  /// In en, this message translates to:
  /// **'Orchestra logo'**
  String get orchestraLogoSemantics;

  /// No description provided for @newSessionTooltip.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get newSessionTooltip;

  /// No description provided for @newSessionTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get newSessionTerminal;

  /// No description provided for @newSessionSsh.
  ///
  /// In en, this message translates to:
  /// **'SSH'**
  String get newSessionSsh;

  /// No description provided for @newSessionClaude.
  ///
  /// In en, this message translates to:
  /// **'Claude'**
  String get newSessionClaude;

  /// No description provided for @editorDescribeWhatYouWant.
  ///
  /// In en, this message translates to:
  /// **'Describe what you want'**
  String get editorDescribeWhatYouWant;

  /// No description provided for @entityPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get entityPlan;

  /// No description provided for @entityRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get entityRequest;

  /// No description provided for @goBackSemantics.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBackSemantics;

  /// No description provided for @featureDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get featureDetailsTitle;

  /// No description provided for @featureAssigneeLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get featureAssigneeLabel;

  /// No description provided for @featureEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get featureEstimateLabel;

  /// No description provided for @featureProjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get featureProjectLabel;

  /// No description provided for @featureLabelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get featureLabelsLabel;

  /// No description provided for @featureUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get featureUnassigned;

  /// No description provided for @failedToLoadFeature.
  ///
  /// In en, this message translates to:
  /// **'Failed to load feature'**
  String get failedToLoadFeature;

  /// No description provided for @featureNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get featureNoDescription;

  /// No description provided for @managedByOrchestra.
  ///
  /// In en, this message translates to:
  /// **'Managed by Orchestra MCP'**
  String get managedByOrchestra;

  /// Dashboard page title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// Dashboard stat card label for active projects
  ///
  /// In en, this message translates to:
  /// **'Active Projects'**
  String get dashboardActiveProjects;

  /// Dashboard stat card label for in-progress features
  ///
  /// In en, this message translates to:
  /// **'In-Progress Features'**
  String get dashboardInProgressFeatures;

  /// Dashboard stat card label for open bugs
  ///
  /// In en, this message translates to:
  /// **'Open Bugs'**
  String get dashboardOpenBugs;

  /// Dashboard stat card label for items in review
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get dashboardInReview;

  /// Dashboard section header for recent activity
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get dashboardRecentActivity;

  /// Placeholder activity: feature completed
  ///
  /// In en, this message translates to:
  /// **'FEAT-WVS completed'**
  String get dashboardFeatCompleted;

  /// Placeholder activity subtitle: feature completed
  ///
  /// In en, this message translates to:
  /// **'AI insight engine — 2 min ago'**
  String get dashboardFeatCompletedSub;

  /// Placeholder activity: feature advanced
  ///
  /// In en, this message translates to:
  /// **'FEAT-BHF advanced to in-review'**
  String get dashboardFeatAdvanced;

  /// Placeholder activity subtitle: feature advanced
  ///
  /// In en, this message translates to:
  /// **'Nutrition manager — 15 min ago'**
  String get dashboardFeatAdvancedSub;

  /// Placeholder activity: bug reported
  ///
  /// In en, this message translates to:
  /// **'Bug reported on FEAT-UJV'**
  String get dashboardBugReported;

  /// Placeholder activity subtitle: bug reported
  ///
  /// In en, this message translates to:
  /// **'Web auth storage — 1 h ago'**
  String get dashboardBugReportedSub;

  /// Placeholder activity: new session
  ///
  /// In en, this message translates to:
  /// **'New session started'**
  String get dashboardNewSession;

  /// Placeholder activity subtitle: new session
  ///
  /// In en, this message translates to:
  /// **'claude-sonnet-4-6 — 2 h ago'**
  String get dashboardNewSessionSub;

  /// Placeholder activity: hydration goal
  ///
  /// In en, this message translates to:
  /// **'Hydration goal reached'**
  String get dashboardHydrationGoal;

  /// Placeholder activity subtitle: hydration goal
  ///
  /// In en, this message translates to:
  /// **'2500 ml — 3 h ago'**
  String get dashboardHydrationGoalSub;

  /// Password hint for minimum character count
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get userDetailMinCharacters;

  /// Empty state label when user has no projects
  ///
  /// In en, this message translates to:
  /// **'No Projects'**
  String get userDetailNoProjects;

  /// Empty state description when user has no projects
  ///
  /// In en, this message translates to:
  /// **'This user has no projects yet'**
  String get userDetailNoProjectsDesc;

  /// Empty state label when user has no notes
  ///
  /// In en, this message translates to:
  /// **'No Notes'**
  String get userDetailNoNotes;

  /// Empty state description when user has no notes
  ///
  /// In en, this message translates to:
  /// **'This user has no notes yet'**
  String get userDetailNoNotesDesc;

  /// Empty state label when user has no chats
  ///
  /// In en, this message translates to:
  /// **'No Chats'**
  String get userDetailNoChats;

  /// Empty state description when user has no chats
  ///
  /// In en, this message translates to:
  /// **'This user has no chat sessions yet'**
  String get userDetailNoChatsDesc;

  /// Empty state label when user has no teams
  ///
  /// In en, this message translates to:
  /// **'No Teams'**
  String get userDetailNoTeams;

  /// Empty state description when user has no teams
  ///
  /// In en, this message translates to:
  /// **'This user is not a member of any team'**
  String get userDetailNoTeamsDesc;

  /// Empty state label when user has no issues
  ///
  /// In en, this message translates to:
  /// **'No Issues'**
  String get userDetailNoIssues;

  /// Empty state description when user has no issues
  ///
  /// In en, this message translates to:
  /// **'This user has no reported issues'**
  String get userDetailNoIssuesDesc;

  /// Badge label for team-scoped workflows
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get workflowTeamBadge;

  /// Snackbar message when installing a workflow
  ///
  /// In en, this message translates to:
  /// **'Installing \"{name}\"...'**
  String workflowInstalling(String name);

  /// Workflow author attribution
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String workflowByAuthor(String author);

  /// Rating display with count
  ///
  /// In en, this message translates to:
  /// **'{rating} ({count} ratings)'**
  String workflowRatingsCount(String rating, int count);

  /// Download count display
  ///
  /// In en, this message translates to:
  /// **'{count} downloads'**
  String workflowDownloadsCount(int count);

  /// Workflow content type: skills
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get workflowSkills;

  /// Workflow content type: agents
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get workflowAgents;

  /// Workflow content type: hooks
  ///
  /// In en, this message translates to:
  /// **'Hooks'**
  String get workflowHooks;

  /// Table column header for ID
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get columnId;

  /// Table column header for title
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get columnTitle;

  /// Table column header for project
  ///
  /// In en, this message translates to:
  /// **'PROJECT'**
  String get columnProject;

  /// Table column header for status
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get columnStatus;

  /// Table column header for priority
  ///
  /// In en, this message translates to:
  /// **'PRIORITY'**
  String get columnPriority;

  /// Table column header for kind
  ///
  /// In en, this message translates to:
  /// **'KIND'**
  String get columnKind;

  /// Smart action bar label: summarize
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get smartActionSummarize;

  /// Smart action bar label: explain
  ///
  /// In en, this message translates to:
  /// **'Explain'**
  String get smartActionExplain;

  /// Smart action bar label: fix
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get smartActionFix;

  /// Smart action bar label: translate
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get smartActionTranslate;

  /// Smart action bar label: custom
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get smartActionCustom;

  /// Activity feed page title
  ///
  /// In en, this message translates to:
  /// **'Activity Feed'**
  String get activityFeedTitle;

  /// Count of activities displayed
  ///
  /// In en, this message translates to:
  /// **'{count} activities'**
  String activityCount(int count);

  /// Count of new unread activities
  ///
  /// In en, this message translates to:
  /// **'{count} new activities'**
  String activityNewCount(int count);

  /// Filter chip to show all activity types
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get activityAllTypes;

  /// Filter chip to show all team members
  ///
  /// In en, this message translates to:
  /// **'All Members'**
  String get activityAllMembers;

  /// Empty state when no activities match filters
  ///
  /// In en, this message translates to:
  /// **'No activities match your filters'**
  String get activityNoMatchingFilters;

  /// Time group header: today's activities
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get activityGroupToday;

  /// Time group header: yesterday's activities
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get activityGroupYesterday;

  /// Time group header: older activities
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get activityGroupEarlier;

  /// Badge shown when real-time WebSocket is connected
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get activityLiveIndicator;

  /// Label shown after copying text to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Button to dismiss/close a panel or notification
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Button to discard generated content
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Button to accept/use AI-generated content
  ///
  /// In en, this message translates to:
  /// **'Use Result'**
  String get useResult;

  /// Subtitle in the universal create dialog type-picker
  ///
  /// In en, this message translates to:
  /// **'What would you like to create?'**
  String get whatToCreate;

  /// Status label when AI result is streaming in
  ///
  /// In en, this message translates to:
  /// **'Streaming...'**
  String get resultStreaming;

  /// Status label when AI result is complete
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get resultComplete;

  /// Status label when AI result encountered an error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get resultError;

  /// Status label while waiting for AI result to begin
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get resultProcessing;

  /// Notification title when a feature is marked done
  ///
  /// In en, this message translates to:
  /// **'Feature Complete'**
  String get notifFeatureComplete;

  /// Notification title when a feature status changes
  ///
  /// In en, this message translates to:
  /// **'Feature Updated'**
  String get notifFeatureUpdated;

  /// Notification title when a smart action finishes
  ///
  /// In en, this message translates to:
  /// **'Smart Action Complete'**
  String get notifSmartActionComplete;

  /// Notification title when an AI note is generated
  ///
  /// In en, this message translates to:
  /// **'Note Generated'**
  String get notifNoteGenerated;

  /// Notification body when an AI note is ready
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is ready for review'**
  String notifNoteReady(String title);

  /// Notification title when sync finishes
  ///
  /// In en, this message translates to:
  /// **'Sync Complete'**
  String get notifSyncComplete;

  /// Notification body showing how many items synced
  ///
  /// In en, this message translates to:
  /// **'{count} items synced'**
  String notifSyncItemsSynced(int count);

  /// Notification title when an agent session completes
  ///
  /// In en, this message translates to:
  /// **'Agent Finished'**
  String get notifAgentFinished;

  /// Default notification body for agent completion
  ///
  /// In en, this message translates to:
  /// **'An agent session completed'**
  String get notifAgentSessionCompleted;

  /// Notification title when a synced entity is deleted
  ///
  /// In en, this message translates to:
  /// **'{entityType} Deleted'**
  String notifEntityDeleted(String entityType);

  /// Notification body when a synced entity is deleted
  ///
  /// In en, this message translates to:
  /// **'{entityType} {entityId} was removed'**
  String notifEntityDeletedBody(String entityType, String entityId);

  /// Description for summarize smart action
  ///
  /// In en, this message translates to:
  /// **'Create a concise summary'**
  String get smartActionSummarizeDesc;

  /// Description for explain smart action
  ///
  /// In en, this message translates to:
  /// **'Explain in simple terms'**
  String get smartActionExplainDesc;

  /// Description for fix smart action
  ///
  /// In en, this message translates to:
  /// **'Fix errors and issues'**
  String get smartActionFixDesc;

  /// Description for translate smart action
  ///
  /// In en, this message translates to:
  /// **'Translate to another language'**
  String get smartActionTranslateDesc;

  /// Label for custom prompt smart action
  ///
  /// In en, this message translates to:
  /// **'Custom prompt'**
  String get smartActionCustomPrompt;

  /// Description for custom prompt smart action
  ///
  /// In en, this message translates to:
  /// **'Write your own instruction'**
  String get smartActionCustomPromptDesc;

  /// Default label for a terminal session
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminalLabelDefault;

  /// Label for Claude Code terminal sessions
  ///
  /// In en, this message translates to:
  /// **'Claude Code'**
  String get terminalClaudeCode;

  /// Label for remote terminal sessions
  ///
  /// In en, this message translates to:
  /// **'Remote Terminal'**
  String get terminalRemoteLabel;

  /// Error message when trying to open local terminal on non-desktop
  ///
  /// In en, this message translates to:
  /// **'Local terminal is only available on desktop'**
  String get terminalDesktopOnly;

  /// Error message when trying to open Claude terminal on non-desktop
  ///
  /// In en, this message translates to:
  /// **'Claude Code terminal is only available on desktop'**
  String get terminalClaudeDesktopOnly;

  /// Snackbar action to view delegation details
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get delegationSnackbarView;

  /// Notification title for delegation requests
  ///
  /// In en, this message translates to:
  /// **'Delegation Request'**
  String get agentNotifDelegationRequest;

  /// Notification title for permission requests
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get agentNotifPermissionRequired;

  /// Notification title for review requests
  ///
  /// In en, this message translates to:
  /// **'Review Requested'**
  String get agentNotifReviewRequested;

  /// Default notification title when agent needs attention
  ///
  /// In en, this message translates to:
  /// **'Agent Attention Needed'**
  String get agentNotifAttentionNeeded;

  /// Notification body when agent needs attention
  ///
  /// In en, this message translates to:
  /// **'Agent needs your attention — {entityType}'**
  String agentNotifNeedsAttention(String entityType);

  /// Notification title when an agent is spawned
  ///
  /// In en, this message translates to:
  /// **'Agent Spawned'**
  String get agentNotifSpawned;

  /// Notification body when an agent is spawned
  ///
  /// In en, this message translates to:
  /// **'A {agentType} agent started working'**
  String agentNotifSpawnedBody(String agentType);

  /// Hydration reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Time to hydrate'**
  String get healthNotifHydrationTitle;

  /// Hydration reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Drink a glass of water to stay on track.'**
  String get healthNotifHydrationBody;

  /// Pomodoro short break notification title
  ///
  /// In en, this message translates to:
  /// **'Short break time'**
  String get healthNotifShortBreak;

  /// Pomodoro long break notification title
  ///
  /// In en, this message translates to:
  /// **'Long break time'**
  String get healthNotifLongBreak;

  /// Pomodoro break notification body
  ///
  /// In en, this message translates to:
  /// **'Stand up, stretch, and rest your eyes.'**
  String get healthNotifPomodoroBody;

  /// Pomodoro work start notification title
  ///
  /// In en, this message translates to:
  /// **'Break is over'**
  String get healthNotifBreakOver;

  /// Pomodoro work start notification body
  ///
  /// In en, this message translates to:
  /// **'Time to focus! Start your next pomodoro.'**
  String get healthNotifBreakOverBody;

  /// Shutdown lead reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Shutdown approaching'**
  String get healthNotifShutdownApproaching;

  /// Shutdown lead reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Your shutdown routine starts in {minutes} minutes.'**
  String healthNotifShutdownApproachingBody(int minutes);

  /// Shutdown main reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Time to shut down'**
  String get healthNotifShutdownNow;

  /// Shutdown main reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Begin your evening wind-down routine now.'**
  String get healthNotifShutdownNowBody;

  /// Weight check-in reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Weight check-in'**
  String get healthNotifWeightTitle;

  /// Weight check-in reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Step on the scale and log your weight.'**
  String get healthNotifWeightBody;

  /// Meal logging reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Log your meal'**
  String get healthNotifMealTitle;

  /// Meal logging reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Record what you ate to keep your nutrition on track.'**
  String get healthNotifMealBody;

  /// Coffee cutoff alert notification title
  ///
  /// In en, this message translates to:
  /// **'Coffee cutoff'**
  String get healthNotifCoffeeTitle;

  /// Coffee cutoff alert notification body
  ///
  /// In en, this message translates to:
  /// **'No more caffeine after this point for better sleep.'**
  String get healthNotifCoffeeBody;

  /// Movement reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Time to move'**
  String get healthNotifMovementTitle;

  /// Movement reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Stand up, stretch, and take a short walk.'**
  String get healthNotifMovementBody;

  /// High heart rate alert notification title
  ///
  /// In en, this message translates to:
  /// **'High heart rate detected'**
  String get healthNotifHeartHigh;

  /// Low heart rate alert notification title
  ///
  /// In en, this message translates to:
  /// **'Low heart rate detected'**
  String get healthNotifHeartLow;

  /// Heart rate alert notification body
  ///
  /// In en, this message translates to:
  /// **'Your heart rate is {bpm} bpm. Consider resting and monitoring.'**
  String healthNotifHeartBody(int bpm);

  /// Hygiene reminder notification title
  ///
  /// In en, this message translates to:
  /// **'Hygiene check-in'**
  String get healthNotifHygieneTitle;

  /// Hygiene reminder notification body
  ///
  /// In en, this message translates to:
  /// **'Time for your personal hygiene routine.'**
  String get healthNotifHygieneBody;

  /// GERD warning notification title
  ///
  /// In en, this message translates to:
  /// **'GERD warning'**
  String get healthNotifGerdTitle;

  /// GERD warning notification body
  ///
  /// In en, this message translates to:
  /// **'Stop eating now to avoid reflux before bed.'**
  String get healthNotifGerdBody;

  /// Minimum heart rate display
  ///
  /// In en, this message translates to:
  /// **'Min: {value}'**
  String vitalsMin(int value);

  /// Maximum heart rate display
  ///
  /// In en, this message translates to:
  /// **'Max: {value}'**
  String vitalsMax(int value);

  /// Hint for metabolic age target
  ///
  /// In en, this message translates to:
  /// **'target < 35'**
  String get vitalsMetabolicTarget;

  /// Notification settings section title for AI agent
  ///
  /// In en, this message translates to:
  /// **'AI Agent'**
  String get notifSectionAiAgent;

  /// Toggle label for AI push notifications
  ///
  /// In en, this message translates to:
  /// **'AI push notifications'**
  String get notifAiPush;

  /// Subtitle for AI push notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Desktop alerts when agent needs attention'**
  String get notifAiPushSubtitle;

  /// Toggle label for AI voice alerts
  ///
  /// In en, this message translates to:
  /// **'AI voice alerts'**
  String get notifAiVoice;

  /// Subtitle for AI voice alerts toggle
  ///
  /// In en, this message translates to:
  /// **'Speak notifications aloud via TTS'**
  String get notifAiVoiceSubtitle;

  /// Toggle label for pushing to connected apps
  ///
  /// In en, this message translates to:
  /// **'Push to connected apps'**
  String get notifPushConnected;

  /// Subtitle for push to connected apps toggle
  ///
  /// In en, this message translates to:
  /// **'Send notifications to mobile & web via tunnel'**
  String get notifPushConnectedSubtitle;

  /// Notification settings section title for voice & schedule
  ///
  /// In en, this message translates to:
  /// **'Voice & Schedule'**
  String get notifSectionVoiceSchedule;

  /// Voice configuration row label
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get notifVoiceLabel;

  /// Fallback value when no custom voice is set
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get notifSystemDefault;

  /// Voice speed configuration row label
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get notifSpeedLabel;

  /// Default value display for voice settings
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get notifDefaultLabel;

  /// Voice speed in words per minute
  ///
  /// In en, this message translates to:
  /// **'{speed} wpm'**
  String notifSpeedWpm(String speed);

  /// Voice volume configuration row label
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get notifVolumeLabel;

  /// Quiet hours configuration row label
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifQuietHours;

  /// Quiet hours disabled display
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifQuietOff;

  /// Quiet hours time range display
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String notifQuietRange(String start, String end);

  /// Dialog title for editing voice name
  ///
  /// In en, this message translates to:
  /// **'Voice Name'**
  String get notifVoiceName;

  /// Hint text for voice name input
  ///
  /// In en, this message translates to:
  /// **'e.g. Samantha'**
  String get notifVoiceNameHint;

  /// Dialog title for editing voice speed
  ///
  /// In en, this message translates to:
  /// **'Speed (words/min)'**
  String get notifSpeedWpmLabel;

  /// Hint text for speed input
  ///
  /// In en, this message translates to:
  /// **'e.g. 180'**
  String get notifSpeedHint;

  /// Dialog title for editing volume
  ///
  /// In en, this message translates to:
  /// **'Volume (0.0-1.0)'**
  String get notifVolumeRange;

  /// Hint text for volume input
  ///
  /// In en, this message translates to:
  /// **'e.g. 0.8'**
  String get notifVolumeHint;

  /// Dialog title for editing quiet hours
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get notifQuietHoursTitle;

  /// Label for quiet hours start time
  ///
  /// In en, this message translates to:
  /// **'Start (HH:MM)'**
  String get notifQuietStart;

  /// Hint for quiet hours start time
  ///
  /// In en, this message translates to:
  /// **'22:00'**
  String get notifQuietStartHint;

  /// Label for quiet hours end time
  ///
  /// In en, this message translates to:
  /// **'End (HH:MM)'**
  String get notifQuietEnd;

  /// Hint for quiet hours end time
  ///
  /// In en, this message translates to:
  /// **'08:00'**
  String get notifQuietEndHint;

  /// Button to turn off quiet hours
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get notifTurnOff;

  /// Error message when saving notification settings fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String notifFailedToSave(String error);

  /// Error message when loading notification settings fails
  ///
  /// In en, this message translates to:
  /// **'Could not load settings'**
  String get notifCouldNotLoad;

  /// Category filter chip: all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// Category filter chip: web
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get categoryWeb;

  /// Category filter chip: mobile
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get categoryMobile;

  /// Category filter chip: backend
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get categoryBackend;

  /// Category filter chip: systems
  ///
  /// In en, this message translates to:
  /// **'Systems'**
  String get categorySystems;

  /// Category filter chip: devops
  ///
  /// In en, this message translates to:
  /// **'DevOps'**
  String get categoryDevOps;

  /// Category filter chip: data
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get categoryData;

  /// Category filter chip: management
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get categoryManagement;

  /// Semantics label for the three-dot context menu button
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptionsSemantics;

  /// Placeholder text in the desktop shell search bar
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchDotDotDot;

  /// Title when creating a new entity
  ///
  /// In en, this message translates to:
  /// **'New {entity}'**
  String newEntityTitle(String entity);

  /// Title when editing an existing entity
  ///
  /// In en, this message translates to:
  /// **'Edit {entity}'**
  String editEntityTitle(String entity);

  /// Hint text for agent body editor
  ///
  /// In en, this message translates to:
  /// **'System prompt (Markdown)...'**
  String get systemPromptHint;

  /// Hint text for doc body editor
  ///
  /// In en, this message translates to:
  /// **'Document content (Markdown)...'**
  String get docContentHint;

  /// Hint text for generic entity body editor
  ///
  /// In en, this message translates to:
  /// **'Description (Markdown)...'**
  String get descriptionMarkdownHint;

  /// Hint text for the smart action prompt input
  ///
  /// In en, this message translates to:
  /// **'Describe what you want...'**
  String get describeWhatYouWant;

  /// Validation message when a required field is empty
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldIsRequired(String field);

  /// Hint text for dropdown field selection
  ///
  /// In en, this message translates to:
  /// **'Select {field}'**
  String selectFieldHint(String field);

  /// Sidebar header in project manager screen
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get pmProjects;

  /// Feature completion count in project manager
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} features complete'**
  String pmFeaturesComplete(int done, int total);

  /// Empty state text in kanban column
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get pmNoItems;

  /// Number of features assigned to a team member
  ///
  /// In en, this message translates to:
  /// **'{count} assigned'**
  String pmNAssigned(int count);

  /// Number of features completed by a team member
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String pmNCompleted(int count);

  /// Reports section header
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get pmReports;

  /// Burn-down chart title
  ///
  /// In en, this message translates to:
  /// **'Burn-down Chart'**
  String get pmBurndownChart;

  /// Completion donut chart title
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get pmCompletion;

  /// Velocity metrics card title
  ///
  /// In en, this message translates to:
  /// **'Velocity Metrics'**
  String get pmVelocityMetrics;

  /// Velocity metric: features done
  ///
  /// In en, this message translates to:
  /// **'Features Done'**
  String get pmFeaturesDone;

  /// Velocity metric: in progress
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get pmInProgress;

  /// Velocity metric: blocked or in review
  ///
  /// In en, this message translates to:
  /// **'Blocked / Review'**
  String get pmBlockedReview;

  /// Velocity metric: average cycle time
  ///
  /// In en, this message translates to:
  /// **'Avg. Cycle Time'**
  String get pmAvgCycleTime;

  /// Velocity metric: throughput over 7 days
  ///
  /// In en, this message translates to:
  /// **'Throughput (7d)'**
  String get pmThroughput7d;

  /// Number of features for throughput metric
  ///
  /// In en, this message translates to:
  /// **'{count} features'**
  String pmNFeatures(int count);

  /// Number of days for cycle time metric
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String pmDays(String count);

  /// Kanban column label: todo
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get kanbanTodo;

  /// Kanban column label: in progress
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get kanbanInProgress;

  /// Kanban column label: in testing
  ///
  /// In en, this message translates to:
  /// **'In Testing'**
  String get kanbanInTesting;

  /// Kanban column label: in review
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get kanbanInReview;

  /// Kanban column label: done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get kanbanDone;

  /// Tab label: Board
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get tabBoard;

  /// Tab label: Timeline
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get tabTimeline;

  /// Tab label: Team
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get tabTeam;

  /// Tab label: Reports
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get tabReports;

  /// Metadata label: assignee
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get featureDetailAssignee;

  /// Metadata label: estimate
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get featureDetailEstimate;

  /// Metadata label: project
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get featureDetailProject;

  /// Metadata section header: labels
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get featureDetailLabels;

  /// Default text when no assignee is set
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get featureDetailUnassigned;

  /// No description provided for @settingsTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get settingsTeam;

  /// No description provided for @claudeSettingsDefaultModel.
  ///
  /// In en, this message translates to:
  /// **'Default model'**
  String get claudeSettingsDefaultModel;

  /// No description provided for @claudeSettingsLimits.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get claudeSettingsLimits;

  /// No description provided for @claudeSettingsToolPermissions.
  ///
  /// In en, this message translates to:
  /// **'Tool Permissions'**
  String get claudeSettingsToolPermissions;

  /// No description provided for @agentInstructionsNewSection.
  ///
  /// In en, this message translates to:
  /// **'New Section'**
  String get agentInstructionsNewSection;

  /// No description provided for @agentInstructionsContent.
  ///
  /// In en, this message translates to:
  /// **'Content (markdown)'**
  String get agentInstructionsContent;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// Section header for public profile settings
  ///
  /// In en, this message translates to:
  /// **'PUBLIC PROFILE'**
  String get publicProfileSection;

  /// Handle / username field label
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get handle;

  /// Handle field placeholder hint
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get handleHint;

  /// Toggle label for public profile visibility
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfileToggle;

  /// Subtitle for public profile toggle
  ///
  /// In en, this message translates to:
  /// **'Allow anyone to view your profile'**
  String get publicProfileSubtitle;

  /// Toggle label for showing comments on profile
  ///
  /// In en, this message translates to:
  /// **'Show Comments'**
  String get showComments;

  /// Subtitle for show comments toggle
  ///
  /// In en, this message translates to:
  /// **'Allow comments on your profile posts'**
  String get showCommentsSubtitle;

  /// Placeholder text for empty cover image area
  ///
  /// In en, this message translates to:
  /// **'Add Cover Image'**
  String get addCoverImage;

  /// Snackbar message after cover image is updated
  ///
  /// In en, this message translates to:
  /// **'Cover updated'**
  String get coverUpdated;

  /// Snackbar error message when cover upload fails
  ///
  /// In en, this message translates to:
  /// **'Failed to upload cover'**
  String get failedToUploadCover;

  /// Section header for social links
  ///
  /// In en, this message translates to:
  /// **'SOCIAL LINKS'**
  String get socialLinksSection;

  /// Button label to add a new social link
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @coverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get coverImage;

  /// No description provided for @coverImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload a cover image for your public profile'**
  String get coverImageDesc;

  /// No description provided for @uploadCover.
  ///
  /// In en, this message translates to:
  /// **'Upload Cover'**
  String get uploadCover;

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfile;

  /// No description provided for @enablePublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Enable Public Profile'**
  String get enablePublicProfile;

  /// No description provided for @enablePublicProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow others to view your profile and activity'**
  String get enablePublicProfileDesc;

  /// No description provided for @showCommentsOnProfile.
  ///
  /// In en, this message translates to:
  /// **'Show Comments'**
  String get showCommentsOnProfile;

  /// No description provided for @showCommentsOnProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Display comments on your public profile page'**
  String get showCommentsOnProfileDesc;

  /// No description provided for @socialLinks.
  ///
  /// In en, this message translates to:
  /// **'Social Links'**
  String get socialLinks;

  /// No description provided for @socialLinksDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your social profiles so others can find you'**
  String get socialLinksDesc;

  /// Section header for AI agent notification settings
  ///
  /// In en, this message translates to:
  /// **'AI Agent'**
  String get aiAgentSection;

  /// Error message when notification settings fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load settings'**
  String get couldNotLoadSettings;

  /// Section header for voice and schedule notification settings
  ///
  /// In en, this message translates to:
  /// **'Voice & Schedule'**
  String get voiceAndSchedule;

  /// Toggle label for AI push notifications
  ///
  /// In en, this message translates to:
  /// **'AI push notifications'**
  String get aiPushNotifications;

  /// Subtitle for AI push notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Desktop alerts when agent needs attention'**
  String get aiPushNotificationsSubtitle;

  /// Toggle label for AI voice alerts
  ///
  /// In en, this message translates to:
  /// **'AI voice alerts'**
  String get aiVoiceAlerts;

  /// Subtitle for AI voice alerts toggle
  ///
  /// In en, this message translates to:
  /// **'Speak notifications aloud via TTS'**
  String get aiVoiceAlertsSubtitle;

  /// Toggle label for pushing notifications to connected apps
  ///
  /// In en, this message translates to:
  /// **'Push to connected apps'**
  String get pushToConnectedApps;

  /// Subtitle for push to connected apps toggle
  ///
  /// In en, this message translates to:
  /// **'Send notifications to mobile & web via tunnel'**
  String get pushToConnectedAppsSubtitle;

  /// Voice setting label in notification settings
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voiceLabel;

  /// Default value label for voice setting
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// Dialog title for editing voice name
  ///
  /// In en, this message translates to:
  /// **'Voice Name'**
  String get voiceName;

  /// Speed setting label in notification settings
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedLabel;

  /// Default value label for settings
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// Dialog title for editing speech speed
  ///
  /// In en, this message translates to:
  /// **'Speed (words/min)'**
  String get speedWordsPerMin;

  /// Volume setting label in notification settings
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// Dialog title for editing volume
  ///
  /// In en, this message translates to:
  /// **'Volume (0.0-1.0)'**
  String get volumeRange;

  /// Quiet hours setting label
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get quietHours;

  /// Quiet hours disabled state label
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get quietHoursOff;

  /// Dialog title for editing quiet hours
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHoursTitle;

  /// Label for quiet hours start time field
  ///
  /// In en, this message translates to:
  /// **'Start (HH:MM)'**
  String get quietHoursStart;

  /// Label for quiet hours end time field
  ///
  /// In en, this message translates to:
  /// **'End (HH:MM)'**
  String get quietHoursEnd;

  /// Button label to turn off quiet hours
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get turnOff;

  /// Error message when saving fails, with error details
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSaveError(String error);

  /// Words per minute display format
  ///
  /// In en, this message translates to:
  /// **'{speed} wpm'**
  String wpmSuffix(String speed);

  /// Singular plan entity label
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// Singular request entity label
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @entityCreated.
  ///
  /// In en, this message translates to:
  /// **'{entity} created'**
  String entityCreated(String entity);

  /// No description provided for @entitySaved.
  ///
  /// In en, this message translates to:
  /// **'{entity} saved'**
  String entitySaved(String entity);

  /// No description provided for @aiGeneratingEntity.
  ///
  /// In en, this message translates to:
  /// **'AI is generating your {entity}...'**
  String aiGeneratingEntity(String entity);

  /// No description provided for @entityGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{entity} generated successfully'**
  String entityGeneratedSuccessfully(String entity);

  /// No description provided for @sendingPromptToAi.
  ///
  /// In en, this message translates to:
  /// **'Sending prompt to AI...'**
  String get sendingPromptToAi;

  /// No description provided for @responseReceivedParsing.
  ///
  /// In en, this message translates to:
  /// **'Response received, parsing...'**
  String get responseReceivedParsing;

  /// No description provided for @failedToParseAiResponse.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse AI response as JSON'**
  String get failedToParseAiResponse;

  /// No description provided for @terminalToolbarSearch.
  ///
  /// In en, this message translates to:
  /// **'Search ({key}F)'**
  String terminalToolbarSearch(String key);

  /// No description provided for @terminalToolbarDecreaseFontSize.
  ///
  /// In en, this message translates to:
  /// **'Decrease font size'**
  String get terminalToolbarDecreaseFontSize;

  /// No description provided for @terminalToolbarIncreaseFontSize.
  ///
  /// In en, this message translates to:
  /// **'Increase font size'**
  String get terminalToolbarIncreaseFontSize;

  /// No description provided for @terminalToolbarCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy ({key}C)'**
  String terminalToolbarCopy(String key);

  /// No description provided for @terminalToolbarPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste ({key}V)'**
  String terminalToolbarPaste(String key);

  /// No description provided for @terminalToolbarClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get terminalToolbarClear;

  /// No description provided for @terminalToolbarSendInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Send interrupt (Ctrl+C)'**
  String get terminalToolbarSendInterrupt;

  /// No description provided for @terminalTabCloseSession.
  ///
  /// In en, this message translates to:
  /// **'Close session'**
  String get terminalTabCloseSession;

  /// No description provided for @terminalTabNewSession.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get terminalTabNewSession;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @leaveEmptyForKeyAuth.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for key auth'**
  String get leaveEmptyForKeyAuth;

  /// Section header for passkeys settings
  ///
  /// In en, this message translates to:
  /// **'Passkeys'**
  String get passkeysTitle;

  /// No description provided for @passkeysDescription.
  ///
  /// In en, this message translates to:
  /// **'Passkeys use WebAuthn to let you sign in securely without a password. Use your fingerprint, face, or a hardware security key.'**
  String get passkeysDescription;

  /// No description provided for @registeredPasskeys.
  ///
  /// In en, this message translates to:
  /// **'Registered Passkeys'**
  String get registeredPasskeys;

  /// No description provided for @noPasskeysRegistered.
  ///
  /// In en, this message translates to:
  /// **'No passkeys registered'**
  String get noPasskeysRegistered;

  /// No description provided for @registerPasskeyHint.
  ///
  /// In en, this message translates to:
  /// **'Register a passkey above to enable passwordless sign-in.'**
  String get registerPasskeyHint;

  /// No description provided for @passkeyCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'Created {date}  ·  Last used {time}'**
  String passkeyCreatedDate(String date, String time);

  /// No description provided for @passkeySignInCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sign-in} other{{count} sign-ins}}'**
  String passkeySignInCount(int count);

  /// Clear action button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Agents tab label in agent instructions settings
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentInstructionsAgents;

  /// Context tab label in agent instructions settings
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get agentInstructionsContext;

  /// Workflow builder title when no name is set
  ///
  /// In en, this message translates to:
  /// **'New Workflow'**
  String get wbNewWorkflow;

  /// Button label to toggle YAML preview in workflow builder
  ///
  /// In en, this message translates to:
  /// **'YAML'**
  String get wbYaml;

  /// Button label to export workflow as a pack
  ///
  /// In en, this message translates to:
  /// **'Export Pack'**
  String get wbExportPack;

  /// Save button in workflow builder
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get wbSave;

  /// SnackBar message after saving a new workflow
  ///
  /// In en, this message translates to:
  /// **'Workflow saved ({id})'**
  String wbSaved(String id);

  /// SnackBar message after updating an existing workflow
  ///
  /// In en, this message translates to:
  /// **'Workflow updated'**
  String get wbUpdated;

  /// SnackBar message when saving fails
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String wbSaveFailed(String error);

  /// SnackBar message when loading a workflow fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load workflow: {error}'**
  String wbLoadFailed(String error);

  /// Canvas toolbar button to add a new state
  ///
  /// In en, this message translates to:
  /// **'Add State'**
  String get wbAddState;

  /// Canvas toolbar button to add a new transition
  ///
  /// In en, this message translates to:
  /// **'Add Transition'**
  String get wbAddTransition;

  /// Badge label shown on the initial state node
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get wbBadgeStart;

  /// Badge label shown on terminal state nodes
  ///
  /// In en, this message translates to:
  /// **'END'**
  String get wbBadgeEnd;

  /// Badge label shown on state nodes that have a skill attached
  ///
  /// In en, this message translates to:
  /// **'skill'**
  String get wbBadgeSkill;

  /// Badge label shown on state nodes that have an agent attached
  ///
  /// In en, this message translates to:
  /// **'agent'**
  String get wbBadgeAgent;

  /// Header label for the inspector panel in the workflow builder
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get wbInspector;

  /// Inspector type label when a state is selected
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get wbInspectorState;

  /// Inspector type label when a transition is selected
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get wbInspectorTransition;

  /// Inspector type label when a gate is selected
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get wbInspectorGate;

  /// Section label for workflow-level properties in inspector
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get wbSectionWorkflow;

  /// Form field label for workflow/state/gate name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get wbFieldName;

  /// Form field label for workflow description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get wbFieldDescription;

  /// Form field label for project ID
  ///
  /// In en, this message translates to:
  /// **'Project ID'**
  String get wbFieldProjectId;

  /// Hint text for the Project ID field
  ///
  /// In en, this message translates to:
  /// **'Auto-detected if empty'**
  String get wbProjectIdHint;

  /// Form field label for selecting the initial workflow state
  ///
  /// In en, this message translates to:
  /// **'Initial State'**
  String get wbFieldInitialState;

  /// Toggle label to mark this workflow as the project default
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get wbSetAsDefault;

  /// Section label for the gates list in the workflow inspector
  ///
  /// In en, this message translates to:
  /// **'Gates'**
  String get wbSectionGates;

  /// Button label to add a new gate
  ///
  /// In en, this message translates to:
  /// **'Add Gate'**
  String get wbAddGate;

  /// Validation hint when no terminal state exists
  ///
  /// In en, this message translates to:
  /// **'No terminal state defined'**
  String get wbNoTerminalState;

  /// Validation hint when the initial state ID is not found in the states list
  ///
  /// In en, this message translates to:
  /// **'Initial state is not in states list'**
  String get wbInvalidInitialState;

  /// Section label in the state inspector panel
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get wbSectionState;

  /// Form field label for state ID
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get wbFieldStateId;

  /// Hint text for the state ID field
  ///
  /// In en, this message translates to:
  /// **'e.g. in-progress'**
  String get wbStateIdHint;

  /// Form field label for state display label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get wbFieldStateLabel;

  /// Toggle label to mark a state as terminal
  ///
  /// In en, this message translates to:
  /// **'Terminal (done) state'**
  String get wbToggleTerminal;

  /// Toggle label to mark a state as active-work (counts toward WIP limit)
  ///
  /// In en, this message translates to:
  /// **'Active work (counts WIP)'**
  String get wbToggleActiveWork;

  /// Section label for skill attachment in the state inspector
  ///
  /// In en, this message translates to:
  /// **'Attached Skill'**
  String get wbSectionAttachedSkill;

  /// Section label for agent attachment in the state inspector
  ///
  /// In en, this message translates to:
  /// **'Attached Agent'**
  String get wbSectionAttachedAgent;

  /// Button label to remove a state from the workflow
  ///
  /// In en, this message translates to:
  /// **'Remove State'**
  String get wbRemoveState;

  /// Section label in the transition inspector panel
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get wbSectionTransition;

  /// Dropdown label for the source state of a transition
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get wbFieldFrom;

  /// Dropdown label for the target state of a transition
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get wbFieldTo;

  /// Dropdown label for selecting an optional gate on a transition
  ///
  /// In en, this message translates to:
  /// **'Gate (optional)'**
  String get wbFieldGateOptional;

  /// Dropdown option representing no gate on a transition
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get wbGateNone;

  /// Tooltip for the edit gate icon button in transition inspector
  ///
  /// In en, this message translates to:
  /// **'Edit gate'**
  String get wbEditGateTooltip;

  /// Button label to remove a transition
  ///
  /// In en, this message translates to:
  /// **'Remove Transition'**
  String get wbRemoveTransition;

  /// Section label in the gate inspector panel
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get wbSectionGate;

  /// Form field label for gate ID
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get wbFieldGateId;

  /// Hint text for the gate ID field
  ///
  /// In en, this message translates to:
  /// **'e.g. code_complete'**
  String get wbGateIdHint;

  /// Form field label for gate display label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get wbFieldGateLabel;

  /// Form field label for the required evidence section in a gate
  ///
  /// In en, this message translates to:
  /// **'Required Section'**
  String get wbFieldRequiredSection;

  /// Hint text for the required section field
  ///
  /// In en, this message translates to:
  /// **'e.g. Changes'**
  String get wbRequiredSectionHint;

  /// Form field label for file patterns in a gate
  ///
  /// In en, this message translates to:
  /// **'File Patterns (one per line)'**
  String get wbFieldFilePatterns;

  /// Hint text for the file patterns field
  ///
  /// In en, this message translates to:
  /// **'_test.go\n.test.ts'**
  String get wbFilePatternsHint;

  /// Form field label for the docs folder in a gate
  ///
  /// In en, this message translates to:
  /// **'Docs Folder'**
  String get wbFieldDocsFolder;

  /// Hint text for the docs folder field
  ///
  /// In en, this message translates to:
  /// **'docs (optional)'**
  String get wbDocsFolderHint;

  /// Form field label for feature kinds that can skip this gate
  ///
  /// In en, this message translates to:
  /// **'Skippable For (comma-separated)'**
  String get wbFieldSkippableFor;

  /// Hint text for the skippable-for field
  ///
  /// In en, this message translates to:
  /// **'bug, hotfix, testcase'**
  String get wbSkippableForHint;

  /// Button label to remove a gate
  ///
  /// In en, this message translates to:
  /// **'Remove Gate'**
  String get wbRemoveGate;

  /// Uppercase header label for the gates strip in the inspector
  ///
  /// In en, this message translates to:
  /// **'GATES'**
  String get wbGatesHeader;

  /// Message shown when no skills or agents are installed for the library picker
  ///
  /// In en, this message translates to:
  /// **'No {type}s installed'**
  String wbNoItemsInstalled(String type);

  /// Dropdown label for attaching a skill or agent to a state
  ///
  /// In en, this message translates to:
  /// **'Attach {type}'**
  String wbAttachItem(String type);

  /// Dropdown hint for selecting a skill or agent
  ///
  /// In en, this message translates to:
  /// **'Select {type}'**
  String wbSelectItem(String type);

  /// Tooltip for the copy YAML button
  ///
  /// In en, this message translates to:
  /// **'Copy YAML'**
  String get wbCopyYaml;

  /// SnackBar message after copying YAML to clipboard
  ///
  /// In en, this message translates to:
  /// **'YAML copied to clipboard'**
  String get wbYamlCopied;

  /// Title of the export pack bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Export as Pack'**
  String get wbExportTitle;

  /// Subtitle instruction in the export pack sheet
  ///
  /// In en, this message translates to:
  /// **'Commit these files to a GitHub repo and install with install_pack.'**
  String get wbExportSubtitle;

  /// Subsection header for next steps in the export sheet
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get wbNextSteps;

  /// Export instruction step 1
  ///
  /// In en, this message translates to:
  /// **'1. Create a GitHub repo: your-org/pack-{slug}'**
  String wbStep1(String slug);

  /// Export instruction step 2
  ///
  /// In en, this message translates to:
  /// **'2. Add pack.json + workflow/{slug}.yaml'**
  String wbStep2(String slug);

  /// Export instruction step 3
  ///
  /// In en, this message translates to:
  /// **'3. Install: install_pack repo:github.com/your-org/pack-{slug}'**
  String wbStep3(String slug);

  /// Export instruction step 4
  ///
  /// In en, this message translates to:
  /// **'4. Use /workflow-builder skill to generate skills per phase'**
  String get wbStep4;

  /// SnackBar message after copying a file to clipboard
  ///
  /// In en, this message translates to:
  /// **'{filename} copied'**
  String wbFileCopied(String filename);

  /// Admin nav: badges section title
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get adminBadges;

  /// Admin nav: points section title
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get adminPoints;

  /// Admin nav: verifications section title
  ///
  /// In en, this message translates to:
  /// **'Verifications'**
  String get adminVerifications;

  /// Dialog title and button for creating a badge
  ///
  /// In en, this message translates to:
  /// **'Create Badge'**
  String get adminCreateBadge;

  /// Dialog title for editing a badge
  ///
  /// In en, this message translates to:
  /// **'Edit Badge'**
  String get adminEditBadge;

  /// Dialog title for deleting a badge
  ///
  /// In en, this message translates to:
  /// **'Delete Badge'**
  String get adminDeleteBadge;

  /// Button label to open create badge dialog
  ///
  /// In en, this message translates to:
  /// **'Add Badge'**
  String get adminAddBadge;

  /// SnackBar after badge is created
  ///
  /// In en, this message translates to:
  /// **'Badge created'**
  String get adminBadgeCreated;

  /// SnackBar after badge is updated
  ///
  /// In en, this message translates to:
  /// **'Badge updated'**
  String get adminBadgeUpdated;

  /// SnackBar after badge is deleted
  ///
  /// In en, this message translates to:
  /// **'Badge deleted'**
  String get adminBadgeDeleted;

  /// Confirmation message before deleting a badge
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String adminDeleteBadgeConfirm(String name);

  /// Empty state when no badge definitions exist
  ///
  /// In en, this message translates to:
  /// **'No badges defined yet'**
  String get adminNoBadgesDefined;

  /// Empty state for user badge list
  ///
  /// In en, this message translates to:
  /// **'No badges awarded yet'**
  String get adminNoBadgesAwarded;

  /// Hint text for badges search field
  ///
  /// In en, this message translates to:
  /// **'Search badges...'**
  String get adminSearchBadges;

  /// Empty state when badge search returns no results
  ///
  /// In en, this message translates to:
  /// **'No badges matching \"{query}\"'**
  String adminNoBadgesMatching(String query);

  /// Input label for badge name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminBadgeName;

  /// Input label for badge description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminBadgeDescription;

  /// Input label for badge category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminBadgeCategory;

  /// Input label for badge icon
  ///
  /// In en, this message translates to:
  /// **'Icon (emoji or name)'**
  String get adminBadgeIcon;

  /// Input label for badge color
  ///
  /// In en, this message translates to:
  /// **'Color (hex)'**
  String get adminBadgeColor;

  /// Button and dialog title for awarding a badge to a user
  ///
  /// In en, this message translates to:
  /// **'Award Badge'**
  String get adminAwardBadge;

  /// SnackBar after awarding a badge
  ///
  /// In en, this message translates to:
  /// **'Awarded {name}'**
  String adminBadgeAwarded(String name);

  /// Points admin page title
  ///
  /// In en, this message translates to:
  /// **'Points Management'**
  String get adminPointsManagement;

  /// Label for points balance display
  ///
  /// In en, this message translates to:
  /// **'Points Balance'**
  String get adminPointsBalance;

  /// Section heading on points panel
  ///
  /// In en, this message translates to:
  /// **'Add or Deduct Points'**
  String get adminAddOrDeductPoints;

  /// Dialog title and button for awarding points
  ///
  /// In en, this message translates to:
  /// **'Award Points'**
  String get adminAwardPoints;

  /// Dialog title and button for deducting points
  ///
  /// In en, this message translates to:
  /// **'Deduct Points'**
  String get adminDeductPoints;

  /// Dialog subtitle when awarding points
  ///
  /// In en, this message translates to:
  /// **'Award points to {name}'**
  String adminAwardPointsTo(String name);

  /// Dialog subtitle when deducting points
  ///
  /// In en, this message translates to:
  /// **'Deduct points from {name}'**
  String adminDeductPointsFrom(String name);

  /// Input label for points amount
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adminPointsAmount;

  /// Input label for points transaction reason
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminPointsReason;

  /// SnackBar when points saved locally pending API
  ///
  /// In en, this message translates to:
  /// **'Saved (API not connected yet)'**
  String get adminPointsSavedPending;

  /// Panel title for transaction history
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get adminTransactionHistory;

  /// Empty state for transaction history
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get adminNoTransactions;

  /// Hint text for user search field
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get adminSearchUsers;

  /// Empty state when user list is empty
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoUsersFound;

  /// Empty state when user search returns no results
  ///
  /// In en, this message translates to:
  /// **'No users matching \"{query}\"'**
  String adminNoUsersMatching(String query);

  /// Error state when user list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get adminFailedToLoadUsers;

  /// Button label to award points
  ///
  /// In en, this message translates to:
  /// **'Award'**
  String get adminAward;

  /// Button label to deduct points
  ///
  /// In en, this message translates to:
  /// **'Deduct'**
  String get adminDeduct;

  /// Tooltip for award points icon button
  ///
  /// In en, this message translates to:
  /// **'Award Points'**
  String get adminAwardPointsTooltip;

  /// Tooltip for deduct points icon button
  ///
  /// In en, this message translates to:
  /// **'Deduct Points'**
  String get adminDeductPointsTooltip;

  /// Verifications admin page title
  ///
  /// In en, this message translates to:
  /// **'Verifications'**
  String get adminVerificationsTitle;

  /// Dialog title for changing user verification tier
  ///
  /// In en, this message translates to:
  /// **'Verification: {name}'**
  String adminVerificationFor(String name);

  /// Dialog body for verification tier selection
  ///
  /// In en, this message translates to:
  /// **'Select a verification tier for this user.'**
  String get adminVerificationSelectTier;

  /// Input label for verification tier dropdown
  ///
  /// In en, this message translates to:
  /// **'Verification Tier'**
  String get adminVerificationTier;

  /// SnackBar after updating verification tier
  ///
  /// In en, this message translates to:
  /// **'Verification updated to {tier}'**
  String adminVerificationUpdated(String tier);

  /// Button label to change verification tier
  ///
  /// In en, this message translates to:
  /// **'Change Tier'**
  String get adminChangeTier;

  /// Hint text for verifications search field
  ///
  /// In en, this message translates to:
  /// **'Search users by name, email, or handle...'**
  String get adminSearchVerifications;

  /// Empty state for verifications user list
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoVerificationUsersFound;

  /// Empty state when verification search returns no results
  ///
  /// In en, this message translates to:
  /// **'No users matching \"{query}\"'**
  String adminNoVerificationUsersMatching(String query);

  /// Error state when verifications list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get adminFailedToLoadVerifications;

  /// SnackBar after points are updated
  ///
  /// In en, this message translates to:
  /// **'Points updated'**
  String get adminPointsUpdated;

  /// SnackBar after points updated and badges awarded
  ///
  /// In en, this message translates to:
  /// **'Points updated. Badges awarded: {badges}'**
  String adminPointsUpdatedWithBadges(String badges);

  /// Generic error snackbar with error detail
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String adminErrorGeneric(String error);

  /// Error message when a list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String adminFailedToLoad(String error);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
