# Version: 0.44.0
# Created: Petr Krivan
# Project: android lab manager

API_PRESETS = [
    ('33', 'Android 13', 'Tiramisu', 'google_apis', 'No Play Store; Google APIs/services'),
    ('33', 'Android 13', 'Tiramisu', 'google_apis_playstore', 'Play Store image, if available'),
    ('34', 'Android 14', 'Upside Down Cake', 'google_apis', 'No Play Store; Google APIs/services'),
    ('34', 'Android 14', 'Upside Down Cake', 'google_apis_playstore', 'Play Store image, if available'),
    ('35', 'Android 15', 'Vanilla Ice Cream', 'google_apis', 'No Play Store; Google APIs/services'),
    ('35', 'Android 15', 'Vanilla Ice Cream', 'google_apis_playstore', 'Play Store image, if available'),
    ('36', 'Android 16', 'Baklava', 'google_apis', 'No Play Store; Google APIs/services'),
    ('36', 'Android 16', 'Baklava', 'google_apis_playstore', 'Play Store image, if available'),
]

NOVNC_PROFILES = {
    'compact': ('1024x768x24', '420x780', ''),
    'normal': ('1280x900x24', '540x960', ''),
    'large': ('1366x900x24', '720x1280', ''),
    'xlarge': ('1600x1000x24', '720x1280', ''),
    'fullhd': ('1920x1080x24', '1080x1920', '0.55'),
}

NOVNC_PROFILE_LABELS = {
    'compact': 'Compact — 1024x768 desktop, 420x780 emulator',
    'normal': 'Normal — 1280x900 desktop, 540x960 emulator',
    'large': 'Large — 1366x900 desktop, 720x1280 emulator',
    'xlarge': 'Extra large — 1600x1000 desktop, 720x1280 emulator',
    'fullhd': 'Full HD phone — 1920x1080 desktop, 1080x1920 emulator, scaled 0.55',
}

DEVICE_PROFILES = [
    ('pixel', 'Generic Pixel'),
    ('pixel_5', 'Pixel 5'),
    ('pixel_6', 'Pixel 6'),
    ('pixel_6_pro', 'Pixel 6 Pro'),
    ('pixel_7', 'Pixel 7'),
    ('pixel_7_pro', 'Pixel 7 Pro'),
    ('pixel_8', 'Pixel 8'),
    ('pixel_8_pro', 'Pixel 8 Pro'),
]
