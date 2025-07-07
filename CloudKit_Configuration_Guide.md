# Konfiguracja CloudKit dla aplikacji

## Problem
CloudKit zwraca błąd "Field 'recordName' is not marked queryable", co oznacza że schemat danych nie jest skonfigurowany w CloudKit Dashboard.

## Rozwiązanie

### Opcja 1: Automatyczne tworzenie schematu (zalecane)
1. Najpierw zapisz dane do iCloud używając przycisku "Backup to iCloud" 
2. To automatycznie utworzy schemat w CloudKit
3. Dopiero potem próbuj przywracać dane

### Opcja 2: Ręczna konfiguracja w CloudKit Dashboard
1. Zaloguj się na https://developer.apple.com
2. Przejdź do CloudKit Dashboard
3. Wybierz kontener aplikacji
4. Przejdź do "Schema" → "Record Types"
5. Dla każdego typu (Area, Project, Task) dodaj indeksy:
   - Kliknij na typ rekordu
   - Przejdź do zakładki "Indexes"
   - Dodaj indeks dla pola "recordName" jako "Queryable"
   - Dodaj indeks "modifiedAt" jako "Sortable"

### Opcja 3: Lokalne obejście
Zaimplementowałem alternatywną metodę zapytań używając CKQueryOperation, która może pomóc obejść ten problem.

## Status
- ✅ Entitlements skonfigurowane poprawnie
- ✅ Używamy domyślnego kontenera CloudKit
- ✅ Implementacja zapisywania danych
- ⚠️  CloudKit schema wymaga utworzenia (automatycznie przy pierwszym zapisie)

## Kolejne kroki
1. Wyczyść i przebuduj aplikację
2. Zapisz dane do iCloud (to utworzy schemat)
3. Spróbuj przywrócić dane

## Debugowanie
W logach zobaczysz:
- "Using CloudKit container: iCloud.io.productroot.assistant" - to domyślny kontener
- "Schema doesn't exist yet - will be created on first save" - przy pierwszym uruchomieniu
- Po zapisaniu danych schemat zostanie utworzony automatycznie