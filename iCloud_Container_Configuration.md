# Konfiguracja kontenera iCloud

## Problem
Błąd "Bad Container" oznacza, że kontener iCloud nie jest prawidłowo skonfigurowany w Apple Developer Portal.

## Kroki do naprawienia

### 1. **W Apple Developer Portal**
1. Zaloguj się do [Apple Developer Portal](https://developer.apple.com)
2. Przejdź do "Certificates, Identifiers & Profiles"
3. Wybierz "Identifiers" → "App IDs"
4. Znajdź swoją aplikację (io.productroot.assistant)
5. Włącz "iCloud" w capabilities
6. Wybierz "CloudKit" 
7. Kliknij "Configure" i utwórz kontener jeśli nie istnieje

### 2. **W Xcode**
1. Otwórz projekt w Xcode
2. Wybierz target "Foundation Lab"
3. Przejdź do zakładki "Signing & Capabilities"
4. Upewnij się, że:
   - Masz prawidłowy Team wybrany
   - Automatyczne zarządzanie podpisywaniem jest włączone
   - iCloud capability jest dodane
   - CloudKit jest zaznaczone
   - Kontener "iCloud.io.productroot.assistant" jest wybrany

### 3. **Alternatywne rozwiązanie - Domyślny kontener**
Jeśli nie możesz skonfigurować custom kontenera, możesz użyć domyślnego:

```swift
// W pliku iCloudService.swift, zmień linię 35 na:
container = CKContainer.default()
```

### 4. **Testowanie**
1. Uruchom aplikację na fizycznym urządzeniu (nie symulatorze)
2. Upewnij się, że jesteś zalogowany do iCloud w Ustawieniach
3. Włącz iCloud sync w aplikacji
4. Sprawdź logi w konsoli Xcode

## Możliwe błędy

### "Bad Container"
- Kontener nie jest skonfigurowany w Developer Portal
- Bundle ID nie pasuje do kontenera
- Brak uprawnień do kontenera

### "Account Not Available"
- Użytkownik nie jest zalogowany do iCloud
- iCloud Drive jest wyłączony
- Brak miejsca w iCloud

### "Network Unavailable"
- Brak połączenia z internetem
- Problemy z serwerami Apple

## Ważne
- CloudKit wymaga aktywnego konta Apple Developer
- Testowanie CloudKit wymaga fizycznego urządzenia
- Symulator iOS ma ograniczone wsparcie dla CloudKit