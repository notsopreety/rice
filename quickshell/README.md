# Quickshell Widgets

A collection of high-performance, themed desktop widgets for the Quickshell Wayland shell.

## Included Widgets

- **Clock**: A Material 3 scalloped analog clock with Pywal support and proportional scaling.
- **Calendar**: A Nepali BS (Bikram Sambat) calendar with holiday tracking and Pywal integration.

## Management

All widgets can be managed via the `manage_widgets.sh` script.

### Registry
Configure your widgets in `widgets.txt`:
```text
clock /path/to/clock.qml
calendar /path/to/calendar.qml
```

### Commands
```bash
./manage_widgets.sh <command> <id|all>

Commands:
  load      Start widget
  unload    Stop widget
  restart   Reload widget
  toggle    Toggle run state
  list      List registered widgets
```

## Structure
```text
.
├── clock/
│   ├── clock.qml
│   ├── settings.json
│   └── README.md
├── calendar/
│   ├── calendar.qml
│   ├── settings.json
│   └── NepaliDate.js
├── widgets.txt
└── manage_widgets.sh
```
