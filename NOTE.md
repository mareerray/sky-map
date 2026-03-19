
### Project structure
```
lib/
├── main.dart                  #    App entry point
├── app.dart                   #	Root widget, sets up BLoC
├── bloc/
│   ├── sky_bloc.dart          #    The kitchen 🍳 — processes events
│   ├── sky_event.dart         #    Orders sent to the kitchen
│   └── sky_state.dart         #    Food that comes back to the screen
├── models/
│   └── celestial_object.dart   #   Blueprint for a star/planet/etc.
├── data/
│   └── celestial_repository.dart   #   	Fetches celestial data from API/file
├── sensors/
│   └── sensor_service.dart     #  	Reads phone sensors 
├── ui/
│   ├── sky_screen.dart         #   The main screen widget 
│   └── sky_painter.dart        #   Draws objects on the black canvas
```

### Make API call with the token (applicationid:applicationsecret)
```
curl --location --request GET 'https://api.astronomyapi.com/api/v2/bodies/positions?latitude=60.1&longitude=19.9&elevation=10&from_date=2026-03-19&to_date=2026-03-19&time=22:00:00' \
--header 'Authorization: Basic YOUR_BASE64_TOKEN'
```

