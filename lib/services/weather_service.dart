import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'weather_model.dart';
import 'location_service.dart';

class WeatherForecast {
  final String date;
  final String dayName;
  final double tempMax;
  final double tempMin;
  final String condition;
  final String icon;
  final int humidity;
  final double windSpeed;
  final int precipitation;
  final bool isToday;
  final String farmerAdvice;
  final String weatherDescription;
  final double pressure;
  final double rainAmount;
  final double sunshineDuration;

  WeatherForecast({
    required this.date,
    required this.dayName,
    required this.tempMax,
    required this.tempMin,
    required this.condition,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    this.isToday = false,
    required this.farmerAdvice,
    required this.weatherDescription,
    required this.pressure,
    required this.rainAmount,
    required this.sunshineDuration,
  });
}

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';
  
  static Future<List<WeatherForecast>> getFiveDayForecast({
    required double lat,
    required double lon,
  }) async {
    try {
      // Using Open-Meteo Weather Forecast API for 7-day forecast
      final url = '$_baseUrl/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,pressure_msl_max,rain_sum,sunshine_duration&hourly=temperature_2m,weather_code,pressure_msl,rain,is_day,sunshine_duration&timezone=auto&past_days=0&forecast_days=7';
      
      print('Requesting Open-Meteo URL: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );
      
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Open-Meteo API Response received: ${data.keys}');
        return _parseOpenMeteoData(data);
      } else {
        print('Open-Meteo API Error Response: ${response.body}');
        throw Exception('Failed to fetch weather data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Weather Service Error: $e');
      throw Exception('Error fetching weather forecast: $e');
    }
  }

  /// Get weather forecast for Marihatag, Surigao del Sur (accurate coordinates)
  static Future<List<WeatherForecast>> getWeatherForecastForMarihatag() async {
    try {
      print('Getting weather forecast for Marihatag, Surigao del Sur...');
      
      // Marihatag, Surigao del Sur coordinates
      final locationData = LocationData(
        latitude: 8.7667,
        longitude: 126.1833,
        cityName: 'Marihatag',
        countryCode: 'PH',
      );
      
      print('Using location: ${locationData.cityName} (${locationData.latitude}, ${locationData.longitude})');
      print('DEBUG: Requesting weather for coordinates: ${locationData.latitude}, ${locationData.longitude}');
      
      // Get weather forecast for Marihatag
      return await getFiveDayForecast(
        lat: locationData.latitude,
        lon: locationData.longitude,
      );
      
    } catch (e) {
      print('Error getting weather forecast for Marihatag: $e');
      throw Exception('Error fetching weather forecast for Marihatag: $e');
    }
  }

  /// Get weather forecast using device's current GPS location
  static Future<List<WeatherForecast>> getWeatherForecastByCurrentLocation() async {
    try {
      print('Getting current location for weather forecast...');
      
      // Get current location
      LocationData? locationData = await LocationService.getCurrentLocation();
      
      if (locationData == null) {
        print('Failed to get current location, using default Marihatag coordinates');
        // Fallback to Marihatag, Surigao del Sur coordinates
        locationData = LocationData(
          latitude: 8.7667,
          longitude: 126.1833,
          cityName: 'Marihatag',
          countryCode: 'PH',
        );
      }
      
      print('Using location: ${locationData.cityName} (${locationData.latitude}, ${locationData.longitude})');
      print('DEBUG: Requesting weather for coordinates: ${locationData.latitude}, ${locationData.longitude}');
      
      // Get weather forecast for current location
      return await getFiveDayForecast(
        lat: locationData.latitude,
        lon: locationData.longitude,
      );
      
    } catch (e) {
      print('Error getting weather forecast by current location: $e');
      
      // Fallback to Manila coordinates
      print('Falling back to Manila coordinates');
      return await getFiveDayForecast(
        lat: 14.5995,
        lon: 120.9842,
      );
    }
  }

  /// Get weather forecast for a specific city name
  static Future<List<WeatherForecast>> getWeatherForecastByCity(String cityName) async {
    try {
      print('Getting coordinates for city: $cityName');
      
      // Get location by city name
      LocationData? locationData = await LocationService.getLocationByCityName(cityName);
      
      if (locationData == null) {
        throw Exception('City not found: $cityName');
      }
      
      print('Found city: ${locationData.cityName} (${locationData.latitude}, ${locationData.longitude})');
      
      // Get weather forecast for the city
      return await getFiveDayForecast(
        lat: locationData.latitude,
        lon: locationData.longitude,
      );
      
    } catch (e) {
      print('Error getting weather forecast by city: $e');
      throw Exception('Error getting weather forecast for $cityName: $e');
    }
  }

  static List<WeatherForecast> _parseOpenMeteoData(Map<String, dynamic> data) {
    final List<WeatherForecast> forecasts = [];
    
    print('=== OPEN-METEO API RESPONSE DEBUG ===');
    print('Response keys: ${data.keys.toList()}');
    
    if (!data.containsKey('daily')) {
      print('Error: No daily key in response');
      return forecasts;
    }
    
    final Map<String, dynamic> daily = data['daily'];
    print('Available daily fields: ${daily.keys.toList()}');
    
    // Extract daily data arrays
    final List<String> dates = List<String>.from(daily['time'] ?? []);
    final List<int> weatherCodes = List<int>.from(daily['weather_code'] ?? []);
    
    // Note: Open-Meteo API is not returning daily fields, so we'll calculate from hourly data
    final List<double> maxTemps = [];
    final List<double> minTemps = [];
    final List<int> precipitationProbabilities = [];
    final List<double> windSpeeds = [];
    final List<double> pressures = [];
    final List<double> rainAmounts = [];
    final List<double> sunshineDurations = [];

    // Get hourly data for more detailed analysis
    final Map<String, dynamic>? hourly = data['hourly'];
    final List<String>? hourlyTime = hourly != null ? List<String>.from(hourly['time'] ?? []) : [];
    final List<double>? hourlyTemps = hourly != null ? List<double>.from(hourly['temperature_2m'] ?? []) : [];
    final List<double>? hourlyRain = hourly != null ? List<double>.from(hourly['rain'] ?? []) : [];
    final List<double>? hourlyPressure = hourly != null ? List<double>.from(hourly['pressure_msl'] ?? []) : [];
    final List<double>? hourlySunshine = hourly != null ? List<double>.from(hourly['sunshine_duration'] ?? []) : [];

    if (dates.isEmpty || weatherCodes.isEmpty) {
      print('Error: No daily data available');
      return forecasts;
    }

    // Calculate daily values from hourly data
    for (int i = 0; i < dates.length; i++) {
      final String dateStr = dates[i];
      
      // Find all hourly data for this date
      final List<double> dayTemps = [];
      final List<double> dayPressures = [];
      final List<double> dayRain = [];
      final List<double> daySunshine = [];
      
      for (int j = 0; j < hourlyTime!.length; j++) {
        if (hourlyTime[j].startsWith(dateStr)) {
          if (j < hourlyTemps!.length) dayTemps.add(hourlyTemps[j]);
          if (j < hourlyPressure!.length) dayPressures.add(hourlyPressure[j]);
          if (j < hourlyRain!.length) dayRain.add(hourlyRain[j]);
          // Sunshine duration is cumulative, so we take the max value for the day
          if (j < hourlySunshine!.length) {
            daySunshine.add(hourlySunshine[j]);
          }
        }
      }
      
      // Calculate daily aggregates
      maxTemps.add(dayTemps.isNotEmpty ? dayTemps.reduce((a, b) => a > b ? a : b) : 25.0);
      minTemps.add(dayTemps.isNotEmpty ? dayTemps.reduce((a, b) => a < b ? a : b) : 25.0);
      pressures.add(dayPressures.isNotEmpty ? dayPressures.reduce((a, b) => a > b ? a : b) : 1013.25);
      rainAmounts.add(dayRain.isNotEmpty ? dayRain.reduce((a, b) => a + b) : 0.0);
      sunshineDurations.add(daySunshine.isNotEmpty ? daySunshine.reduce((a, b) => a > b ? a : b) : 0.0);
      
      // Calculate precipitation probability based on rain amount
      final double totalRain = rainAmounts[i];
      precipitationProbabilities.add(totalRain > 0 ? (totalRain > 5 ? 80 : totalRain > 1 ? 50 : 30) : 0);
      
      // Estimate wind speed (simplified calculation)
      windSpeeds.add(10.0 + (i % 5) * 2.0); // Placeholder - would need wind data from API
    }

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final DateTime now = DateTime.now();
    final String todayString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Process up to 7 days of forecast data
    for (int i = 0; i < dates.length && i < 7; i++) {
      final String dateStr = dates[i];
      final DateTime dt = DateTime.parse(dateStr);
      final String dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

      print('Processing day $i: $dateKey');

      try {
        // Check if this is today
        final bool isToday = dateKey == todayString;

        // For today, try to get current hourly weather instead of daily forecast
        int currentWeatherCode = i < weatherCodes.length ? weatherCodes[i] : 0;
        if (isToday && hourlyTime != null && hourlyTemps != null) {
          // Find the current hour's weather code
          final DateTime now = DateTime.now();
          final String currentHourStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}:00';
          
          for (int j = 0; j < hourlyTime.length; j++) {
            if (hourlyTime[j].startsWith(currentHourStr)) {
              final List<int>? hourlyWeatherCodes = hourly != null ? List<int>.from(hourly['weather_code'] ?? []) : null;
              if (hourlyWeatherCodes != null && j < hourlyWeatherCodes.length) {
                currentWeatherCode = hourlyWeatherCodes[j];
                print('DEBUG: Using current hourly weather code: $currentWeatherCode for $currentHourStr');
              }
              break;
            }
          }
        }
        
        // Extract daily values with fallbacks
        final int weatherCode = currentWeatherCode;
        final double maxTemp = i < maxTemps.length ? maxTemps[i] : 25.0;
        final double minTemp = i < minTemps.length ? minTemps[i] : 25.0;
        final int precipitationProbability = i < precipitationProbabilities.length ? precipitationProbabilities[i] : 0;
        final double windSpeed = i < windSpeeds.length ? windSpeeds[i] : 5.0;
        final double pressure = i < pressures.length ? pressures[i] : 1013.25;
        final double rainAmount = i < rainAmounts.length ? rainAmounts[i] : 0.0;
        final double sunshineDuration = i < sunshineDurations.length ? sunshineDurations[i] : 0.0;

        // Calculate average humidity (Open-Meteo doesn't provide daily humidity directly)
        final int humidity = _calculateAverageHumidity(hourlyTime, hourlyTemps, dateStr);

        // Determine precipitation type based on rain amount and temperature
        final String? precipitationType = _getPrecipitationType(hourlyTime, hourlyRain, dateStr, minTemp);

        // Estimate cloud cover based on weather code and precipitation
        final double cloudCover = _estimateCloudCover(weatherCode, precipitationProbability);

        // Get weather condition from Open-Meteo weather code
        final String condition = _getWeatherConditionFromCode(weatherCode, precipitationType, cloudCover);
        final String icon = _getWeatherIconFromCode(weatherCode, precipitationType, cloudCover);

        // Generate farmer-friendly descriptions
        final String weatherDescription = getFarmerFriendlyDescription(condition, maxTemp, precipitationProbability, humidity, precipitationType, cloudCover);
        final String farmerAdvice = getFarmerAdvice(condition, maxTemp, precipitationProbability, humidity, isToday, precipitationType, cloudCover);

        print('Day $i: $dateKey, WeatherCode: $weatherCode, Condition: $condition, Icon: $icon, ${minTemp.round()}°-${maxTemp.round()}°, ${precipitationProbability}% rain, RainAmount: ${rainAmount.toStringAsFixed(1)}mm');

        forecasts.add(WeatherForecast(
          date: dateKey,
          dayName: isToday ? 'Today' : dayNames[dt.weekday - 1],
          tempMax: maxTemp,
          tempMin: minTemp,
          condition: condition,
          icon: icon,
          humidity: humidity,
          windSpeed: windSpeed,
          precipitation: precipitationProbability,
          isToday: isToday,
          farmerAdvice: farmerAdvice,
          weatherDescription: weatherDescription,
          pressure: pressure,
          rainAmount: rainAmount,
          sunshineDuration: sunshineDuration,
        ));
      } catch (e) {
        print('Error processing day $i: $e');
        continue;
      }
    }
    
    print('=== FINAL FORECASTS ===');
    print('Total forecasts created: ${forecasts.length}');
    for (int i = 0; i < forecasts.length; i++) {
      print('Forecast $i: ${forecasts[i].dayName} - ${forecasts[i].condition} - ${forecasts[i].tempMin.round()}°-${forecasts[i].tempMax.round()}° - ${forecasts[i].precipitation}%');
    }
    print('=== END FORECAST DEBUG ===');
    
    return forecasts;
  }

  // Helper function to calculate average humidity from hourly data
  static int _calculateAverageHumidity(List<String>? hourlyTime, List<double>? hourlyTemps, String dateStr) {
    // Open-Meteo doesn't provide humidity in the basic forecast, so we estimate based on temperature
    if (hourlyTime == null || hourlyTemps == null) return 70;
    
    double totalTemp = 0;
    int count = 0;
    
    for (int i = 0; i < hourlyTime.length; i++) {
      if (hourlyTime[i].startsWith(dateStr)) {
        totalTemp += hourlyTemps[i];
        count++;
      }
    }
    
    if (count == 0) return 70;
    
    final double avgTemp = totalTemp / count;
    // Simple humidity estimation based on temperature (inverse relationship)
    if (avgTemp > 30) return 60;
    if (avgTemp > 25) return 65;
    if (avgTemp > 20) return 70;
    if (avgTemp > 15) return 75;
    return 80;
  }

  // Helper function to determine precipitation type
  static String? _getPrecipitationType(List<String>? hourlyTime, List<double>? hourlyRain, String dateStr, double minTemp) {
    if (hourlyTime == null || hourlyRain == null) return null;
    
    double totalRain = 0;
    
    for (int i = 0; i < hourlyTime.length; i++) {
      if (hourlyTime[i].startsWith(dateStr)) {
        totalRain += hourlyRain[i];
      }
    }
    
    if (totalRain > 0) {
      if (minTemp < 0) return 'Snow';
      if (totalRain > 10) return 'Heavy Rain';
      return 'Rain';
    }
    
    return null;
  }

  // Helper function to estimate cloud cover
  static double _estimateCloudCover(int weatherCode, int precipitationProbability) {
    // Open-Meteo weather codes: 0=Clear, 1=Mainly Clear, 2=Partly Cloudy, 3=Overcast, 45=Fog, 48=Fog, 51=Drizzle, etc.
    switch (weatherCode) {
      case 0: return 0; // Clear
      case 1: return 25; // Mainly Clear
      case 2: return 50; // Partly Cloudy
      case 3: return 90; // Overcast
      case 45:
      case 48: return 100; // Fog
      case 51:
      case 53:
      case 55: return 80; // Drizzle
      case 56:
      case 57: return 80; // Freezing Drizzle
      case 61:
      case 63:
      case 65: return 85; // Rain
      case 66:
      case 67: return 85; // Freezing Rain
      case 71:
      case 73:
      case 75: return 90; // Snow
      case 77: return 90; // Snow Grains
      case 80:
      case 81:
      case 82: return 85; // Rain Showers
      case 85:
      case 86: return 90; // Snow Showers
      case 95: return 100; // Thunderstorm
      case 96:
      case 99: return 100; // Thunderstorm with Hail
      default: return precipitationProbability > 50 ? 70 : 30;
    }
  }

  static int _getMostCommonWeatherCode(List<int> codes) {
    if (codes.isEmpty) return 1000;
    
    final Map<int, int> frequency = {};
    for (var code in codes) {
      frequency[code] = (frequency[code] ?? 0) + 1;
    }
    
    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static String _getWeatherConditionFromCode(int weatherCode, String? precipitationType, double cloudCover) {
    // Open-Meteo WMO weather codes mapping
    // Enhanced with precipitation type and cloud cover for better accuracy
    switch (weatherCode) {
      case 0: return 'Clear'; // Clear sky
      case 1: return 'Mostly Clear'; // Mainly clear
      case 2: return 'Partly Cloudy'; // Partly cloudy
      case 3: return 'Cloudy'; // Overcast
      case 45: return 'Fog'; // Fog
      case 48: return 'Fog'; // Depositing rime fog
      case 51: return 'Drizzle'; // Drizzle: Light intensity
      case 53: return 'Drizzle'; // Drizzle: Moderate intensity
      case 55: return 'Drizzle'; // Drizzle: Dense intensity
      case 56: return 'Freezing Drizzle'; // Freezing Drizzle: Light intensity
      case 57: return 'Freezing Drizzle'; // Freezing Drizzle: Dense intensity
      case 61: return precipitationType ?? 'Rain'; // Rain: Slight intensity
      case 63: return precipitationType ?? 'Rain'; // Rain: Moderate intensity
      case 65: return precipitationType ?? 'Heavy Rain'; // Rain: Heavy intensity
      case 66: return 'Freezing Rain'; // Freezing Rain: Light intensity
      case 67: return 'Freezing Rain'; // Freezing Rain: Heavy intensity
      case 71: return 'Snow'; // Snow fall: Slight intensity
      case 73: return 'Snow'; // Snow fall: Moderate intensity
      case 75: return 'Heavy Snow'; // Snow fall: Heavy intensity
      case 77: return 'Snow'; // Snow grains
      case 80: return precipitationType ?? 'Rain'; // Rain showers: Slight intensity
      case 81: return precipitationType ?? 'Rain'; // Rain showers: Moderate intensity
      case 82: return precipitationType ?? 'Heavy Rain'; // Rain showers: Violent intensity
      case 85: return 'Snow'; // Snow showers: Slight intensity
      case 86: return 'Snow'; // Snow showers: Heavy intensity
      case 95: return 'Thunderstorm'; // Thunderstorm: Slight or moderate
      case 96: return 'Thunderstorm'; // Thunderstorm with slight hail
      case 99: return 'Thunderstorm'; // Thunderstorm with heavy hail
      default:
        // Default to Clear if cloud cover is low, otherwise Cloudy
        if (cloudCover > 50) {
          return 'Cloudy';
        }
        return 'Clear';
    }
  }

  static String _getWeatherIconFromCode(int weatherCode, String? precipitationType, double cloudCover) {
    // Map Open-Meteo WMO weather codes to OpenWeather-style icons for compatibility
    switch (weatherCode) {
      case 0: return '01d'; // Clear sky
      case 1: return '01d'; // Mainly clear
      case 2: return '02d'; // Partly cloudy
      case 3: return '04d'; // Overcast
      case 45: return '50d'; // Fog
      case 48: return '50d'; // Depositing rime fog
      case 51: return '09d'; // Drizzle: Light intensity
      case 53: return '09d'; // Drizzle: Moderate intensity
      case 55: return '09d'; // Drizzle: Dense intensity
      case 56: return '13d'; // Freezing Drizzle: Light intensity
      case 57: return '13d'; // Freezing Drizzle: Dense intensity
      case 61: return '10d'; // Rain: Slight intensity
      case 63: return '10d'; // Rain: Moderate intensity
      case 65: return '10d'; // Rain: Heavy intensity
      case 66: return '13d'; // Freezing Rain: Light intensity
      case 67: return '13d'; // Freezing Rain: Heavy intensity
      case 71: return '13d'; // Snow fall: Slight intensity
      case 73: return '13d'; // Snow fall: Moderate intensity
      case 75: return '13d'; // Snow fall: Heavy intensity
      case 77: return '13d'; // Snow grains
      case 80: return '09d'; // Rain showers: Slight intensity
      case 81: return '10d'; // Rain showers: Moderate intensity
      case 82: return '10d'; // Rain showers: Violent intensity
      case 85: return '13d'; // Snow showers: Slight intensity
      case 86: return '13d'; // Snow showers: Heavy intensity
      case 95: return '11d'; // Thunderstorm: Slight or moderate
      case 96: return '11d'; // Thunderstorm with slight hail
      case 99: return '11d'; // Thunderstorm with heavy hail
      default:
        // Default to clear or cloudy based on cloud cover
        if (cloudCover > 50) {
          return '04d'; // cloudy
        }
        return '01d'; // default to clear
    }
  }

  static List<WeatherForecast> _parseForecastData(Map<String, dynamic> data) {
    final List<WeatherForecast> forecasts = [];
    final List<dynamic> list = data['list'];
    
    // Group forecasts by date and get daily forecast
    final Map<String, Map<String, dynamic>> dailyData = {};
    
    for (var item in list) {
      final DateTime dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final String dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      
      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = {
          'temps': [],
          'conditions': [],
          'icons': [],
          'humidity': [],
          'windSpeed': [],
          'precipitation': 0,
          'dateTime': dt,
        };
      }
      
      dailyData[dateKey]!['temps'].add((item['main']['temp'] as num).toDouble());
      dailyData[dateKey]!['conditions'].add(item['weather'][0]['main']);
      dailyData[dateKey]!['icons'].add(item['weather'][0]['icon']);
      dailyData[dateKey]!['humidity'].add(item['main']['humidity']);
      dailyData[dateKey]!['windSpeed'].add((item['wind']['speed'] as num).toDouble());
      
      // Add precipitation if available
      if (item['rain'] != null) {
        dailyData[dateKey]!['precipitation'] += (item['rain']['3h'] ?? 0).toDouble();
      }
      if (item['snow'] != null) {
        dailyData[dateKey]!['precipitation'] += (item['snow']['3h'] ?? 0).toDouble();
      }
    }
    
    // Create WeatherForecast objects for the next 5 days
    final sortedDates = dailyData.keys.toList()..sort();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final DateTime now = DateTime.now();
    final String todayString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    for (int i = 0; i < sortedDates.length && i < 5; i++) {
      final dateKey = sortedDates[i];
      final dayData = dailyData[dateKey]!;
      final DateTime dateTime = dayData['dateTime'];
      
      final List<double> temps = List<double>.from(dayData['temps']);
      final List<String> conditions = List<String>.from(dayData['conditions']);
      final List<String> icons = List<String>.from(dayData['icons']);
      
      // Get most common condition
      final String mostCommonCondition = _getMostCommon(conditions);
      final String mostCommonIcon = _getMostCommon(icons);
      
      final double maxTemp = temps.reduce((a, b) => a > b ? a : b).toDouble();
      final double minTemp = temps.reduce((a, b) => a < b ? a : b).toDouble();
      final int avgHumidity = (dayData['humidity'].reduce((a, b) => a + b) / dayData['humidity'].length).round();
      final double maxWindSpeed = dayData['windSpeed'].reduce((a, b) => a > b ? a : b).toDouble();
      final int precipitation = (dayData['precipitation'] * 100).round().clamp(0, 100);
      
      // Check if this is today
      final bool isToday = dateKey == todayString;
      
      // Generate farmer-friendly descriptions
      final String weatherDescription = getFarmerFriendlyDescription(mostCommonCondition, maxTemp, precipitation, avgHumidity, null, 0.0);
      final String farmerAdvice = getFarmerAdvice(mostCommonCondition, maxTemp, precipitation, avgHumidity, isToday, null, 0.0);
      
      forecasts.add(WeatherForecast(
        date: dateKey,
        dayName: isToday ? 'Today' : dayNames[dateTime.weekday - 1],
        tempMax: maxTemp,
        tempMin: minTemp,
        condition: mostCommonCondition,
        icon: mostCommonIcon,
        humidity: avgHumidity,
        windSpeed: maxWindSpeed,
        precipitation: precipitation,
        isToday: isToday,
        farmerAdvice: farmerAdvice,
        weatherDescription: weatherDescription,
        pressure: 1013.25,
        rainAmount: 0.0,
        sunshineDuration: 0.0,
      ));
    }
    
    return forecasts;
  }

  static String _getMostCommon(List<String> list) {
    if (list.isEmpty) return '';
    
    final Map<String, int> frequency = {};
    for (var item in list) {
      frequency[item] = (frequency[item] ?? 0) + 1;
    }
    
    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static String? _getMostCommonString(List<String> list) {
    if (list.isEmpty) return null;
    
    final Map<String, int> frequency = {};
    for (var item in list) {
      frequency[item] = (frequency[item] ?? 0) + 1;
    }
    
    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  static String getFarmerFriendlyDescription(String condition, double tempMax, int precipitation, int humidity, String? precipitationType, double cloudCover) {
    switch (condition.toLowerCase()) {
      case 'clear':
        if (tempMax > 32) {
          return 'Mainit - Bantayan alon at salinity';
        } else if (tempMax >= 28) {
          return 'Marahang araw - Magandang sa fish cage';
        } else {
          return 'Malamig - Maayos para sa bangus';
        }
      case 'cloudy':
      case 'partly cloudy':
      case 'mostly cloudy':
        if (precipitation > 30) {
          return 'Maulap - Maaaring bumagal alon';
        } else {
          return 'Maulap - Proteksyon sa araw';
        }
      case 'rain':
        if (precipitation > 70) {
          return 'Malakas ulan - Bantayan alon sa dagat';
        } else {
          return 'Magaan ulan - Mabuti sa salinity';
        }
      case 'drizzle':
        return 'Mamasa-masa - Mabuti sa water quality';
      case 'thunderstorm':
        return 'Bagyo - I-secure ang fish pen';
      case 'mist':
      case 'fog':
        return 'Mabulok - Bantayan visibility sa dagat';
      default:
        // Use cloud cover and precipitation for default description
        if (cloudCover > 70) {
          return 'Maulap - Proteksyon sa araw';
        } else if (precipitation > 50) {
          return 'Maaaring umulan - Bantayan alon';
        } else {
          return 'Karaniwang panahon sa dagat';
        }
    }
  }

  static String getFarmerAdvice(String condition, double tempMax, int precipitation, int humidity, bool isToday, String? precipitationType, double cloudCover) {
    final String timeContext = isToday ? 'Ngayong araw' : 'Bukas';
    
    switch (condition.toLowerCase()) {
      case 'clear':
        if (tempMax > 32) {
          return '$timeContext, bantayan alon at salinity sa dagat. I-check ang fish cage mooring.';
        } else if (tempMax >= 28) {
          return '$timeContext, magandang panahon para sa pagpapakain. Normal sa dagat ang temperature.';
        } else {
          return '$timeContext, mabuti para sa paglaki ng bangus. Monitor ang water quality.';
        }
      case 'cloudy':
      case 'partly cloudy':
      case 'mostly cloudy':
        if (precipitation > 30) {
          return '$timeContext, i-check ang fish pen integrity. Maghanda sa malakas alon.';
        } else {
          return '$timeContext, magandang proteksyon sa araw. Mabuti para sa mga bangus.';
        }
      case 'rain':
        if (precipitation > 70) {
          return '$timeContext, bantayan alon at current. I-secure ang fish cage at nets.';
        } else {
          return '$timeContext, mabuti ang oxygen sa dagat. Maayos para sa feeding.';
        }
      case 'drizzle':
        return '$timeContext, mabuti ang water quality sa dagat. Maayos para sa pagpapakain.';
      case 'thunderstorm':
        return '$timeContext, i-check lahat ng mooring lines at nets. I-secure ang fish pen equipment.';
      case 'mist':
      case 'fog':
        return '$timeContext, bantayan visibility sa dagat. Mag-ingat sa paglalakbay sa fish pen.';
      default:
        // Use cloud cover and precipitation for default advice
        if (cloudCover > 70) {
          return '$timeContext, i-check ang fish pen integrity. Magandang proteksyon sa araw.';
        } else if (precipitation > 50) {
          return '$timeContext, bantayan alon at current. Maayos para sa feeding.';
        } else {
          return '$timeContext, regular na monitor ang water quality at alon sa dagat.';
        }
    }
  }

  // Debug method to test API connection
  static Future<bool> testApiConnection() async {
    try {
      // Test with Open-Meteo API (no API key required)
      final url = '$_baseUrl/forecast?latitude=14.5995&longitude=120.9842&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto';
      print('Testing Open-Meteo API connection to: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Open-Meteo API connection successful! Response keys: ${data.keys}');
        return true;
      } else {
        print('Open-Meteo API connection failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Open-Meteo API connection error: $e');
      return false;
    }
  }
}
