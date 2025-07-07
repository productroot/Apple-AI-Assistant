# Naprawienie problemu z nieskończoną synchronizacją iCloud

## Wprowadzone zmiany:

### 1. **Dodanie mechanizmu debounce**
- Synchronizacja jest opóźniona o 2 sekundy po ostatniej zmianie
- Zapobiega to wielokrotnym synchronizacjom przy szybkich zmianach

### 2. **Flaga `isUpdatingFromSync`**
- Zapobiega cyklicznym aktualizacjom
- Gdy dane są ładowane z iCloud, lokalne zapisy nie wywołują ponownej synchronizacji

### 3. **Ochrona przed wielokrotną synchronizacją**
- Guard w `saveTasks` zapobiega uruchomieniu synchronizacji, gdy jedna już trwa
- Rzuca błąd `syncInProgress` zamiast kolejkować synchronizacje

### 4. **Limit iteracji w zapytaniach**
- Maksymalnie 10 iteracji w `performQuery`
- Zapobiega nieskończonym pętlom przy dużej ilości danych

### 5. **Poprawiony Toggle w Settings**
- Synchronizacja uruchamia się tylko przy włączeniu (nie przy każdej zmianie)
- Usunięty `onChange` który mógł powodować wielokrotne wywołania

## Jak to teraz działa:

1. **Dodanie zadania**:
   - Zadanie jest zapisywane lokalnie natychmiast
   - Synchronizacja z iCloud jest zaplanowana za 2 sekundy
   - Jeśli dodasz kolejne zadanie w tym czasie, timer jest resetowany

2. **Synchronizacja**:
   - Tylko jedna synchronizacja może działać jednocześnie
   - Dane z iCloud nie wywołują ponownej synchronizacji (flaga `isUpdatingFromSync`)
   - Status synchronizacji jest prawidłowo aktualizowany

3. **Obsługa błędów**:
   - Timeout dla zapytań CloudKit
   - Graceful degradation do lokalnego storage przy błędach

## Testowanie:

1. Dodaj zadanie i sprawdź, czy synchronizacja kończy się po kilku sekundach
2. Dodaj kilka zadań szybko po sobie - powinna być tylko jedna synchronizacja
3. Wyłącz i włącz iCloud sync - dane powinny się zsynchronizować raz

Problem z nieskończącą się synchronizacją powinien być rozwiązany.