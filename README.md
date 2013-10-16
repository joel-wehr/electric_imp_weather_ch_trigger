electric_imp_weather_ch_trigger
===============================

Sunrise/Sunset trigger for use with an Electric Imp. Trigger your device at sunrise and sunset. Useful for turning on lights
decorations only during the day or night, and requires no physical sensors.

In order to not pass 0 as a parameter, the code adds 1 minute to sunrise/sunset, so it will trigger 1 minute after each.
