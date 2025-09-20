import 'package:flutter/material.dart';
import 'package:raylytics/pages/login.dart';
import 'package:raylytics/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:excel/excel.dart' as ex; // Add this dependency for Excel functionality
import 'package:path_provider/path_provider.dart'; // Add this dependency
import 'package:share_plus/share_plus.dart'; // Add this dependency for sharing
import 'dart:io';
import 'package:intl/intl.dart'; // Add this dependency for date formatting
import 'package:permission_handler/permission_handler.dart'; // Add this dependency

// Enum to manage the state of the home screen's body
enum HomeState {
  idle,       // Initial state, no card shown
  prediction, // "Predict Current" was clicked
  forecast,   // "Forcast Predict" was clicked
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variable to control which card is visible
  HomeState _currentState = HomeState.idle;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- ADDED FOR LOCATION TOGGLE ---
  bool _useCurrentLocation = false;
  final _locationController = TextEditingController();
  final _solarNoctController = TextEditingController(); // Add controller for Solar NOCT
  // --- END OF ADDITION ---
  

  double? _latitude;
  double? _longitude;
  String? _address;
  String? _prediction;
  Map<String, dynamic>? _forecastData;
  bool _isLoading = false;
  bool _isDownloading = false; // Add this for download loading state

  // API Configuration - Replace with your actual API endpoints
  static const String BASE_API_URL = "http://192.168.152.203:8000";
  static const String PREDICTION_ENDPOINT = "/predict";
  static const String FORECAST_ENDPOINT = "/forecast15";

  // Method to get current date formatted
  String _getCurrentDateFormatted() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(now);
  }

  // Method to get coordinates from city name using geocoding
  Future<Map<String, double>?> _getCoordinatesFromCity(String cityName) async {
    try {
      List<Location> locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
    } catch (e) {
      print("Geocoding error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not find location: $cityName")),
      );
    }
    return null;
  }

  // Method to create and download Excel file
  Future<void> _downloadExcelFile() async {
    if (_forecastData == null || _forecastData!['forecast'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No forecast data available to download")),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required to download files")),
        );
        return;
      }

      // Create Excel workbook
      final excel = ex.Excel.createExcel();
      final sheet = excel['Solar Forecast'];
      
      // Clear default sheet if exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Add headers with styling
      sheet.cell(ex.CellIndex.indexByString("A1")).value =  ex.TextCellValue("Solar Power Forecast - 15 Days");
      sheet.merge(ex.CellIndex.indexByString("A1"), ex.CellIndex.indexByString("E1"));
      
      // Add metadata
      final currentDate = _getCurrentDateFormatted();
      sheet.cell(ex.CellIndex.indexByString("A2")).value = ex.TextCellValue("Generated on: $currentDate");
      sheet.cell(ex.CellIndex.indexByString("A3")).value = ex.TextCellValue("Location: ${_address ?? 'Unknown'}");
      if (_latitude != null && _longitude != null) {
        sheet.cell(ex.CellIndex.indexByString("A4")).value = 
          ex.TextCellValue("Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}");
      }
      sheet.cell(ex.CellIndex.indexByString("A5")).value = 
        ex.TextCellValue("Solar NOCT: ${_solarNoctController.text.trim()}");

      // Add table headers
      int headerRow = 7;
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow)).value = 
        ex.TextCellValue("Date");
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow)).value = 
        ex.TextCellValue("Day of Week");
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: headerRow)).value = 
        ex.TextCellValue("Temperature (°C)");
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow)).value = 
        ex.TextCellValue("Humidity (%)");
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow)).value = 
        ex.TextCellValue("Predicted Power (kWh)");
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: headerRow)).value = 
        ex.TextCellValue("Confidence");

      // Add forecast data
      final List<dynamic> forecastList = _forecastData!['forecast'];
      for (int i = 0; i < forecastList.length; i++) {
        final forecast = forecastList[i];
        int dataRow = headerRow + 1 + i;
        
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: dataRow)).value = 
          ex.TextCellValue(forecast['date'] ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dataRow)).value = 
          ex.TextCellValue(forecast['day_of_week'] ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: dataRow)).value = 
          ex.TextCellValue(forecast['temperature'] ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: dataRow)).value = 
          ex.TextCellValue(forecast['humidity'] ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: dataRow)).value = 
          ex.TextCellValue(forecast['predicted_power'] ?? '');
        sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: dataRow)).value = 
          ex.TextCellValue(forecast['confidence'] ?? '');
      }

      // Get the directory to save the file
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not access storage directory");
      }

      // Create filename with current date
      final fileName = 'Forecast_${DateFormat('ddMMMyyyy').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      // Save the Excel file
      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        // Show success message and option to share
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Excel file saved: $fileName"),
            action: SnackBarAction(
              label: "Share",
              onPressed: () => _shareExcelFile(filePath),
            ),
          ),
        );
      } else {
        throw Exception("Failed to generate Excel file");
      }
    } catch (e) {
      print("Excel download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to download Excel file: $e")),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  // Method to share the Excel file
  Future<void> _shareExcelFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Solar Power Forecast - 15 Days',
        subject: 'Solar Power Forecast Data',
      );
    } catch (e) {
      print("Share error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to share file: $e")),
      );
    }
  }

  // Method to make API call for current prediction
  Future<void> _fetchCurrentPrediction() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a valid location")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final solarNoct = _solarNoctController.text.trim();
      if (solarNoct.isEmpty) {
        throw Exception("Please enter Solar NOCT value");
      }
      
      final url = Uri.parse(
          "$BASE_API_URL$PREDICTION_ENDPOINT?lat=$_latitude&lon=$_longitude&solar_noct=$solarNoct&city=${Uri.encodeComponent(_address ?? 'Unknown')}"
      );
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Add any required API keys or authentication headers here
          // 'Authorization': 'Bearer your_api_key',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _prediction = data["predicted_solar_output"]?.toString() ?? "No prediction available";
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Prediction fetched successfully!")),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception("API Error: ${errorData['error'] ?? response.statusCode}");
      }
    } catch (e) {
      print("Prediction API error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch prediction: $e")),
      );
      setState(() {
        _prediction = "Failed to fetch prediction";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to make API call for forecast
  Future<void> _fetchForecast() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a valid location")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final solarNoct = _solarNoctController.text.trim();
      if (solarNoct.isEmpty) {
        throw Exception("Please enter Solar NOCT value");
      }
      
      final requestBody = {
        'latitude': _latitude,
        'longitude': _longitude,
        'city': _address ?? 'Unknown',
        'solar_noct': double.parse(solarNoct),
      };
      
      final url = Uri.parse("$BASE_API_URL$FORECAST_ENDPOINT");
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _forecastData = data;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Forecast fetched successfully!")),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception("API Error: ${errorData['error'] ?? response.statusCode}");
      }
    } catch (e) {
      print("Forecast API error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch forecast: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to handle location setup (either current or manual)
  Future<void> _setupLocation() async {
    if (_useCurrentLocation) {
      // Use current location
      try {
        final position = await LocationService.getCurrentPosition();
        final address = await LocationService.getAddressFromLatLng(position);
        
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _address = address;
          _locationController.text = address;
        });
      } catch (e) {
        print("Error fetching current location: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to get current location: $e")),
        );
      }
    } else {
      // Use manual city input
      final cityName = _locationController.text.trim();
      if (cityName.isNotEmpty) {
        final coordinates = await _getCoordinatesFromCity(cityName);
        if (coordinates != null) {
          setState(() {
            _latitude = coordinates['latitude'];
            _longitude = coordinates['longitude'];
            _address = cityName;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a city name")),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _solarNoctController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // The menu icon that opens the drawer
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
      ),
      // The Sidebar
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLocationInput(),
                const SizedBox(height: 16),
                _buildTextField(
                  hint: 'Solar NOCT (Watts)',
                  controller: _solarNoctController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                _buildButtonRow(),
                const SizedBox(height: 48),
                // This widget shows the correct content based on the button clicked
                _buildConditionalContent(),
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading || _isDownloading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isDownloading ? 'Generating Excel file...' : 'Loading...',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _locationController,
            enabled: !_useCurrentLocation,
            decoration: InputDecoration(
              hintText: 'City Location / Name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: _useCurrentLocation,
          onChanged: (bool value) async {
            setState(() {
              _useCurrentLocation = value;
            });

            if (_useCurrentLocation) {
              await _setupLocation();
            } else {
              _locationController.clear();
              setState(() {
                _latitude = null;
                _longitude = null;
                _address = null;
              });
            }
          },
          activeThumbColor: const Color(0xFF6A359C),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String hint, 
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildButtonRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await _setupLocation();
              if (_latitude != null && _longitude != null) {
                setState(() => _currentState = HomeState.prediction);
                await _fetchCurrentPrediction();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Predict Current'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await _setupLocation();
              if (_latitude != null && _longitude != null) {
                setState(() => _currentState = HomeState.forecast);
                await _fetchForecast();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Forcast Predict'),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionalContent() {
    switch (_currentState) {
      case HomeState.prediction:
        return _buildPredictionCard();
      case HomeState.forecast:
        return _buildForecastCard();
      case HomeState.idle:
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPredictionCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solar Power\nPrediction : ${_getCurrentDateFormatted()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Solar Power: ${_prediction ?? "Loading..."}', 
            style: const TextStyle(fontSize: 14)
          ),
          Text(
            'Location: ${_address ?? "Unknown"}', 
            style: const TextStyle(fontSize: 14)
          ),
          if (_latitude != null && _longitude != null)
            Text(
              'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                if (_prediction != null) {
                  final shareText = 'Solar Power Prediction for ${_getCurrentDateFormatted()}\n'
                      'Location: ${_address ?? "Unknown"}\n'
                      'Solar Power: $_prediction\n'
                      'Generated by Raylytics App';
                  Share.share(shareText);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard() {
    final fileName = 'Forecast_${DateFormat('ddMMMyyyy').format(DateTime.now())}.xlsx';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Download', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                fileName, 
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: _isDownloading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_for_offline_outlined),
                  onPressed: _isDownloading ? null : _downloadExcelFile,
                ),
                IconButton(
                  icon: const Icon(Icons.share), 
                  onPressed: () {
                    if (_forecastData != null) {
                      final shareText = '15-Day Solar Power Forecast\n'
                          'Location: ${_address ?? "Unknown"}\n'
                          'Generated on: ${_getCurrentDateFormatted()}\n'
                          'Generated by Raylytics App';
                      Share.share(shareText);
                    }
                  }
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 24),
        const Text('15 Day Forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              columns: const <DataColumn>[
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Temp', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Humidity', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Power', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _buildForecastRows(),
            ),
          ),
        ),
      ],
    );
  }

  List<DataRow> _buildForecastRows() {
    if (_forecastData != null && _forecastData!['forecast'] != null) {
      // Use actual API data
      final List<dynamic> forecastList = _forecastData!['forecast'];
      return forecastList.map<DataRow>((forecast) {
        return DataRow(
          cells: <DataCell>[
            DataCell(Text(forecast['date'] ?? '')),
            DataCell(Text(forecast['day_of_week'] ?? '')),
            DataCell(Text(forecast['temperature'] ?? '')),
            DataCell(Text(forecast['humidity'] ?? '')),
            DataCell(Text(forecast['predicted_power'] ?? '')),
          ],
        );
      }).toList();
    } else {
      // Use sample data as fallback
      return List<DataRow>.generate(
        15,
        (int index) {
          final date = DateTime.now().add(Duration(days: index + 1));
          final temp = 23 + (index % 5);
          final humidity = 60 + (index % 20);
          final power = 240 + (index * 2);
          return DataRow(
            cells: <DataCell>[
              DataCell(Text(DateFormat('dd/MM').format(date))),
              DataCell(Text(DateFormat('EEE').format(date))),
              DataCell(Text('$temp°C')),
              DataCell(Text('$humidity%')),
              DataCell(Text('$power kWh')),
            ],
          );
        },
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF6A359C),
                    Color(0xFFF85F43),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'RAYLYTICS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAE2F3),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _buildDrawerItem(icon: Icons.person_outline, text: 'Username', onTap: () {}),
            ),
          ),
          _buildDrawerItem(icon: Icons.info_outline, text: 'About', onTap: () {}),
          _buildDrawerItem(icon: Icons.description_outlined, text: 'Report', onTap: () {}),
          _buildDrawerItem(icon: Icons.logout, text: 'Sign Out', onTap: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(text, style: const TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }
}