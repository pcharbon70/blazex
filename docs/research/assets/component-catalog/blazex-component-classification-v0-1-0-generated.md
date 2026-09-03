---
title: "BlazeX component classification v0.1.0"
kind: note
created: "2026-09-03"
maturity: stable
tags:
  - bh-00
  - component-catalog
  - generated
  - product-classification
aliases:
  - "BlazeX generated component classification"
---

# BlazeX component classification v0.1.0

> Generated deterministically from the locked Phase 3 source catalog and canonical Phase 4 classification. Do not edit by hand.

## Classification identity

| Field | Value |
| --- | --- |
| Classification ID | `BX-CLASSIFICATION-BROWSER-FOUNDATION` |
| Classification/schema version | `0.1.0` / `1.0.0` |
| Stage / status | `complete` / `locked` |
| Source catalog | `assets/component-catalog/blazex-component-catalog-v0.1.0.json` |
| Source catalog SHA-256 | `ec0f413c9968b92878e71c1aae9570286dd68ec538938ad880d8908cf7ea70a3` |
| Families / exceptions | 83 / 12 |

## Summary

| Dimension | Counts |
| --- | --- |
| Disposition | `adapt-concept` 28, `build-natively` 43, `renderer-specific-extension` 1, `replace-with-platform-pattern` 11 |
| Delivery tier | `F0` 13, `F1` 26, `F2` 21, `F3` 18, `F4` 5 |
| Package | `blazex_charts` 1, `blazex_data` 6, `blazex_forms` 18, `blazex_surfaces` 9, `blazex_ui` 47, `blazex_ui_tree` 2 |
| Remote authority | `local-only` 73, `optional-remote` 7, `phoenix-enhanced` 3 |
| Primary fallback | `alternative-interaction` 30, `explicit-unavailable` 2, `in-app-substitute` 14, `nonvisual-representation` 1, `omission` 1, `server-round-trip` 5, `static-content` 30 |
| Portability | `custom-scene` 1, `portable-semantic` 24, `portable-with-capabilities` 57, `renderer-extension` 1 |
| Native strategy | `custom-drawn` 2, `native-composite` 58, `native-preferred` 15, `not-applicable` 8 |
| Required capability references | `BX-CAP-ACCESSIBILITY` 83, `BX-CAP-FILES` 1, `BX-CAP-FOCUS` 40, `BX-CAP-KEYBOARD` 48, `BX-CAP-MEASUREMENT` 12, `BX-CAP-POINTER` 3, `BX-CAP-SURFACE` 14, `BX-CAP-WINDOW` 3 |
| Optional capability references | `BX-CAP-CLIPBOARD` 6, `BX-CAP-MEASUREMENT` 4, `BX-CAP-NETWORK` 10, `BX-CAP-NOTIFICATIONS` 1, `BX-CAP-POINTER` 45, `BX-CAP-STORAGE` 1, `BX-CAP-SYSTEM-THEME` 1, `BX-CAP-TIME` 5, `BX-CAP-WINDOW` 4 |

## Families

| Stable ID | Source family | Disposition | Tier | Package | Prerequisites | Required / optional capabilities | Remote | Fallback | Portability | Native strategy | Classification / implementation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `BX-FAM-ALERT` | `Alert` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-APP-BAR` | `AppBar` | `build-natively` | `F1` | `blazex_ui` | `BX-FAM-TOOL-BAR` | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-AUTOCOMPLETE` | `Autocomplete` | `adapt-concept` | `F2` | `blazex_forms` | `BX-FAM-FIELD`, `BX-FAM-POPOVER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-SURFACE`<br>O: `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `optional-remote` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-AVATAR` | `Avatar` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-BADGE` | `Badge` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-BREADCRUMBS` | `Breadcrumbs` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-BREAKPOINT-PROVIDER` | `BreakpointProvider` | `replace-with-platform-pattern` | `F0` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-MEASUREMENT`<br>O: `BX-CAP-WINDOW` | `local-only` | `static-content` | `portable-with-capabilities` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-BUTTON` | `Button` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-BUTTON-GROUP` | `ButtonGroup` | `build-natively` | `F1` | `blazex_ui` | `BX-FAM-BUTTON` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-CARD` | `Card` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-CAROUSEL` | `Carousel` | `adapt-concept` | `F3` | `blazex_ui` | `BX-FAM-BUTTON` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER`, `BX-CAP-TIME` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-CHART` | `Chart` | `adapt-concept` | `F4` | `blazex_charts` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-MEASUREMENT`<br>O: — | `local-only` | `nonvisual-representation` | `custom-scene` | `custom-drawn` | `accepted` / `unknown` |
| `BX-FAM-CHECK-BOX` | `CheckBox` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-FIELD` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-CHIP` | `Chip` | `build-natively` | `F2` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-CHIP-SET` | `ChipSet` | `build-natively` | `F2` | `blazex_ui` | `BX-FAM-CHIP` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-COLLAPSE` | `Collapse` | `build-natively` | `F2` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-COLOR-PICKER` | `ColorPicker` | `adapt-concept` | `F3` | `blazex_forms` | `BX-FAM-PICKER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-CONTAINER` | `Container` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-DATA-GRID` | `DataGrid` | `adapt-concept` | `F4` | `blazex_data` | `BX-FAM-TABLE`, `BX-FAM-VIRTUALIZE` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`<br>O: `BX-CAP-CLIPBOARD`, `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `optional-remote` | `server-round-trip` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-DATE-PICKER` | `DatePicker` | `adapt-concept` | `F3` | `blazex_forms` | `BX-FAM-PICKER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-DIALOG` | `Dialog` | `adapt-concept` | `F3` | `blazex_surfaces` | `BX-FAM-FOCUS-TRAP`, `BX-FAM-OVERLAY` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-DIVIDER` | `Divider` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-DRAWER` | `Drawer` | `adapt-concept` | `F3` | `blazex_surfaces` | `BX-FAM-OVERLAY` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER`, `BX-CAP-WINDOW` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-DROP-ZONE` | `DropZone` | `adapt-concept` | `F3` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`, `BX-CAP-POINTER`<br>O: — | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-ELEMENT` | `Element` | `renderer-specific-extension` | `F0` | `blazex_ui_tree` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `omission` | `renderer-extension` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-EXIT-PROMPT` | `ExitPrompt` | `adapt-concept` | `F3` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-WINDOW`<br>O: — | `local-only` | `explicit-unavailable` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-EXPANSION-PANEL` | `ExpansionPanel` | `adapt-concept` | `F2` | `blazex_ui` | `BX-FAM-COLLAPSE` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-FIELD` | `Field` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-INPUT-CONTROL` | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-FILE-UPLOAD` | `FileUpload` | `adapt-concept` | `F3` | `blazex_forms` | `BX-FAM-FIELD` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FILES`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `phoenix-enhanced` | `explicit-unavailable` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-FOCUS-TRAP` | `FocusTrap` | `replace-with-platform-pattern` | `F0` | `blazex_surfaces` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-FORM` | `Form` | `build-natively` | `F0` | `blazex_forms` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `phoenix-enhanced` | `alternative-interaction` | `portable-with-capabilities` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-GRID` | `Grid` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-HIDDEN` | `Hidden` | `build-natively` | `F2` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-HIGHLIGHTER` | `Highlighter` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-HOTKEY` | `Hotkey` | `adapt-concept` | `F3` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER`, `BX-CAP-WINDOW` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-ICON` | `Icon` | `build-natively` | `F0` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-IMAGE` | `Image` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-INPUT` | `Input` | `replace-with-platform-pattern` | `F0` | `blazex_forms` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: `BX-CAP-CLIPBOARD` | `local-only` | `static-content` | `portable-with-capabilities` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-INPUT-CONTROL` | `InputControl` | `replace-with-platform-pattern` | `F0` | `blazex_forms` | `BX-FAM-INPUT` | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-LAYOUT` | `Layout` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: `BX-CAP-WINDOW` | `local-only` | `static-content` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-LINK` | `Link` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-LIST` | `List` | `build-natively` | `F1` | `blazex_data` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `optional-remote` | `server-round-trip` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-MAIN` | `Main` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-MASK` | `Mask` | `adapt-concept` | `F3` | `blazex_forms` | `BX-FAM-TEXT-FIELD` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-CLIPBOARD`, `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-MENU` | `Menu` | `adapt-concept` | `F3` | `blazex_surfaces` | `BX-FAM-FOCUS-TRAP`, `BX-FAM-POPOVER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-MESSAGE-BOX` | `MessageBox` | `replace-with-platform-pattern` | `F3` | `blazex_surfaces` | `BX-FAM-DIALOG` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-NAV-MENU` | `NavMenu` | `adapt-concept` | `F2` | `blazex_ui` | `BX-FAM-LINK` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-NUMERIC-FIELD` | `NumericField` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-INPUT-CONTROL` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-CLIPBOARD`, `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-OVERLAY` | `Overlay` | `replace-with-platform-pattern` | `F0` | `blazex_surfaces` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-SURFACE`<br>O: — | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-PAGE-CONTENT-NAVIGATION` | `PageContentNavigation` | `adapt-concept` | `F3` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-WINDOW`<br>O: `BX-CAP-MEASUREMENT`, `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-PAGINATION` | `Pagination` | `build-natively` | `F2` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-PAPER` | `Paper` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-PICKER` | `Picker` | `replace-with-platform-pattern` | `F0` | `blazex_forms` | `BX-FAM-INPUT-CONTROL`, `BX-FAM-POPOVER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-POPOVER` | `Popover` | `adapt-concept` | `F0` | `blazex_surfaces` | `BX-FAM-OVERLAY` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-MEASUREMENT`, `BX-CAP-SURFACE`<br>O: — | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-PROGRESS` | `Progress` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: `BX-CAP-TIME` | `local-only` | `static-content` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-RADIO` | `Radio` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-FIELD` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-RATING` | `Rating` | `build-natively` | `F2` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-RENDER` | `Render` | `replace-with-platform-pattern` | `F0` | `blazex_ui_tree` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-RTL-PROVIDER` | `RTLProvider` | `replace-with-platform-pattern` | `F0` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-SCROLL-TO-TOP` | `ScrollToTop` | `build-natively` | `F3` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-WINDOW`<br>O: `BX-CAP-MEASUREMENT`, `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-SELECT` | `Select` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-INPUT-CONTROL`, `BX-FAM-POPOVER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-SURFACE`<br>O: `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `optional-remote` | `in-app-substitute` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-SKELETON` | `Skeleton` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: `BX-CAP-TIME` | `local-only` | `static-content` | `portable-with-capabilities` | `custom-drawn` | `accepted` / `unknown` |
| `BX-FAM-SLIDER` | `Slider` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-FIELD` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-SNACKBAR` | `Snackbar` | `adapt-concept` | `F2` | `blazex_surfaces` | `BX-FAM-OVERLAY` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`, `BX-CAP-SURFACE`<br>O: `BX-CAP-NETWORK`, `BX-CAP-NOTIFICATIONS`, `BX-CAP-POINTER`, `BX-CAP-TIME` | `phoenix-enhanced` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-SPACER` | `Spacer` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-SPLIT-PANEL` | `SplitPanel` | `adapt-concept` | `F3` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-POINTER`<br>O: — | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-STACK` | `Stack` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-STEPPER` | `Stepper` | `adapt-concept` | `F2` | `blazex_ui` | `BX-FAM-BUTTON` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-SWIPE-AREA` | `SwipeArea` | `adapt-concept` | `F3` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`, `BX-CAP-POINTER`<br>O: — | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-SWITCH` | `Switch` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-FIELD` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-TABLE` | `Table` | `adapt-concept` | `F4` | `blazex_data` | `BX-FAM-TABLE-SIMPLE` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-CLIPBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `optional-remote` | `server-round-trip` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TABLE-SIMPLE` | `TableSimple` | `replace-with-platform-pattern` | `F1` | `blazex_data` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TABS` | `Tabs` | `adapt-concept` | `F2` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TEXT-FIELD` | `TextField` | `build-natively` | `F2` | `blazex_forms` | `BX-FAM-INPUT-CONTROL` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-CLIPBOARD`, `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-THEME-PROVIDER` | `ThemeProvider` | `replace-with-platform-pattern` | `F0` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: `BX-CAP-STORAGE`, `BX-CAP-SYSTEM-THEME` | `local-only` | `static-content` | `portable-with-capabilities` | `not-applicable` | `accepted` / `unknown` |
| `BX-FAM-TIME-PICKER` | `TimePicker` | `adapt-concept` | `F3` | `blazex_forms` | `BX-FAM-PICKER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-preferred` | `accepted` / `unknown` |
| `BX-FAM-TIMELINE` | `Timeline` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TOGGLE` | `Toggle` | `build-natively` | `F2` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-POINTER` | `local-only` | `alternative-interaction` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TOOL-BAR` | `ToolBar` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TOOLTIP` | `Tooltip` | `adapt-concept` | `F3` | `blazex_surfaces` | `BX-FAM-POPOVER` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`, `BX-CAP-SURFACE`<br>O: `BX-CAP-POINTER`, `BX-CAP-TIME` | `local-only` | `in-app-substitute` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TREE-VIEW` | `TreeView` | `adapt-concept` | `F4` | `blazex_data` | `BX-FAM-LIST` | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-FOCUS`, `BX-CAP-KEYBOARD`<br>O: `BX-CAP-MEASUREMENT`, `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `optional-remote` | `server-round-trip` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-TYPOGRAPHY` | `Typography` | `build-natively` | `F1` | `blazex_ui` | — | R: `BX-CAP-ACCESSIBILITY`<br>O: — | `local-only` | `static-content` | `portable-semantic` | `native-composite` | `accepted` / `unknown` |
| `BX-FAM-VIRTUALIZE` | `Virtualize` | `adapt-concept` | `F4` | `blazex_data` | — | R: `BX-CAP-ACCESSIBILITY`, `BX-CAP-KEYBOARD`, `BX-CAP-MEASUREMENT`<br>O: `BX-CAP-NETWORK`, `BX-CAP-POINTER` | `optional-remote` | `server-round-trip` | `portable-with-capabilities` | `native-composite` | `accepted` / `unknown` |

## Source-closure exception outcomes

| Exception ID | Product disposition | Classification / implementation | Rationale |
| --- | --- | --- | --- |
| `BX-EXC-DOCUMENTATION-EXCLUDED` | `omit-from-product` | `accepted` / `omitted` | Use this material only as reviewed evidence; documentation, tests, and internal helpers do not become BlazeX product families. |
| `BX-EXC-DUPLICATE-NONE` | `no-entry-confirmed` | `accepted` / `omitted` | Preserve the reviewed zero finding explicitly so this source class cannot disappear from later catalog review. |
| `BX-EXC-EXPERIMENTAL-NONE` | `no-entry-confirmed` | `accepted` / `omitted` | Preserve the reviewed zero finding explicitly so this source class cannot disappear from later catalog review. |
| `BX-EXC-ICONS-INFRASTRUCTURE` | `retain-as-infrastructure` | `accepted` / `unknown` | Retain this source class as provenance and cross-cutting infrastructure evidence; it does not create an additional public component family. |
| `BX-EXC-INTERNAL-HELPERS` | `omit-from-product` | `accepted` / `omitted` | Use this material only as reviewed evidence; documentation, tests, and internal helpers do not become BlazeX product families. |
| `BX-EXC-JAVASCRIPT-INFRASTRUCTURE` | `retain-as-infrastructure` | `accepted` / `unknown` | Retain this source class as provenance and cross-cutting infrastructure evidence; it does not create an additional public component family. |
| `BX-EXC-LOCALIZATION-INFRASTRUCTURE` | `retain-as-infrastructure` | `accepted` / `unknown` | Retain this source class as provenance and cross-cutting infrastructure evidence; it does not create an additional public component family. |
| `BX-EXC-OBSOLETE-NONE` | `no-entry-confirmed` | `accepted` / `omitted` | Preserve the reviewed zero finding explicitly so this source class cannot disappear from later catalog review. |
| `BX-EXC-SERVICES-SERVICE-ONLY` | `retain-as-service-evidence` | `accepted` / `unknown` | Retain service registrations as capability and host-adapter evidence without cloning MudBlazor dependency injection or adding a visual family. |
| `BX-EXC-TESTS-EXCLUDED` | `omit-from-product` | `accepted` / `omitted` | Use this material only as reviewed evidence; documentation, tests, and internal helpers do not become BlazeX product families. |
| `BX-EXC-THEME-STYLE-INFRASTRUCTURE` | `retain-as-infrastructure` | `accepted` / `unknown` | Retain this source class as provenance and cross-cutting infrastructure evidence; it does not create an additional public component family. |
| `BX-EXC-UNRESOLVED-NONE` | `no-entry-confirmed` | `accepted` / `omitted` | Preserve the reviewed zero finding explicitly so this source class cannot disappear from later catalog review. |

## Evidence boundary

Every row is an accepted product classification layered over locked source evidence.
No row is implemented, evidenced, supported, native-compatible, renderer-compatible,
or API-compatible. Public identities are provisional BlazeX planning names and are not
runtime atoms or a MudBlazor/.NET compatibility surface.

## Connections

- [Disposition, tier, and package policy](../../20-notes/blazex-component-disposition-tier-and-package-policy.md)
- [Phase 4 implementation evidence](../../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-04-implementation-evidence.md)

## Sources

- [Locked Phase 3 source catalog](blazex-component-catalog-v0.1.0.json)
- [Canonical Phase 4 classification](blazex-component-classification-v0.1.0.json)
