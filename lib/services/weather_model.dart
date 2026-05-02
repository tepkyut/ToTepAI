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
  });

  @override
  String toString() {
    return 'WeatherForecast(date: $date, dayName: $dayName, tempMax: $tempMax, tempMin: $tempMin, condition: $condition, icon: $icon, humidity: $humidity, windSpeed: $windSpeed, precipitation: $precipitation, isToday: $isToday, farmerAdvice: $farmerAdvice, weatherDescription: $weatherDescription)';
  }
}
