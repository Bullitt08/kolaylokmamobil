import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_page.dart';
import 'screens/search_page.dart';
import 'screens/profile_page.dart';
import 'services/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'screens/filtered_results_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://zxixknpruagqlvxkbhkv.supabase.co', // Supabase proje URL'niz
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp4aXhrbnBydWFncWx2eGtiaGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYxOTYyOTUsImV4cCI6MjA1MTc3MjI5NX0.8VgXdWPXLEpyMNuoZw24U62TEPnTFM3JC56oOq4LWeI', // Supabase proje API Key'iniz
    );
    debugPrint('Supabase başarıyla başlatıldı');
  } catch (e) {
    debugPrint('Supabase başlatma hatası: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kolaylokma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF8A0C27),
      ),
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _isLoading = true;
  String _loadingMessage = 'Uygulama başlatılıyor...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _loadingMessage = 'Konum servisleri kontrol ediliyor...');

      // Konum servislerinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loadingMessage = 'Lütfen konum servislerini açın');
        return;
      }

      // Konum izinlerini kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _loadingMessage = 'Konum izni isteniyor...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loadingMessage = 'Konum izni reddedildi');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _loadingMessage =
            'Konum izinleri kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.');
        return;
      }

      // Tüm kontroller başarılı, ana ekrana geç
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Başlatma hatası: $e');
      setState(() {
        _loadingMessage = 'Bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _loadingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  bool _shouldShowFilterOnLoad = false;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  void _showFilterDialog() {
    double _maxDistance = 10.0;
    RangeValues _priceRange = const RangeValues(0, 1000);
    double _minRating = 0.0;
    bool _onlyOpen = false;
    List<String> _selectedCategories = [];
    String _menuSearch = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF8A0C27), width: 2.0),
                borderRadius: BorderRadius.circular(8.0),
              ),
              backgroundColor: const Color(0xFFEDEFE8),
              title: Center(
                child: Text(
                  'Filtreler',
                  style: TextStyle(
                    color: Color(0xFF8A0C27),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menü İçeriği Arama
                    const Text('Menü İçeriği Ara',
                        style: TextStyle(
                            color: Color(0xFF8A0C27),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Örn: Adana kebap, pide, lahmacun...',
                        prefixIcon:
                            Icon(Icons.search, color: Color(0xFF8A0C27)),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF8A0C27)),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _menuSearch = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Mesafe Filtresi
                    const Text('Maksimum Mesafe (km)',
                        style: TextStyle(
                            color: Color(0xFF8A0C27),
                            fontWeight: FontWeight.bold)),
                    Slider(
                      activeColor: const Color(0xFF8A0C27),
                      value: _maxDistance,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${_maxDistance.round()} km',
                      onChanged: (value) {
                        setState(() => _maxDistance = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Fiyat Aralığı Filtresi
                    const Text('Menü Fiyat Aralığı (₺)',
                        style: TextStyle(
                            color: Color(0xFF8A0C27),
                            fontWeight: FontWeight.bold)),
                    RangeSlider(
                      activeColor: const Color(0xFF8A0C27),
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      labels: RangeLabels(
                        '₺${_priceRange.start.round()}',
                        '₺${_priceRange.end.round()}',
                      ),
                      onChanged: (values) {
                        setState(() => _priceRange = values);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Minimum Değerlendirme Filtresi
                    const Text('Minimum Değerlendirme',
                        style: TextStyle(
                            color: Color(0xFF8A0C27),
                            fontWeight: FontWeight.bold)),
                    Slider(
                      activeColor: const Color(0xFF8A0C27),
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _minRating.toString(),
                      onChanged: (value) {
                        setState(() => _minRating = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Sadece Açık Restoranlar
                    SwitchListTile(
                      activeColor: const Color(0xFF8A0C27),
                      title: const Text('Sadece Açık Restoranlar',
                          style: TextStyle(
                              color: Color(0xFF8A0C27),
                              fontWeight: FontWeight.bold)),
                      value: _onlyOpen,
                      onChanged: (value) {
                        setState(() => _onlyOpen = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Kategori Filtresi
                    const Text('Kategoriler',
                        style: TextStyle(
                            color: Color(0xFF8A0C27),
                            fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        FilterChip(
                          label: Text(
                            'Kebap',
                            style: TextStyle(
                              color: _selectedCategories.contains('Kebap')
                                  ? const Color(0xFFEDEFE8)
                                  : const Color(0xFF8A0C27),
                            ),
                          ),
                          selectedColor: const Color(0xFF8A0C27),
                          selected: _selectedCategories.contains('Kebap'),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add('Kebap');
                              } else {
                                _selectedCategories.remove('Kebap');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(
                            'Pide',
                            style: TextStyle(
                              color: _selectedCategories.contains('Pide')
                                  ? const Color(0xFFEDEFE8)
                                  : const Color(0xFF8A0C27),
                            ),
                          ),
                          selectedColor: const Color(0xFF8A0C27),
                          selected: _selectedCategories.contains('Pide'),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add('Pide');
                              } else {
                                _selectedCategories.remove('Pide');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(
                            'Döner',
                            style: TextStyle(
                              color: _selectedCategories.contains('Döner')
                                  ? const Color(0xFFEDEFE8)
                                  : const Color(0xFF8A0C27),
                            ),
                          ),
                          selectedColor: const Color(0xFF8A0C27),
                          selected: _selectedCategories.contains('Döner'),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add('Döner');
                              } else {
                                _selectedCategories.remove('Döner');
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: Text(
                            'Lahmacun',
                            style: TextStyle(
                              color: _selectedCategories.contains('Lahmacun')
                                  ? const Color(0xFFEDEFE8)
                                  : const Color(0xFF8A0C27),
                            ),
                          ),
                          selectedColor: const Color(0xFF8A0C27),
                          selected: _selectedCategories.contains('Lahmacun'),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add('Lahmacun');
                              } else {
                                _selectedCategories.remove('Lahmacun');
                              }
                              ;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal',
                      style: TextStyle(
                          color: Color(0xFF8A0C27),
                          fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(const Color(0xFF8A0C27)),
                  ),
                  onPressed: () {
                    final filters = {
                      'maxDistance': _maxDistance,
                      'priceRange': _priceRange,
                      'minRating': _minRating,
                      'onlyOpen': _onlyOpen,
                      'categories': _selectedCategories,
                      'menuSearch': _menuSearch,
                    };
                    Navigator.pop(context, filters);
                  },
                  child: const Text(
                    'Uygula',
                    style: TextStyle(
                      color: Color(0xFFEDEFE8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((filters) {
      if (filters != null && _homePageKey.currentState != null) {
        _homePageKey.currentState!.applyFiltersAndShowResults(filters).then(
          (filteredRestaurants) {
            if (mounted && filteredRestaurants != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FilteredResultsPage(
                    filteredRestaurants: filteredRestaurants,
                    filters: filters,
                  ),
                ),
              );
            }
          },
        );
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      if (_selectedIndex != 0) {
        _shouldShowFilterOnLoad = true;
        setState(() => _selectedIndex = 0);
      } else {
        _showFilterDialog();
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      _authService.isLoggedIn().then((isLoggedIn) {
        if (!isLoggedIn) {
          setState(() {
            _selectedIndex = index;
          });
        }
      });
    }
  }

  Widget _getPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(
          key: _homePageKey,
          onLocationReady: _shouldShowFilterOnLoad
              ? () {
                  _shouldShowFilterOnLoad = false;
                  _showFilterDialog();
                }
              : null,
        );
      case 2:
        return const SearchPage();
      case 3:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'web/icons/logo.png',
          height: 40,
        ),
        backgroundColor: Color(0xFFEDEFE8),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF8A0C27)),
            onPressed: () {
              // TODO: Bildirimler sayfasına yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bildirimler yakında eklenecek')),
              );
            },
          ),
        ],
      ),
      body: _getPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Filtre',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Arama',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hesabım',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF8A0C27),
        backgroundColor: Color(0xFFEDEFE8),
      ),
    );
  }
}
