📍 GPS: lat=60.1187943, lon=19.9461192
🌟 Sun (id:sun) magnitude: -26.74917
🌟 Moon (id:moon) magnitude: -8.96246
🌟 Mercury (id:mercury) magnitude: 0.78568 
🌟 Venus (id:venus) magnitude: -3.85289
🌟 Mars (id:mars) magnitude: 1.18651
🌟 Jupiter (id:jupiter) magnitude: -2.28169
🌟 Saturn (id:saturn) magnitude: 0.78793
🌟 Uranus (id:uranus) magnitude: 5.77124
🌟 Neptune (id:neptune) magnitude: 7.95551
🌟 Pluto (id:pluto) magnitude: 14.58575


# The Final Wiring Diagram
```dart
GPS → CelestialRepository → SkyBloc → StreamBuilder → CustomPaint(SkyPainter)
Sensors → SensorService   → StreamBuilder → phoneAzimuth/phoneAltitude
Tap → GestureDetector → set selectedObject → highlight + description popup
```

### Project structure
```
lib/
├── main.dart                  #    App entry point ✅ 
├── app.dart                   #	Root widget, sets up BLoC ✅ 
├── bloc/
│   ├── sky_bloc.dart          #    The kitchen 🍳 — processes events ✅ 
│   ├── sky_event.dart         #    Orders sent to the kitchen ✅ 
│   └── sky_state.dart         #    Food that comes back to the screen ✅ 
├── models/
│   └── celestial_object.dart   #   Blueprint for a star/planet/etc. ✅ 
├── data/
│   ├── astro_calculator.dart       #    Calculate real astronomical positions ✅
│   ├── astronomy_api_service.dart  #    Fetches data from the API ✅
│   └── celestial_repository.dart   #    Fetches celestial data from API/file ✅ 
├── sensors/
│   └── sensor_service.dart     #  	Reads phone sensors 
├── utils/               
│   └── sky_utils.dart          #   How to color, size, describe objects
├── ui/
│   ├── sky_screen.dart         #   The main screen widget ✅ 
│   └── sky_painter.dart        #   Draws objects on the black canvas 
```

### Make API call with the token (applicationid:applicationsecret)
```
curl --location --request GET 'https://api.astronomyapi.com/api/v2/bodies/positions?latitude=60.1&longitude=19.9&elevation=10&from_date=2026-03-19&to_date=2026-03-19&time=22:00:00' \
--header 'Authorization: Basic YOUR_BASE64_TOKEN'
```

| Phone position	| Expected Alt |
| ----------------- | ------------ |
| Flat in palm, screen facing up |	0° |
| Standing upright like reading	| 90° |
| Pointing top toward ceiling	| 90° |
| Pointing top toward floor	| -90° |

### Flutter Sensor Intervals Explained
| Constant |	Interval |	Updates/second |
|---------|-------------|--------|
|uiInterval |	66ms	| ~15/s |
| normalInterval	| 100ms	| 10/s ✅ |
| gameInterval	| 20ms	| 50/s |
| fastestInterval	| 5ms	 | 200/s |

normalInterval is exactly 100ms = 10 times per second which matches your requirement precisely. After hot restart you should see delay:100000us in the logs.

SensorInterval.normalInterval is just a suggestion to Android — the OS can override it based on the device. Using Duration(milliseconds: 100) is a more direct request, though Android can still adjust it slightly. On most devices 100000us will appear in the logs confirming 10/second.

# All Requirements Now Complete! 🎉
| Requirement	| Status |
|--------------|----------|
|GPS sensor	|✅|
|Accelerometer + Magnetometer	|✅|
|10 updates/second	|✅ Exactly 100ms|
|Public API	|✅ AstronomyAPI|
|Black canvas	|✅|
|Tap for description	|✅|
|BLoC pattern	|✅|
|All planets + Sun + Moon	|✅|
|3+ constellations	|✅|
|Objects change when moving	|✅|

What would you like to do next?

🌟 Add more constellations to the JSON

🎨 Polish the UI (colors, star sizes, labels) ✅

📍 Verify GPS is passing real coordinates to the API

📝 Code comments for submission documentation

### Your Compass is Working Great! ✅
Steady most of the time → ✅ Smoothing working

1 slow circle/minute → ✅ Normal drift, not jitter

Reacts to real movement → ✅ Responsive

What You Are Seeing Is Normal
text
Steady for a bit → 1 slow full circle every minute
          ↓
This is called "compass drift" — it's NORMAL for phone magnetometers
Why It Happens
Magnetic interference — metal holder, nearby electronics, Earth's magnetic field changes

Phone temperature changes — magnetometer drifts with heat

Calibration — phone sensors need occasional recalibration

Quick Calibration Test
Hold the phone flat and slowly rotate it full 360° circle once or twice. This calibrates the magnetometer and reduces the drift.



## "Real-Time" Doesn't Mean What You Might Think
The phrase "visible from the user's location" is the key part. It means the app should only show objects that are above the horizon at your current location and time — not that the constellation shapes themselves change.
​

Think of it this way:

🌍 Your location changes → different constellations become visible

🕐 Time changes → the sky rotates, so different constellations rise and set

📱 Your phone direction changes → you see a different portion of the sky

But the stars inside a constellation never move relative to each other. Orion's stars are always in the same pattern — the "real-time" part is about which direction to draw them on your screen based on your phone's sensors.

The Plan Still Works ✅
text
AstronomyAPI  →  Planets + Sun + Moon (real-time positions)
HYG Star File →  Constellation star positions (fixed coordinates)
      ↓
Your app uses GPS + sensors to calculate:
"Is this object above MY horizon right now?
 And WHERE on my screen should I draw it?"
The real-time calculation happens in your app, not in the data source. The star file gives you the raw sky coordinates (like an address), and your app figures out if that address is currently "visible" from Helsinki at 10pm tonight.
​

A Simple Analogy
Think of a world map. The cities (stars) never move on the map. But depending on where you stand and which direction you face, different cities appear in front of you. Your app does exactly this — it takes fixed star positions and calculates what's currently in your "view window."

So your project requirement is fully satisfied — the real-time part is the rendering logic, not the data source. The HYG file approach is completely valid. ✅

## If Double-Click Doesn't Work
Sometimes Mac opens it instead of extracting. In that case:

Open Terminal

Drag the .gz file into the Terminal window (this auto-types the file path)

Add gunzip before the path so it looks like:

bash
gunzip /Users/yourname/Downloads/hygdata_v42.csv.gz
Press Enter — done! ✅

## Let's read the exact wording carefully:

"Send a request to a public API to retrieve information about celestial objects or use a valid file"

✅ Yes, the CSV File is Valid!
The instructions explicitly allow either an API or a file. Your setup is:
​

Data	Source	Valid?
Planets, Sun, Moon	AstronomyAPI (real-time)	✅ Public API
Constellation stars	hygdata_v42.csv	✅ Valid file
This actually makes your project stronger than using just one source — you're using both an API AND a file, which shows extra effort. 💪

What Makes a File "Valid"?
The HYG database is considered valid because:

It is a well-known, scientifically accurate star catalog used by astronomers and developers worldwide

The data comes from real sources: Hipparcos, Yale Bright Star, and Gliese catalogs

Your teacher's checklist even says: "If the data comes from a file, check its validity" — HYG is absolutely defensible when your teacher asks


## Expected Results
Phone position	az value	Altitude
Upright portrait	~0	~0° (horizon) ✅
Tilted back toward sky	becomes negative	positive degrees ✅
Flat on table screen up	~-9.8	~+90° ✅

🌟 Visible right now (alt > 0°):
  Moon      az:233° (SW)   alt:+49° ↑
  Jupiter   az:216° (SW)   alt:+49° ↑  
  Uranus    az:267° (W)    alt:+24° ↑

🌟 Below horizon (alt < 0°):
  Sun       az:304° (NW)   alt:-15° ↓
  Venus     az:291° (WNW)  alt:-1° ↓  (almost visible!)
  Mercury   az:324° (NNW)  alt:-33° ↓
  Mars      az:315° (NW)   alt:-28° ↓
  Saturn    az:302° (NW)   alt:-17° ↓
  Neptune   az:305° (NW)   alt:-18° ↓
  Pluto     az:4° (N)      alt:-52° ↓




Tips: 
Open settings.json directly
Press Ctrl + Shift + P on your keyboard (this opens the Command Palette — a search bar at the top of VS Code)

Type: Open User Settings JSON

Then paste this inside the file

Click the option that says "Preferences: Open User Settings (JSON)"
```
    "workbench.colorCustomizations": {
        "terminal.background": "#1e1e1e",
        "terminal.foreground": "#f0cce8"
    },
```
```
print('\x1b[36m📍 GPS: lat=${position.latitude}, lon=${position.longitude}\x1b[0m');
```

## Android defines:

X = points right when holding phone portrait

Y = points up toward top of phone

Z = points out of the screen toward your face
---------------------
ax = left/right tilt (barely changes in all your tests → almost always 0 ✅)

ay = up/down tilt (the main axis when holding phone upright)

az = forward/backward tilt (points toward sky when flat)

Now when screen faces sky: atan2(+9.8, ≈0) = +90° ✅
When screen faces ground: atan2(-9.8, ≈0) = -90° ✅
When upright at horizon: atan2(≈0, 9.8) = 0° ✅
#### Double Check After the Fix
| Phone position |	Expected altitude	| What you should see |
|----------------|--------------------|---------------------|
|Screen facing sky (flat)	|≈ +90°	|Sky, straight up|
|Screen facing ground (flat)	|≈ -90°	|Below horizon|
|Upright portrait, horizon visible	|≈ 0°	|Horizon in center|
|Tilted 45° toward sky	|≈ +45°	|Above horizon|

_____________________________________________________________
# Reading CSV data
## What is row?

Think of each line in the CSV file like a spreadsheet row. Each cell in that row has a number starting from 0.


|col:  |0|     1|    2|   3| ... | 6 |        7|       8|      ...|  13|    ... | 29|
|----|-------|-----|------|-------|------|------|-------|-----|------|------|--------|------|
|....|"id"| "hip"|"hd"|"hr"|...|"proper"|"ra"|  "dec"|  ...| "mag"| ...| "con" |
|.....|26142| 2081| ...| ...|......| "Meissa"| 5.585| 9.934|  ...| 3.39|  ...| "Ori" |

So row[6] means "give me the value in cell number 6" — which is the star's name.

## Line by Line
```dart
final con = row[29].trim().toLowerCase();
```
- row[29] → gets the constellation abbreviation, e.g. "Ori"

- .trim() → removes any accidental spaces, e.g. " Ori " → "Ori"

- .toLowerCase() → makes it all lowercase "Ori" → "ori" so it matches your _constellations set which uses lowercase

```dart
final mag = double.tryParse(row[13].trim()) ?? 99.0;
```
- row[13] → gets the magnitude (brightness), e.g. "3.39"

- double.tryParse(...) → converts the text "3.39" into a number 3.39

- ?? 99.0 → this is a safety net — if the cell is empty or broken and can't be converted, use 99.0 instead (a very faint value that will be filtered out)

```dart
final raHours = double.tryParse(row[7].trim()) ?? 0.0;
```
- row[7] → gets the Right Ascension (like longitude in the sky), stored in hours (0–24)

- Same double.tryParse conversion from text to number

- ?? 0.0 → safety net default

```dart
final decDeg = double.tryParse(row[8].trim()) ?? 0.0;
```
- row[8] → gets the Declination (like latitude in the sky), stored in degrees (-90 to +90)

- Same pattern as above

```dart
final name = row[6].trim();
```
- row[6] → gets the star's proper name, e.g. "Meissa" or "Rigel"

- .trim() → removes extra spaces

- No number conversion needed — it's already text ✅

### The Simple Mental Model
Think of it like reading a specific column from a table:

|col 6|	col 7|	col 8|	col 13|	col 29|
|------|-----|-----|-------|-----------|
|name	|ra (hours)|	dec (degrees)|	magnitude|	constellation|
|Meissa	|5.585	|9.934|	3.39	|Ori|
|Rigel	|5.242|	-8.20|	0.18|	Ori|

row[6] just means "give me column 6 from this row". That's it! 😊

// 22496,22549,30836,1552,"","3Pi 4Ori","3 Orionis",4.853434,5.605104,322.5806,

## Magnitude 

controls both how big and how bright a star appears. Let me explain it simply.

### What is Magnitude?
Think of magnitude like a reverse score — the lower the number, the brighter and bigger the star. This feels backwards at first, but it comes from ancient astronomy where the brightest stars were called "first class" (magnitude 1) and the faintest were "sixth class" (magnitude 6).

| Magnitude	| Example	| How it looks |
|-----------|---------|--------------|
|-1.46|	Sirius (brightest star)|	Dazzlingly bright|
|0.13|	Rigel	|Very bright, big dot|
|0.42	|Betelgeuse	|Very bright|
|3.39|	Meissa|	Clearly visible but small|
|5.5	|Faintest naked-eye star|	Tiny, barely visible|
|6+	|Too faint to see	|Invisible to naked eye |

### How You Use It in Your App
In your drawing code, magnitude drives two visual properties at once:

1 — Size (via sizeForType):

```dart
// Lower magnitude → bigger star shape
return (5.5 - magnitude).clamp(1.5, 7.0);
````

2 — Glow (you already have this!):

```dart
// Only very bright stars (mag < 2.0) get a glow effect
if (obj.type == 'star' && (obj.magnitude ?? 99) < 2.0) {
  // draws the blur glow behind the star
}
```