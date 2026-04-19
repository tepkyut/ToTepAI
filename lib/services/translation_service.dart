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
      'remember_me': 'Tandaan ako',
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
      'confirm_password': 'Kumpirma an Password',
      'username': 'Username',
      'enter_email': 'Butang an imong email',
      'enter_password': 'Butang an imong password',
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