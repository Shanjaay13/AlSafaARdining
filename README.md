# Al Safa AR Dining

Al Safa AR Dining is a premium, interactive Augmented Reality (AR) menu and dining application built using Flutter. The system transforms the traditional dining experience by allowing customers to scan a table QR code, browse a rich visual menu, customize their orders in real-time with dynamic visual overlays, and visualize dishes in a simulated AR environment before ordering.

Designed with a modern, high-contrast **Obsidian Black** and **Midnight Green** color scheme, highlighted by **Refined Gold** accents and typography powered by the **Outfit** Google Font.

---

## Key Features

*   **QR Table Unlocking:** Simulates a table QR code scanning interface that securely connects the customer's session to a specific dining table (e.g., Table #12).
*   **Interactive AR Simulator:** 
    *   Place, rotate, and scale virtual food models on a simulated restaurant background.
    *   Pinch-to-zoom and drag-to-position support.
    *   Camera scanning grid and digital overlays for realistic AR feel.
*   **Real-Time Customization Visuals:**
    *   *Drinks:* Sliders to control ice levels (visibly adding ice cubes) and sweetness/powder density.
    *   *Roti / Flatbreads:* Toggle eggs, cheese, or condensed milk, which apply dynamic visual layers onto the food graphics.
    *   *Noodles / Rice:* Custom spicy levels that dynamically scatter red chili rings based on mild, medium, or extra hot preferences.
    *   *Sides (Lauk):* Adjust gravy (kuah) style between dry, normal, and a "Curry Flood" (Banjir) overlay.
*   **Food Anatomy Callout Pins:** Interactive hotspots on signature dishes (like Nasi Lemak) that detail the ingredients, sourcing, and preparation of individual components (e.g., Coconut Rice, House-made Sambal, Spiced Fried Chicken).
*   **Nutrition & Ingredients Sidebar:** Instantly view calories, macronutrients (protein, carbs), and ingredient breakdowns to make informed dietary choices.
*   **Seamless Cart & Ordering:** Dynamic state-managed shopping cart and a polished checkout flow.

---

## Tech Stack & Architecture

*   **Framework:** [Flutter](https://flutter.dev/) (SDK version `^3.11.5`)
*   **State Management:** [Provider](https://pub.dev/packages/provider) (for cart management and real-time custom option sync)
*   **UI Components & Theming:** Custom Dark Theme (`ThemeData.dark()`) with HSL color palettes, custom gradients, and custom canvas painters (`CustomPaint` overlays)
*   **Typography:** Google Fonts ([Outfit](https://fonts.google.com/specimen/Outfit))

---

## Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
*   An active IDE (VS Code, Android Studio) or Flutter CLI.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Shanjaay13/AlSafaARdining.git
    cd AlSafaARdining
    ```

2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    To run on your preferred device (e.g., Google Chrome or native macOS desktop):
    ```bash
    flutter run -d chrome
    # or
    flutter run -d macos
    ```

---

## Project Structure

```
lib/
├── main.dart                 # App initialization & global providers
├── models/
│   └── menu_data.dart        # Static menu structures & mock data
├── providers/
│   └── cart_provider.dart    # Cart state & customization models
├── screens/
│   ├── qr_scanner_page.dart  # QR Table Unlock portal
│   ├── home_page.dart        # Category explorer & main dashboard
│   ├── detail_page.dart      # Customization & details view
│   ├── ar_simulator_page.dart# Interactive AR viewport & visual overlays
│   └── order_confirmed_page.dart # Checkout success screen
└── widgets/
    └── premium_food_visual.dart  # Custom canvas/vector food graphics
```
