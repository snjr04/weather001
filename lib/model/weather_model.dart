class WeatherModel {
  final String city;
  final String description;
  final double temp;

  WeatherModel({
    required this.city,
    required this.description,
    required this.temp,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['name'] ?? '',
      description: json['weather'][0]['description'] ?? '',
      temp: (json['main']['temp'] as num).toDouble(),
    );
  }
}
