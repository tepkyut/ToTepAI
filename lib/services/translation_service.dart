import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // LibreTranslate endpoint
  static const String _libreBaseUrl = 'https://libretranslate.com/translate';
  
  // Language codes mapping
  static const Map<String, String> _languageCodes = {
    'English': 'en',
    'Tagalog': 'tl',
    'Kamayo': 'kam',
  };

  // Reverse mapping for display
  static const Map<String, String> _codeToLanguage = {
    'en': 'English',
    'tl': 'Tagalog',
    'kam': 'Kamayo',
  };

  static String getLanguageCode(String language) {
    return _languageCodes[language] ?? 'en';
  }

  static String getLanguageName(String code) {
    return _codeToLanguage[code] ?? 'English';
  }

  // Translate using LibreTranslate API
  static Future<String> translate(String text, String sourceLanguage, String targetLanguage) async {
    final sourceCode = getLanguageCode(sourceLanguage);
    final targetCode = getLanguageCode(targetLanguage);

    if (sourceCode == targetCode) return text; // No translation needed

    try {
      final uri = Uri.parse(_libreBaseUrl);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': sourceCode,
          'target': targetCode,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] ?? text;
      } else {
        return text;
      }
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }

  // Hardcoded onboarding translations
  static const Map<String, Map<String, String>> _onboardingTranslations = {
    'English': {
      'welcome': 'Welcome to ToTepAI',
      'desc': 'An Intelligent system for bangus size classification and harvest forecasting using Gemini model and Arduino-Powered Segregation.',
      'classification': 'Smart Fish Classification',
      'classification_desc': 'Using sensors and the Gemini AI model, ToTepAI automatically sorts Bangus based on their weight with high precision.',
      'forecasting': 'Accurate Harvest Forecasting',
      'forecasting_desc': 'Predict your harvest time and yield efficiently through intelligent forecasting to improve farm productivity.',
      'empowering': 'Empowering Bangus Farmers',
      'empowering_desc': 'Save time, reduce errors, and make data-driven farming decisions with ToTepAI\'s smart automation.',
      'skip': 'Skip',
      'continue': 'Continue',
      'get_started': 'Get Started',
      'select_language': 'Select Language',
      'welcome_overview': "Here's your updated overview for today.",
      
      // Authentication translations
      'login': 'Log In',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'username': 'Username',
      'enter_email': 'Enter your email',
      'enter_password': 'Enter your password',
      'remember_me': 'Remember me',
      'login_with_google': 'Login with Google',
      'signup_with_google': 'Sign up with Google',
      'or': 'or',
      'email_required': 'Email is required',
      'password_required': 'Password is required',
      'username_required': 'Username is required',
      'confirm_password_required': 'Please confirm your password',
      'passwords_not_match': 'Passwords do not match',
      'login_successful': 'Login successful!',
      'account_created': 'Account created successfully!',
      'signed_in_with_google': 'Signed in with Google',
      'login_failed': 'Login failed',
      'no_account_found': 'No account found with this email address',
      'incorrect_password': 'Incorrect password. Please try again',
      'invalid_email': 'Invalid email address format',
      'account_disabled': 'This account has been disabled',
      'too_many_attempts': 'Too many failed attempts. Please try again later',
      'network_error': 'Network error. Please check your connection',
      'unexpected_error': 'An unexpected error occurred. Please try again.',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      
      // Dashboard translations
      'harvest_remarks': 'Harvest Remarks',
      'ai_powered_insights': 'AI-powered harvest insights',
      'no_remarks_available': 'No Remarks Available',
      'no_harvest_remarks_message': 'No harvest remarks available for the selected month. Try selecting a different month or add harvest data with forecast remarks.',
      'personal_information': 'Personal Information',
      'account_information': 'Account Information',
      'language': 'Language',
      'logout': 'Logout',
      
      // Calamity warning translations
      'typhoon_season_warning': 'The next harvest month falls within the high typhoon risk period (June–November). Secure ponds and infrastructure, prepare backup power and aeration, and monitor government advisories closely.',
      'monsoon_season_warning': 'The next harvest month is during the northeast monsoon season (December–February). Watch for strong winds, cooler temperatures, and changes in water quality.',
      'dry_season_warning': 'The next harvest month is in the dry and warm period (March–May). There is higher risk of heat stress and low dissolved oxygen, so increase monitoring and aeration.',
      'general_warning': 'Earthquakes and localized severe weather can occur at any time. Always follow official government and local advisories.',
      
      // Footer and legal translations
      'by_continuing_agree': 'By continuing, you agree to our ',
      'privacy_policy': 'Privacy Policy',
      'and': ' and ',
      'terms_of_service': 'Terms of Service',
      'close': 'Close',
      'last_updated': 'Last updated: April 2026',
      
      // Privacy Policy sections
      'privacy_title': 'Privacy Policy',
      'data_collection': 'Data Collection',
      'data_collection_content': 'ToTepAI systematically collects harvest data, fish growth patterns, and environmental information to deliver precise forecasting and comprehensive analytics for your aquaculture operations.',
      'data_usage': 'Data Usage',
      'data_usage_content': 'Your data is utilized exclusively for:\n• Generating personalized harvest forecasts\n• Providing weather-based agricultural recommendations\n• Enhancing our artificial intelligence algorithms\n• Creating anonymized industry insights and research',
      'data_protection': 'Data Protection',
      'data_protection_content': 'We employ enterprise-grade security protocols including:\n• End-to-end encrypted data transmission and storage\n• Multi-factor secure user authentication\n• Quarterly comprehensive security audits\n• Full compliance with international data protection regulations',
      'data_sharing': 'Data Sharing',
      'data_sharing_content': 'Your personal and operational data is never shared with external parties without your explicit written consent. Only anonymized, statistically aggregated data may be utilized for academic research and industry development.',
      'your_rights': 'Your Rights',
      'your_rights_content': 'You retain the following rights regarding your data:\n• Complete access to your stored information at any time\n• Request permanent data deletion and removal\n• Opt-out of ongoing data collection processes\n• Export your complete dataset in industry-standard formats',
      
      // Terms of Service sections
      'terms_title': 'Terms of Service',
      'acceptance_of_terms': 'Acceptance of Terms',
      'acceptance_of_terms_content': 'By accessing and utilizing ToTepAI services, you expressly agree to be bound by these terms and conditions. Should you disagree with any provision herein, you must immediately cease all use of our platform.',
      'service_description': 'Service Description',
      'service_description_content': 'ToTepAI is an advanced artificial intelligence platform designed for aquaculture management, delivering:\n• Sophisticated harvest forecasting and analytical insights\n• Meteorological-based agricultural recommendations\n• Comprehensive growth pattern analysis\n• Continuous real-time monitoring and reporting',
      'user_responsibilities': 'User Responsibilities',
      'user_responsibilities_content': 'As a registered user, you hereby commit to:\n• Provide accurate and verifiable harvest data\n• Utilize the service exclusively for legitimate aquaculture operations\n• Refrain from attempting to manipulate or compromise the AI system\n• Respect all intellectual property and proprietary rights',
      'service_availability': 'Service Availability',
      'service_availability_content': 'While we maintain a service level objective of 99.9% operational uptime, we cannot guarantee uninterrupted service availability. ToTepAI shall not be held liable for temporary service disruptions or data loss resulting from technical complications beyond our reasonable control.',
      'limitation_of_liability': 'Limitation of Liability',
      'limitation_of_liability_content': 'ToTepAI delivers predictive analytics and recommendations based on available data inputs. These insights are provided for guidance purposes only and must be supplemented with professional agricultural judgment. ToTepAI assumes no liability for operational decisions made in reliance upon our recommendations.',
      'account_termination': 'Account Termination',
      'account_termination_content': 'ToTepAI reserves the unilateral right to suspend or terminate user accounts that violate these terms, engage in fraudulent activities, or misuse the platform in any manner deemed detrimental to service integrity.',
      'modifications': 'Modifications',
      'modifications_content': 'These terms of service may be periodically amended at our discretion. Continued utilization of ToTepAI services following such modifications shall constitute unequivocal acceptance of the revised terms.',
      
      // Dashboard home page translations
      'welcome_back': 'Welcome back',
      'harvest_data_breakdown': 'Harvest Data Breakdown',
      'actual_data_of_harvest': 'Actual Data of Harvest',
      
      // Dashboard forecast page translations
      'bangus_class_tracking': 'Bangus Class Tracking',
      'year_comparison': 'Year Comparison',
      'ai_forecast_for_next_harvest': 'AI Forecast for Next Harvest',
      'forecast_model': 'Forecast Model',
      
      // Notification page translations
      'notifications': 'Notifications',
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark all as read',
      'clear_all': 'Clear all',
      'notification_settings': 'Notification settings',
      'harvest_control': 'Harvest Control',
      'contact_developer': 'Contact Developer',
      'developer_support': 'Developer Support',
      'need_help_contact': 'Need help? Contact our developer.',
      'harvest_active_message': 'Your harvest session is currently active. The system is ready to receive data from your device.',
      'other_user_harvesting': '{user} is currently harvesting. Please wait for the session to end.',
      'start_harvest_message': 'Start a harvest session to enable data collection from your device.',
      
      // Personal information field translations
      'full_name': 'Full Name',
      'phone_number': 'Phone Number',
      'city': 'City',
      'barangay': 'Barangay',
      'purok': 'Purok',
      'password_strength': 'Password strength: ',
    },
    'Tagalog': {
      'welcome': 'Maligayang Pagdating sa ToTepAI',
      'desc': 'Isang Matalinong sistema para sa klasipikasyon ng sukat ng bangus at pagtataya ng ani gamit ang Gemini model at Arduino-Powered Segregation.',
      'classification': 'Matalinong Klasipikasyon ng Isda',
      'classification_desc': 'Gamit ang mga sensor at Gemini AI model, awtomatikong inuuri ng ToTepAI ang mga Bangus batay sa kanilang timbang mataas na katumpakan.',
      'forecasting': 'Tumpak na Pagtataya ng Ani',
      'forecasting_desc': 'Hulaan ang iyong oras at ani nang mahusay sa pamamagitan ng matalinong pagtataya upang mapabuti ang produktibidad ng bukid.',
      'empowering': 'Pagpapalakas sa mga Mangingisda ng Bangus',
      'empowering_desc': 'Magtipid sa oras, bawasan ang mga mali, at gumawa ng mga desisyon sa pagbubukid na batay sa datos gamit ang smart automation ng ToTepAI.',
      'skip': 'Laktawan',
      'continue': 'Magpatuloy',
      'get_started': 'Magsimula',
      'select_language': 'Pumili ng Wika',
      'welcome_overview': 'Narito ang iyong update para sa araw na ito.',
      
      // Authentication translations
      'login': 'Mag-login',
      'signup': 'Mag-sign Up',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Kumpirmahin ang Password',
      'username': 'Username',
      'enter_email': 'Ilagay ang iyong email',
      'enter_password': 'Ilagay ang iyong password',
      'remember_me': 'Tandaan ko',
      'login_with_google': 'Mag-login gamit ang Google',
      'signup_with_google': 'Mag-sign up gamit ang Google',
      'or': 'o',
      'email_required': 'Kailangan ang email',
      'password_required': 'Kailangan ang password',
      'username_required': 'Kailangan ang username',
      'confirm_password_required': 'Kumpirmahin ang iyong password',
      'passwords_not_match': 'Hindi magtugma ang mga password',
      'login_successful': 'Matagumpay ang login!',
      'account_created': 'Matagumpay na nagawa ang account!',
      'signed_in_with_google': 'Naka-sign in gamit ang Google',
      'login_failed': 'Bigo ang login',
      'no_account_found': 'Walang nahanap na account sa email address na ito',
      'incorrect_password': 'Maling password. Subukan ulit',
      'invalid_email': 'Maling format ng email address',
      'account_disabled': 'Ang account na ito ay hindi na aktibo',
      'too_many_attempts': 'Maraming nabigong pagtatangka. Subukan ulit mamaya',
      'network_error': 'Error sa network. Suriin ang iyong koneksyon',
      'unexpected_error': 'May hindi inaasahang error. Subukan ulit.',
      'dont_have_account': 'Wala kang account?',
      'already_have_account': 'May account ka na ba?',
      
      // Dashboard translations
      'harvest_remarks': 'Mga Tala ng Ani',
      'ai_powered_insights': 'Mga insight sa ani na powered ng AI',
      'no_remarks_available': 'Walang Tala na Magagamit',
      'no_harvest_remarks_message': 'Walang tala ng ani na magagamit para sa napiling buwan. Subukan na pumili ng ibang buwan o magdagdag ng data ng ani na may mga forecast na tala.',
      'personal_information': 'Personal na Impormasyon',
      'account_information': 'Impormasyon ng Account',
      'language': 'Wika',
      'logout': 'Mag-logout',
      
      // Calamity warning translations
      'typhoon_season_warning': 'Ang susunod na buwan ng ani ay nasa panahon ng mataas na panganib ng bagyo (Hunyo–Nobyembre). I-secure ang mga pond at imprastraktura, ihanda ang backup power at aeration, at bantayan nang malapit ang mga advise ng gobyerno.',
      'monsoon_season_warning': 'Ang susunod na buwan ng ani ay panahon ng northeast monsoon (Disyembre–Pebrero). Magbantay sa malakas hangin, mas malamig na temperatura, at mga pagbabago sa kalidad ng tubig.',
      'dry_season_warning': 'Ang susunod na buwan ng ani ay sa tuyo at mainit na panahon (Marso–Mayo). Mas mataas ang panganib ng heat stress at mababang dissolved oxygen, kaya dagdagan ang monitoring at aeration.',
      'general_warning': 'Mga lindol at lokal na malubhang panahon ay maaaring mangyari anumang oras. Sundin palagi ang mga opisyal na advise ng gobyerno at lokal.',
      
      // Footer and legal translations
      'by_continuing_agree': 'Sa pagpapatuloy, sumasang-ayon ka sa aming ',
      'privacy_policy': 'Patakaran sa Privacy',
      'and': ' at ',
      'terms_of_service': 'Mga Tuntunin ng Serbisyo',
      'close': 'Isara',
      'last_updated': 'Huling na-update: Abril 2026',
      
      // Privacy Policy sections
      'privacy_title': 'Patakaran sa Privacy',
      'data_collection': 'Pangkolekta ng Datos',
      'data_collection_content': 'Ang ToTepAI ay sistematikong nangongolekta ng datos ng ani, mga pattern ng paglaki ng isda, at impormasyon sa kapaligiran upang maghatid ng tumpak na pagtataya at komprehensibong analytics para sa iyong operasyon sa aquaculture.',
      'data_usage': 'Paggamit ng Datos',
      'data_usage_content': 'Ang iyong datos ay ginagamit eksklusibo para sa:\n• Pagbuo ng personalized na forecast ng ani\n• Pagbibigay ng agricultural recommendation batay sa panahon\n• Pagpapabuti ng aming artificial intelligence algorithms\n• Paglikha ng anonymized na industry insights at research',
      'data_protection': 'Proteksyon ng Datos',
      'data_protection_content': 'Ginagamit namin ang enterprise-grade security protocols kasama ang:\n• End-to-end encrypted na transmisyon at storage ng datos\n• Multi-factor secure na user authentication\n• Quarterly na komprehensibong security audits\n• Full compliance sa international data protection regulations',
      'data_sharing': 'Pagbabahagi ng Datos',
      'data_sharing_content': 'Ang iyong personal at operational data ay hindi ibinabahagi sa mga panlabas na partido nang walang iyong explicit na pahintulot. Lamang ang anonymized, statistically aggregated data ang maaaring gamitin para sa academic research at industry development.',
      'your_rights': 'Iyong Karapatan',
      'your_rights_content': 'Nananatili kang may mga sumusunod na karapatan tungkol sa iyong datos:\n• Kumpletong access sa iyong naka-imporma anumang oras\n• Kahilingan ng permanenteng pagtanggal ng datos\n• Opt-out sa ongoing na data collection processes\n• I-export ang iyong kumpletong dataset sa industry-standard formats',
      
      // Terms of Service sections
      'terms_title': 'Mga Tuntunin ng Serbisyo',
      'acceptance_of_terms': 'Pagtanggap sa mga Tuntunin',
      'acceptance_of_terms_content': 'Sa pag-access at paggamit ng mga serbisyo ng ToTepAI, hayag kang sumasang-ayon na babalaan ng mga tuntunin at kondisyon na ito. Kung hindi ka sang-ayon sa anumang probisyon dito, dapat kang agad itigil ang lahat ng paggamit sa aming platform.',
      'service_description': 'Deskripsyon ng Serbisyo',
      'service_description_content': 'Ang ToTepAI ay isang advanced na artificial intelligence platform na idinisenyo para sa aquaculture management, nagbibigay ng:\n• Sophisticated na harvest forecasting at analytical insights\n• Meteorological-based na agricultural recommendations\n• Komprehensibong growth pattern analysis\n• Continuous real-time monitoring at reporting',
      'user_responsibilities': 'Responsibilidad ng User',
      'user_responsibilities_content': 'Bilang registered user, ikaw ay sumasang-ayon na:\n• Magbigay ng tumpak at mapatunayang datos ng ani\n• Gamitin ang serbisyo eksklusibo para sa legitimate na aquaculture operations\n• Refrain sa pagtatangka na manipulahin o i-compromise ang AI system\n• Respetuhin ang lahat ng intellectual property at proprietary rights',
      'service_availability': 'Availability ng Serbisyo',
      'service_availability_content': 'Habang pinapanatili namin ang service level objective na 99.9% operational uptime, hindi namin matitiyak ang uninterrupted na availability ng serbisyo. Ang ToTepAI ay hindi dapat managot sa temporaryong serbisyo disruptions o data loss na resulta sa mga teknikal na komplikasyon sa labas ng aming makatwirang kontrol.',
      'limitation_of_liability': 'Limitasyon ng Pananagutan',
      'limitation_of_liability_content': 'Ang ToTepAI ay nagbibigay ng predictive analytics at recommendations batay sa available na data inputs. Ang mga insights na ito ay ibinibigay para sa guidance purposes lamang at dapat i-supplement sa professional na agricultural judgment. Ang ToTepAI ay hindi tumatanggap ng pananagutan para sa operational na desisyon na ginawa sa pagtitiwala sa aming mga recommendations.',
      'account_termination': 'Pagwawakas ng Account',
      'account_termination_content': 'Ang ToTepAI ay nagrarerserba ng unilateral na karapatan na isuspend o i-terminate ang mga user account na lumalabag sa mga tuntuning ito, nagsasagawa ng fraudulent na aktibidades, o nagsamantala sa platform sa anumang paraang itinuturing na detrimental sa service integrity.',
      'modifications': 'Mga Modipikasyon',
      'modifications_content': 'Ang mga tuntunin ng serbisyo na ito ay maaaring periodikong baguhin sa aming diskresyon. Ang patuloy na paggamit ng mga serbisyo ng ToTepAI pagkatapos ng mga modipikasyong ito ay bubuuoin ng unequivocal na pagtanggap sa mga na-revised na tuntunin.',
      
      // Dashboard home page translations
      'welcome_back': 'Maligayang pagbalik',
      'harvest_data_breakdown': 'Detalye ng Datos ng Ani',
      'actual_data_of_harvest': 'Aktwal na Datos ng Ani',
      
      // Dashboard forecast page translations
      'bangus_class_tracking': 'Pagsubaybay sa Klase ng Bangus',
      'year_comparison': 'Pagkukumpara sa Taon',
      'ai_forecast_for_next_harvest': 'AI Forecast para sa Susunod na Ani',
      'forecast_model': 'Forecast Model',
      'harvest_control': 'Kontrol sa Ani',
      'contact_developer': 'Kontak ng Developer',
      'developer_support': 'Suporta ng Developer',
      'need_help_contact': 'Kailangan ng tulong? Kontak ang aming developer.',
      'harvest_active_message': 'Ang iyong harvest session ay kasalukuyang aktibo. Ang system ay handang makatanggap ng data mula sa iyong device.',
      'other_user_harvesting': '{user} ay kasalukuyang naghaharvest. Maghintay hanggang sa matapos ang session.',
      'start_harvest_message': 'Simulan ang harvest session para paganahin ang pag-collect ng data mula sa iyong device.',
      
      // Personal information field translations
      'full_name': 'Buong Pangalan',
      'phone_number': 'Numero ng Telepono',
      'city': 'Lungsod',
      'barangay': 'Barangay',
      'purok': 'Purok',
      'password_strength': 'Lakas ng password: ',
    },
    'Kamayo': {
      'welcome': 'Madayaw na Pag-abot sa kanami sistem na ToTepAI',
      'desc': 'Isa ini ka madayaw ug matigam na sistema sa paggamit para sa pagklasipikar ng kabadihon ng bangus ug pagtukma sini gamit ang Gemini model ug Arduino na pagplastar.',
      'classification': 'Madayaw na Pagklasipikar ng Isda',
      'classification_desc': 'Pamaagi sa mga sensor ug Gemini AI model, awtomatik na paga klasipikar ng ToTepAI ang bangus base sa kaniran timbang.',
      'forecasting': 'Sakto na Pagtugma sini',
      'forecasting_desc': 'Matukmaan ang kanmo harvest ug ang oras na sakto pamaagi gikan sa ToTepAI na sistem para mapabadi ang produkto sa pag-ani.',
      'empowering': 'Pagtabang sa mga Mangisdaay ng Bangus',
      'empowering_desc': 'Makuhaan ang oras, malikayan ang mga sayop, ug makahimo ng mas madayaw na desisyon sa pag-uma pamaagi sa smart automation ng ToTepAI.',
      'skip': 'Laktawi',
      'continue': 'Padayon',
      'get_started': 'Sugdi',
      'select_language': 'Pilia ang gusto mo na klasi ng inisturyahan',
      'welcome_overview': 'Mao kini ang imong update para sa karon nga adlaw.',
      
     // Authentication translations
      'login': 'Mag-login',
      'signup': 'Magparehistro',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Kunpirmaha an Password',
      'username': 'Username',
      'enter_email': 'ibutang imong email',
      'enter_password': 'ibutang imong password',
      'remember_me': 'Hinumdumi ako',
      'login_with_google': 'Mag-login gamit an Google',
      'signup_with_google': 'Magparehistro gamit an Google',
      'or': 'o',
      'email_required': 'Kinahanglan an email',
      'password_required': 'Kinahanglan an password',
      'username_required': 'Kinahanglan an username',
      'confirm_password_required': 'Kumpirma an imong password',
      'passwords_not_match': 'Dili magkapareho an mga password',
      'login_successful': 'Maayo an pag-login!',
      'account_created': 'Nahimo na an account!',
      'no_account_found': 'Wara account nga nakita sa ini nga email',
      'incorrect_password': 'Sayop an password. Sulayi liwat',
      'invalid_email': 'Sayop an porma sa email',
      'account_disabled': 'Ini nga account dili na aktibo',
      'too_many_attempts': 'Damo sayop nga pagsulay. Sulayi liwat sa urhi',
      'network_error': 'May error sa network. Tan-awa an imong koneksyon',
      'unexpected_error': 'May diri ginlauman nga error. Sulayi liwat',
      'dont_have_account': 'Wara kay account?',
      'already_have_account': 'Aron day account?',

  // Dashboard translations
      'harvest_remarks': 'Mga Tala ng Ani',
      'ai_powered_insights': 'Mga insight ng ani nga gikan sa AI',
      'no_remarks_available': 'Wara pay tala',
      'no_harvest_remarks_message': 'Wara pay tala ng ani para han napili nga bulan. Pwede ka pa mamili ng iba nga bulan o magdugang ng data sa ani nga may panabot.',
      'personal_information': 'Sariling Impormasyon',
      'account_information': 'Impormasyon ng Account',
      'language': 'Pinulongan',
      'logout': 'Gawas',
      
      // Calamity warning translations
      'typhoon_season_warning': 'Ang sunod na bulan sa ani naa sa panahon taas nga peligro sa bagyo (Hunyo–Nobyembre). Segurohun ang mga pond ug imprastraktura, andam ang backup power ug aeration, ug bantayan ang mga advise sa gobyerno.',
      'monsoon_season_warning': 'Ang sunod na bulan sa ani ay panahon sa northeast monsoon (Disyembre–Pebrero. Bantayi ang kuwang nga hangin, mas bugnaw nga temperatura, ug mga kausaban sa kalidad sa tubig.',
      'dry_season_warning': 'Ang sunod na bulan sa ani anaa sa tuyo ug mainit nga panahon (Marso–Mayo. Mas taas ang peligro sa heat stress ug mababa ang dissolved oxygen, sukad ani dugangan ang monitoring ug aeration.',
      'general_warning': 'Mga lindol ug lokal nga grabe nga panahon mahimong mahitabi bisan asa. Palagi sunod ang mga opisyal nga advise sa gobyerno ug lokal.',
      
      // Footer and legal translations
      'by_continuing_agree': 'Sa pagpadayon, sumasang-ayon ka sa aming ',
      'privacy_policy': 'Patakaran sa Privacy',
      'and': ' ug ',
      'terms_of_service': 'Mga Tuntunin sa Serbisyo',
      'close': 'Isara',
      'last_updated': 'Kataposang na-update: Abril 2026',
      
      // Privacy Policy sections
      'privacy_title': 'Patakaran sa Privacy',
      'data_collection': 'Pang kolekta sa Datos',
      'data_collection_content': 'Ang ToTepAI kay sistematiko nga nangolekta sa datos sa ani, mga pattern sa pagtubo sa isda, ug impormasyon sa kapaligiran aron maghatag sa tukma nga pagtagna ug komprehensibong analytics para sa imong operasyon sa aquaculture.',
      'data_usage': 'Paggamit sa Datos',
      'data_usage_content': 'Ang imong datos kay gigamit eksklusibo para sa:\\n• Pagbuo sa personalized nga forecast sa ani\\n• Paghatag sa agricultural recommendation base sa panahon\\n• Pagpalambo sa among artificial intelligence algorithms\\n• Paglikha sa anonymized nga industry insights ug research',
      'data_protection': 'Proteksyon sa Datos',
      'data_protection_content': 'Gigamit namo ang enterprise-grade security protocols lakip sa:\\n• End-to-end encrypted nga transmisyon ug storage sa datos\\n• Multi-factor secure nga user authentication\\n• Quarterly nga komprehensibong security audits\\n• Full compliance sa international data protection regulations',
      'data_sharing': 'Pagbahagi sa Datos',
      'data_sharing_content': 'Ang imong personal ug operational data kay dili ibahagi sa mga external party walay imong explicit nga pahintulot. Lamang ang anonymized, statistically aggregated data ang mahimong gamiton para sa academic research ug industry development.',
      'your_rights': 'Imong Karapatan',
      'your_rights_content': 'Nanatili ka may mga sumusunod nga karapatan bahin sa imong datos:\\n• Kompletong access sa imong gipang-impormahan bisan unsang oras\\n• Hangyo sa permanenteng pagtangtang sa datos\\n• Opt-out sa ongoing nga data collection processes\\n• I-export ang imong kumpletong dataset sa industry-standard formats',
      
      // Terms of Service sections
      'terms_title': 'Mga Tuntunin sa Serbisyo',
      'acceptance_of_terms': 'Pagtanggap sa mga Tuntunin',
      'acceptance_of_terms_content': 'Sa pag-access ug paggamit sa mga serbisyo sa ToTepAI, hayag ka nga sumasang-ayon nga balaan sa mga tuntunin ug kondisyon nga ini. Kung dili ka sang-ayon sa bisan unsang probisyon dinhi, kinahanglan ka nga dayon itigil ang tanan nga paggamit sa among platform.',
      'service_description': 'Deskripsyon sa Serbisyo',
      'service_description_content': 'Ang ToTepAI kay usa ka advanced nga artificial intelligence platform nga gidesenyo para sa aquaculture management, naghatag sa:\\n• Sophisticated nga harvest forecasting ug analytical insights\\n• Meteorological-based nga agricultural recommendations\\n• Komprehensibong growth pattern analysis\\n• Continuous real-time monitoring ug reporting',
      'user_responsibilities': 'Responsibilidad sa User',
      'user_responsibilities_content': 'Bilang registered user, ikaw kay sumasang-ayon nga:\\n• Maghatag sa tukma ug mapatunayang datos sa ani\\n• Gamiton ang serbisyo eksklusibo para sa legitimate nga aquaculture operations\\n• Refrain sa pagtangka nga manipulahon o i-compromise ang AI system\\n• Respetuhon ang tanan nga intellectual property ug proprietary rights',
      'service_availability': 'Availability sa Serbisyo',
      'service_availability_content': 'Samtang nagpapanatili kami sa service level objective nga 99.9% operational uptime, dili kami makatiyak sa uninterrupted nga availability sa serbisyo. Ang ToTepAI kay dili dapat managot sa temporaryong serbisyo disruptions o data loss nga resulta sa mga teknikal nga komplikasyon sa gawas sa among makatarunganong kontrol.',
      'limitation_of_liability': 'Limitasyon sa Pananagutan',
      'limitation_of_liability_content': 'Ang ToTepAI kay naghatag sa predictive analytics ug recommendations base sa available nga data inputs. Ang mga insights nga kay kay ibigay para sa guidance purposes lamang ug kinahanglan i-supplement sa professional nga agricultural judgment. Ang ToTepAI kay dili motanggap sa pananagutan para sa operational nga desisyon nga gibuhat sa pagtuo sa among mga recommendations.',
      'account_termination': 'Pagwakas sa Account',
      'account_termination_content': 'Ang ToTepAI kay nagrarerserba sa unilateral nga karapatan nga isuspend o i-terminate ang mga user account nga nalabag sa mga tuntunin nga ini, nagsagawa sa fraudulent nga aktibidades, o nagsamantala sa platform sa bisan unsang pa nga itinuturing nga detrimental sa service integrity.',
      'modifications': 'Mga Modipikasyon',
      'modifications_content': 'Ang mga tuntunin sa serbisyo nga kay maaaring periodikong usbon sa among diskresyon. Ang padayon nga paggamit sa mga serbisyo sa ToTepAI pagkahuman sa mga modipikasyon nga kay moporma sa unequivocal nga pagtanggap sa mga na-revised nga tuntunin.',
      
      // Dashboard home page translations
      'welcome_back': 'Madayaw nga pagbalik',
      'harvest_data_breakdown': 'Detalye sa Datos sa Ani',
      'actual_data_of_harvest': 'Aktwal na Datos sa Ani',
      
      // Dashboard forecast page translations
      'bangus_class_tracking': 'Pagsubaybay sa Klase sa Bangus',
      'year_comparison': 'Pagkukumpara sa Tuig',
      'ai_forecast_for_next_harvest': 'AI Forecast para sa Sunod nga Ani',
      'forecast_model': 'Forecast Model',
      'harvest_control': 'Kontrol sa Ani',
      'contact_developer': 'Kontak ng Developer',
      'developer_support': 'Suporta sa Developer',
      'need_help_contact': 'Kinahanglan ug tabang? Kontaka ang aming developer.',
      'harvest_active_message': 'Ang imong harvest session kay karon aktibo. Ang system kay andam makadawat sa data gikan sa imong device.',
      'other_user_harvesting': 'Si {user} kay karon nag-ani. Paghulat hangtod matapos ang session.',
      'start_harvest_message': 'Pagsugod sa harvest session para paganahin ang pag-collect sa data gikan sa imong device.',
      
      // Personal information field translations
      'full_name': 'Puno nga Ngalan',
      'phone_number': 'Numero sa Telepono',
      'city': 'Siudad',
      'barangay': 'Barangay',
      'purok': 'Purok',
      'password_strength': 'Lakas sa password: ',
    },
  };

  // Get translation with fallback
  static Future<String> getTranslation(String key, String language) async {
    final englishText = _onboardingTranslations['English']?[key] ?? key;

    if (language == 'English') return englishText;

    // Try API translation
    final translatedText = await translate(englishText, 'English', language);

    if (translatedText != englishText) return translatedText;

    // Fallback to hardcoded translation
    return _onboardingTranslations[language]?[key] ?? englishText;
  }

  // Synchronous version for immediate UI updates
  static String getTranslationSync(String key, String language) {
    return _onboardingTranslations[language]?[key] ?? _onboardingTranslations['English']?[key] ?? key;
  }

  static List<String> getSupportedLanguages() {
    return ['English', 'Tagalog', 'Kamayo'];
  }
}