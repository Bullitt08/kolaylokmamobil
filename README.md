# Kolaylokma Mobil Uygulama

Kolaylokma, restoran yönetimi ve kullanıcı etkileşimi için geliştirilmiş bir mobil uygulamadır.

## Gereksinimler

Projeyi çalıştırmak için aşağıdaki yazılımların yüklü olması gerekmektedir:

- Flutter SDK (3.0.0 veya üzeri)
- Dart SDK (3.0.0 veya üzeri)
- Android Studio veya VS Code
- Git
- Android Emulator veya fiziksel Android cihaz
- iOS için: MacOS ve Xcode (iOS geliştirmesi yapılacaksa)

## Kurulum Adımları

1. Flutter'ı kurun:
   - [Flutter'ın resmi sitesinden](https://flutter.dev/docs/get-started/install) işletim sisteminize uygun Flutter SDK'yı indirin
   - İndirdiğiniz dosyayı çıkarın ve PATH'e ekleyin
   - Terminal veya Command Prompt'ta kontrol edin:
   ```bash
   flutter doctor
   ```

2. Projeyi bilgisayarınıza indirin:
   ```bash
   git clone [proje_repository_linki]
   cd kolaylokmamobil
   ```

3. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```

4. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## VS Code ile Çalıştırma

1. VS Code'u açın
2. Flutter ve Dart eklentilerini yükleyin:
   - View -> Command Palette (Ctrl+Shift+P)
   - "Flutter: Install Extensions" yazın ve Enter'a basın
3. Projeyi VS Code'da açın:
   - File -> Open Folder
   - İndirdiğiniz proje klasörünü seçin
4. Emülatör veya cihaz seçin:
   - VS Code'un alt çubuğunda "No Device" yazısına tıklayın
   - Listeden bir emülatör veya bağlı cihaz seçin
5. Projeyi çalıştırın:
   - F5 tuşuna basın veya
   - Run -> Start Debugging seçin

## Android Studio ile Çalıştırma

1. Android Studio'yu açın
2. Flutter ve Dart pluginlerini yükleyin:
   - File -> Settings -> Plugins
   - "Flutter" ve "Dart" pluginlerini aratıp yükleyin
3. Projeyi Android Studio'da açın:
   - File -> Open
   - İndirdiğiniz proje klasörünü seçin
4. Emülatör veya cihaz seçin:
   - Tools -> Device Manager
   - Create Virtual Device veya bağlı cihazı seçin
5. Projeyi çalıştırın:
   - Run butonuna tıklayın veya
   - Shift + F10 tuşlarına basın

## Sorun Giderme

1. "Flutter command not found" hatası:
   - Flutter'ın PATH'e eklendiğinden emin olun
   - Terminal/CMD'yi yeniden başlatın

2. Paket hataları için:
   ```bash
   flutter clean
   flutter pub get
   ```

3. Build hataları için:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Özellikler

- Kullanıcı kaydı ve girişi
- Restoran yönetimi
- Menü yönetimi
- Sipariş takibi
- Konum bazlı restoran listeleme
- Bildirim gönderme
- Profil yönetimi
