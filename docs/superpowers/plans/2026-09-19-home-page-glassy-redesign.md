# Home Page Glassy Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completely rebuild the Home Page UI of `kero_read` with a modern, high-contrast, glassmorphic Bento Dashboard matching the aesthetic quality of the Reader view.

**Architecture:** MVC using GetX controllers and Hive storage. The new Home view features a floating glassy app bar, a hero "Continue Reading" bento card, quick action pills, an interactive filter chips row with grid/list switcher, and glassy book/folder cards on a Deep Midnight gradient backdrop.

**Tech Stack:** Flutter 3.x, Dart 3.12+, GetX (`get`), `glassmorphism`, `hive`, `pdfrx`.

---

### Task 1: Update Color Tokens for Deep Midnight Atmosphere

**Files:**
- Modify: `lib/theme/color_tokens.dart:22-28`

- [ ] **Step 1: Update `homeGradient` and add midnight tokens**

Update `AppColors` in `lib/theme/color_tokens.dart`:
```dart
  /// Home background gradient (Deep Midnight slate -> rich obsidian).
  static const LinearGradient homeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D0F18),
      Color(0xFF131622),
      Color(0xFF090A10),
    ],
  );

  static const Color midnightAura = Color(0xFF3B82F6);
```

- [ ] **Step 2: Verify `color_tokens.dart` compiles cleanly**
Run: `flutter analyze lib/theme/color_tokens.dart`
Expected: PASS with no errors.

---

### Task 2: Extend `HomeController` State and Computed Filters

**Files:**
- Modify: `lib/controllers/home_controller.dart`

- [ ] **Step 1: Add filter enum, observables, and computed getters**

Add to `HomeController`:
```dart
enum HomeFilter { all, inProgress, folders, device }

// In HomeController:
var selectedFilter = HomeFilter.all.obs;
var isGridView = true.obs;
var searchQuery = ''.obs;
var isSearchOpen = false.obs;

void toggleViewMode() => isGridView.toggle();
void toggleSearch() {
  isSearchOpen.toggle();
  if (!isSearchOpen.value) searchQuery.value = '';
}
void setFilter(HomeFilter filter) => selectedFilter.value = filter;

PdfModel? get continueReadingPdf {
  final list = _storage.pdfBox.values.toList();
  if (list.isEmpty) return null;
  list.sort((a, b) => b.timeAdded.compareTo(a.timeAdded));
  final inProgress = list.where((p) => p.lastReadPage > 1).toList();
  return inProgress.isNotEmpty ? inProgress.first : list.first;
}
```

- [ ] **Step 2: Add getters for filtered folders, PDFs, and device PDFs**
Filter lists according to `searchQuery` and `selectedFilter`.

- [ ] **Step 3: Verify `home_controller.dart` with `flutter analyze`**
Run: `flutter analyze lib/controllers/home_controller.dart`
Expected: PASS with no errors.

---

### Task 3: Create Floating `HomeAppBar` Widget

**Files:**
- Create: `lib/views/widgets/home/home_app_bar.dart`

- [ ] **Step 1: Implement `HomeAppBar` using `GlassyContainer`**
Features:
- Positioned floating pill matching `ReaderAppBar` (height 60, rounded 28).
- Left: Back button (if inside folder) + dynamic folder/app title ("Kero Read" / folder name).
- Right: Search icon/expanded search TextField + item count badge.

- [ ] **Step 2: Verify `home_app_bar.dart` compiles cleanly**
Run: `flutter analyze lib/views/widgets/home/home_app_bar.dart`
Expected: PASS with no errors.

---

### Task 4: Create `HeroContinueReadingCard` Widget

**Files:**
- Create: `lib/views/widgets/home/hero_continue_reading_card.dart`

- [ ] **Step 1: Implement `HeroContinueReadingCard`**
Features:
- Reads `controller.continueReadingPdf`.
- If PDF exists: shows book title, reading progress bar, `Page X of Y`, and "Resume" button opening `ReaderView`.
- If no PDF: shows sleek glass welcome card with "Import your first PDF" call to action.

- [ ] **Step 2: Verify with `flutter analyze`**
Run: `flutter analyze lib/views/widgets/home/hero_continue_reading_card.dart`
Expected: PASS with no errors.

---

### Task 5: Create `HomeControls` (Quick Actions & Filter Chips)

**Files:**
- Create: `lib/views/widgets/home/home_controls.dart`

- [ ] **Step 1: Implement Quick Actions Row**
- Three glass action buttons: `Import PDF`, `New Folder`, `Scan Device`.

- [ ] **Step 2: Implement Filter Chips and View Toggle**
- Horizontal filter chips: `All`, `In Progress`, `Folders`, `Device Files`.
- Trailing Grid / List toggle button.

- [ ] **Step 3: Verify with `flutter analyze`**
Run: `flutter analyze lib/views/widgets/home/home_controls.dart`
Expected: PASS with no errors.

---

### Task 6: Create `PdfGridCard`, `FolderGlassCard`, and Polish `PdfListTile`

**Files:**
- Create: `lib/views/widgets/home/pdf_grid_card.dart`
- Create: `lib/views/widgets/home/folder_glass_card.dart`
- Modify: `lib/views/widgets/home/pdf_list_tile.dart`

- [ ] **Step 1: Implement `PdfGridCard`**
- 2-column glassy card with cover header, title, progress bar, more options.

- [ ] **Step 2: Implement `FolderGlassCard`**
- Glassy folder card tinted with `folder.colorValue`, item count badge, navigation.

- [ ] **Step 3: Polish `PdfListTile`**
- Sleek horizontal glass tile with book thumbnail, reading progress badge, more options.

- [ ] **Step 4: Verify with `flutter analyze`**
Run: `flutter analyze lib/views/widgets/home/`
Expected: PASS with no errors.

---

### Task 7: Rebuild `HomeView` with Unified Bento Layout

**Files:**
- Modify: `lib/views/home_view.dart`

- [ ] **Step 1: Reconstruct `HomeView`**
- Remove old TabBar, old `MiniDashboard`, and old Scaffold layout.
- Use Stack with Deep Midnight background and floating `HomeAppBar`.
- Scrollable body with `HeroContinueReadingCard`, `HomeControls`, and dynamic Grid/List of items.

- [ ] **Step 2: Verify with `flutter analyze`**
Run: `flutter analyze lib/views/home_view.dart`
Expected: PASS with no errors.

---

### Task 8: Full Project Analysis and Verification

- [ ] **Step 1: Run `flutter analyze` across entire project**
Run: `flutter analyze`
Expected: 0 errors.
