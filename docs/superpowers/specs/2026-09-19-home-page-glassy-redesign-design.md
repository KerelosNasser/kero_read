# Home Page Glassy Redesign Design Document

- **Date**: 2026-09-19
- **Status**: Approved by User
- **Target**: `c:\projects\Flutter\kero_read\lib\views\home_view.dart` and related home widgets

---

## 1. Objective

Completely redesign and rebuild the Home Page UI of `kero_read` with a modern, high-contrast, glassmorphic Bento Dashboard matching the aesthetic quality of the Reader view. Destroy outdated, muddy amber-brown styling and replace with Obsidian / Deep Midnight atmosphere, floating glass header, continue-reading hero card, quick action pills, interactive filter chips, grid/list view switcher, and polished glass book/folder cards.

---

## 2. Visual Foundation & Color System

- **Atmosphere**: Deep Midnight palette (`#0B0D13` to `#161922`) with subtle radial ambient glow (`#3B82F6` / `#6366F1` at ~8% opacity).
- **Glass Spec**:
  - Background: `Colors.white.withValues(alpha: 0.08)` to `0.03`.
  - Border: `Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0)`.
  - Blur: `16.0` Gaussian blur.
  - Drop Shadows: `BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: Offset(0, 8))`.
- **Typography**: High-contrast white (`Colors.white`, `Colors.white70`, `Colors.white38`).

---

## 3. Architecture & Components

### 3.1 Floating Header (`HomeAppBar`)
- Positioned floating pill matching `ReaderAppBar` style.
- Displays:
  - Left: Back button (if inside folder), app title / folder title.
  - Right: Expandable inline glass search bar trigger, theme indicator / library count badge.

### 3.2 Hero "Continue Reading" Card
- Displays most recently read book from `recentPdfs` where `lastReadPage > 0` (or most recently opened).
- Components:
  - Left: Stylized glass book icon / cover badge with circular reading progress indicator.
  - Middle: Book title (bold, 1-2 lines), reading progress (`Page X of Y` + percent bar).
  - Right: Quick "Resume" pill button directly opening `ReaderView`.
- Fallback state: When no books are in recent list, shows a welcome bento card with an "Import PDF" prompt.

### 3.3 Quick Actions Row
- Horizontal row of 3 glassy action pills:
  - **Import PDF**: Triggers `controller.importPdf()`.
  - **New Folder**: Triggers `HomeDialogs.showCreateFolderDialog()`.
  - **Scan Device**: Triggers `controller.scanDevicePdfs()`, showing subtle animation when scanning.

### 3.4 Library Navigation, Filters & View Toggle
- **Filter Chips Row**: Glass segmented selector with chips:
  - `All` (All imported books + folders)
  - `In Progress` (Books with progress > 0)
  - `Folders` (Only folders)
  - `Device Files` (Scanned device PDFs)
- **View Toggle**: Trailing button to switch between Grid view and List view (saved in controller).
- **Inline Search**: Filter query applied in real-time to active list/grid.

### 3.5 Book & Folder Items
- **Grid View (`PdfGridCard`)**:
  - 2-column masonry or fixed aspect ratio grid.
  - Cover preview header with stylized gradient + page badge.
  - Title, progress indicator line, options button (`...`).
- **List View (`PdfGlassTile`)**:
  - Sleek horizontal glass tile.
  - Book thumbnail with progress ring.
  - Title, parent directory / folder tag, last opened date/time.
  - Options button (`...`).
- **Folder Card / Chip (`FolderGlassCard`)**:
  - Uses `folder.colorValue`.
  - Folder icon, name, item count badge.
  - Tap opens folder; long press triggers options bottom sheet.

---

## 4. State & Controller Integration

- Update `HomeController`:
  - Add `searchQuery = ''.obs`.
  - Add `isSearchOpen = false.obs`.
  - Add `selectedFilter = HomeFilter.all.obs` (enum: `all`, `inProgress`, `folders`, `device`).
  - Add `isGridView = true.obs` (toggle between grid and list).
  - Computed getters for filtered lists:
    - `filteredItems`: applies active filter + search query.
    - `continueReadingPdf`: returns first PDF with reading progress or most recent.

---

## 5. Verification Plan

- Run `flutter analyze` or lint checks on all modified/new files.
- Verify smooth rendering in both Light and Dark themes.
- Test all interactions:
  - Import PDF via quick action.
  - Open folder and navigate back via header.
  - Toggle between Grid and List view.
  - Filter by `All`, `In Progress`, `Folders`, `Device Files`.
  - Search query filtering.
  - Tap "Resume" on Hero card to open reader.
