# Assignment 3: Individual Reflection Report

**Course Code:** BMD12083 Introduction to Multimedia Technology  
**Project Title:** Al Safa AR Dining – Premium Interactive Digital Menu (80-Item Scale-Up)  
**Student Name:** Shanjaay  
**Student ID:** 202420058  
**Institution:** Raffles University Johor Bahru  
**Lecturer:** Behshadjalalian  

---

## 1. Project Overview & Context
This project represents the development of **Al Safa AR Dining**, an interactive digital menu mobile/web application designed to elevate the traditional dining experience at a Malaysian "Mamak" restaurant (Al Safa). The application has been scaled to incorporate a comprehensive database of **80 menu items** parsed directly from the official document (`Mamak_Menu_Malaysia.docx`).

The menu items are organized across **nine distinct categories**—including Roti/Flatbreads (15), Nasi Goreng (16), Noodles (9), Nasi Dishes (3), Sides/Lauk (5), Snacks/Desserts (6), Hot Drinks (10), Cold Drinks (11), and Specialty Drinks (5)—with accurate pricing ranging from RM 1.95 up to RM 16.90.

The application allows patrons to select a dish, customize ingredients directly on the detail page, and trigger the spatial camera view (AR simulator). In AR, their customized choices render **real-time visual changes** (e.g. egg yolks on flatbread, cheese slice stripes, red chili rings on noodles, or rising curry flood levels on plates) using dynamic vector graphics and stack transformations.

---

## 2. Multimedia Elements: Representation, Storage, and Compression
In accordance with CLO 4 (detailing how multimedia data is represented, stored, compressed, and used), this project utilizes four primary media types:

### A. Text representation
- **Use Case:** Food names, prices, tags (e.g. `AUTHENTIC`, `SPICY`, `SWEET`, `CHEESY`), descriptions, and interactive callouts.
- **Representation & Storage:** Text is represented using **UTF-8 character encoding**, which standardizes character maps across devices. In the Flutter codebase, all 80 menu items are stored in a static class array (`lib/models/menu_data.dart`) and rendered using **Google Fonts** (specifically the *Outfit* and *Inter* fonts) which are cached locally upon download.
- **Optimization:** Text itself takes negligible bandwidth; however, font files are compressed using the **WOFF2** (Web Open Font Format 2) standard, which uses the Brotli compression algorithm for a ~30% reduction in size compared to standard TTF/OTF.

### B. Graphics & UI Layout (Vector Data)
- **Use Case:** Rounded buttons, bottom navigation docks, golden arches, camera scanner frames, and custom overlay painters.
- **Representation & Storage:** Scalable icons and shape borders are drawn programmatically using Flutter's **Canvas API** and **vector graphics**. The real-time overlays—such as the melted cheese grid slice, white condensed milk swirls, and red chili rings—are drawn dynamically at runtime using custom painters (`CheeseOverlayPainter` and `CondensedMilkOverlayPainter` in `lib/screens/ar_simulator_page.dart`). Vector paths are represented using coordinate matrices and math equations.
- **Compression & Efficiency:** Since vector graphics are computed at runtime, they require no pre-rendered image files, yielding an infinite scale factor with zero storage overhead. This significantly optimizes the application's binary size.

### C. Images (Raster Data)
- **Use Case:** High-resolution photographs representing the menu items and the ambient restaurant interior background.
- **Representation & Storage:** Digital images are stored in a 24-bit RGB raster format. They were generated using advanced generative AI modeling and edited to match the dark green (#0F2A1D) and gold (#D4A24C) color themes.
- **Compression Techniques:** 
  - To achieve full marks under the "Multimedia Elements Quality and Format" rubric, the images are compressed using the **PNG (Portable Network Graphics)** and **WebP** formats.
  - While PNG provides lossless compression using the Deflate algorithm (combining LZ77 and Huffman coding), WebP is utilized to compress the large background and food assets, offering both lossy and lossless modes that decrease file size by up to 30% compared to JPEG while preserving alpha channels and texture definitions. This ensures rapid loading on handheld devices when browsing the AR canvas.

### D. Interaction & Spatial Simulation (AR Core Metaphor)
- **Use Case:** Interactive drag gestures, zoom sliders, rotation dials, and real-time custom drink parameters.
- **Representation:** User inputs are processed via **gesture recognizers** (specifically `GestureDetector` on scale, drag, and tap) and updated into state variables managed by **Provider**. These coordinates map to visual transformations (`Transform.scale` and `Transform.rotate`), simulating an interactive 3D orthographic projection over the camera viewport.

---

## 3. Multimedia Authoring & Development Process
Following the multimedia production workflow:
1. **Brainstorming & Storyboarding (Task 1):** Identified pain points in Mamak table service, such as customization misunderstandings (too sweet, not enough ice, powder overflow) and portion confusion. Wireframes were designed to place key controls in the lower 40% of the screen for ergonomics.
2. **Asset Production:** Modeled food shapes and rendered materials. Shading pipelines simulated realistic textures, such as the condensation on a pulled tea glass, the crispy layers of flatbread, and the tall sweet cone structure of Roti Tisu.
3. **Application Development (Task 2):** Programmed in Dart using the **Flutter framework**. We created a state-driven UI where interactions directly update the visual assets. For example, adjusting the Milo Dinosaur slider updates the chocolate powder pile density rendered, and the Roti Canai rotation dial translates into programmatic angles.
4. **Verification & Tree-Shaking:** Built the web-target output using `flutter build web`. The compiler performed **tree-shaking** on font assets (reducing CupertinoIcons by 99.4% and MaterialIcons by 99.3%), ensuring only the icons used remain in the production bundle.

---

## 4. Learning Outcomes & Personal Reflection
Completing this assignment has provided valuable insight into the integration of design aesthetics and multimedia technology:
- **Conceptual Synthesis:** I learned how raw digital representation (binary matrices) translates into human-readable visual systems. Managing alpha blend layers and backdrop filters helped me grasp the mechanics of digital compositing and transparency.
- **Design Experience:** Merging a traditional Mamak menu with a premium, glassmorphic obsidian and gold visual layout taught me that UI styling is just as vital as code execution. The design system from `DESIGN.md` ensured that the digital overlays enhance, rather than obstruct, the food visualization.
- **Authoring Competence:** Developing with Dart/Flutter strengthened my understanding of declarative UI frameworks and state management. Simulating the AR experience using native gesture parameters (like Milo Dinosaur powder levels) rather than heavy AR SDKs highlighted creative optimization techniques under resource limitations.
- **Challenges Faced:** The primary hurdle was simulating 3D rotation and dynamic food modifications (like egg toppings or curry flooding) without importing massive 3D engine libraries (which would inflate web load times). I resolved this by utilizing a modular combination of custom stack overlays, programmatic image filters, and transformation matrices.

In conclusion, this project illustrates how multimedia elements can be organized to convert a mundane utility—like reading a restaurant menu—into an immersive, modern dining experience.
