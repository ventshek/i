=============Rough notes=============

>Appearance
Global themes = plasmaxdark
Application style = Breeze
Plasma style = Breeze
Colours = plasmaxdark
Window Decorations = plasmaxdark
Fonts = nochange
Icons = Windows 10
Cursors = Clones 
Splash Screen = non

=============Step by step=============

1. Install Tiled menu && win7 volume, add config and resize desktop menu apps.

2. Install PlasmaXDark and set Breeze Dark as global theme, shrink panel to 34.

3. Application style to Oxygen and Plasma style && colours to PlasmaXDark.

4. Window Decorationsto PlasmaXDark, icons to Newinx/win10 or PlasmaXDark and edit titlebar.

5. Install cursors 'Windows 10 KDE' and set to win 10.

6. Set Splash screen to off and install Plasma X login for login screen, change and sync.

7. run ova, delete ova.

8. Run archdi for changes.

9. Menu config =
{
  "fullscreenDefault": false,
  "fullscreen": false,
  "iconDefault": "start-here-kde",
  "icon": "start-here-kde",
  "fixedPanelIconDefault": true,
  "fixedPanelIcon": false,
  "searchResultsMergedDefault": true,
  "searchResultsMerged": true,
  "searchResultsCustomSortDefault": false,
  "searchResultsReversedDefault": false,
  "searchDefaultFiltersDefault": [
    "Dictionary",
    "services",
    "calculator",
    "shell",
    "org.kde.windowedwidgets",
    "org.kde.datetime",
    "baloosearch",
    "locations",
    "unitconverter"
  ],
  "searchDefaultFilters": [
    "Dictionary",
    "services",
    "calculator",
    "shell",
    "org.kde.windowedwidgets",
    "org.kde.datetime",
    "baloosearch",
    "locations",
    "unitconverter"
  ],
  "showRecentAppsDefault": true,
  "showRecentApps": true,
  "recentOrderingDefault": 1,
  "recentOrdering": 1,
  "numRecentAppsDefault": 5,
  "numRecentApps": 5,
  "sidebarShortcutsDefault": [
    "xdg:DOCUMENTS",
    "xdg:PICTURES",
    "org.kde.dolphin.desktop",
    "systemsettings.desktop"
  ],
  "sidebarShortcuts": [
    "xdg:DOCUMENTS",
    "xdg:PICTURES",
    "org.kde.dolphin.desktop",
    "systemsettings.desktop"
  ],
  "defaultAppListViewDefault": "Alphabetical",
  "defaultAppListView": "Alphabetical",
  "tileModelDefault": "",
  "tileModel": [
    {
      "x": 0,
      "y": 0,
      "w": 2,
      "h": 2,
      "url": "octopi.desktop",
      "label": "Software Center"
    },
    {
      "x": 2,
      "y": 0,
      "w": 2,
      "h": 2,
      "url": "systemsettings.desktop"
    },
    {
      "x": 4,
      "y": 0,
      "w": 2,
      "h": 2,
      "url": "org.kde.dolphin.desktop"
    },
    {
      "x": 0,
      "y": 2,
      "w": 2,
      "h": 2,
      "url": "org.gnome.DiskUtility.desktop"
    },
    {
      "x": 0,
      "y": 4,
      "w": 2,
      "h": 2,
      "url": "fwbuilder.desktop"
    },
    {
      "x": 4,
      "y": 4,
      "w": 2,
      "h": 2,
      "url": "virtualbox.desktop"
    },
    {
      "x": 2,
      "y": 2,
      "w": 2,
      "h": 2,
      "url": "torbrowser.desktop"
    },
    {
      "x": 4,
      "y": 2,
      "w": 2,
      "h": 2,
      "url": "firefox.desktop"
    },
    {
      "x": 2,
      "y": 4,
      "w": 2,
      "h": 2,
      "url": "kcm_firewall.desktop"
    },
    {
      "x": 0,
      "y": 6,
      "w": 2,
      "h": 2,
      "url": "keepass.desktop",
      "showLabel": true,
      "label": "KeePass"
    },
    {
      "x": 2,
      "y": 6,
      "w": 2,
      "h": 2,
      "url": "org.kde.kgpg.desktop"
    },
    {
      "x": 4,
      "y": 6,
      "w": 2,
      "h": 2,
      "url": "sublime_text.desktop"
    }
  ],
  "tileScaleDefault": 0.8,
  "tileMarginDefault": 5,
  "tileMargin": 2,
  "tilesLockedDefault": false,
  "tilesLocked": false,
  "defaultTileColorDefault": "",
  "defaultTileColor": "",
  "defaultTileGradientDefault": false,
  "defaultTileGradient": false,
  "sidebarBackgroundColorDefault": "",
  "sidebarBackgroundColor": "",
  "hideSearchFieldDefault": false,
  "hideSearchField": true,
  "searchFieldFollowsThemeDefault": false,
  "searchFieldFollowsTheme": true,
  "sidebarFollowsThemeDefault": false,
  "sidebarFollowsTheme": true,
  "tileLabelAlignmentDefault": "left",
  "tileLabelAlignment": "left",
  "appDescriptionDefault": "after",
  "appDescription": "after",
  "menuItemHeightDefault": 36,
  "menuItemHeight": 36,
  "searchFieldHeightDefault": 48,
  "searchFieldHeight": 48,
  "appListWidthDefault": 350,
  "appListWidth": 350,
  "favGridColsDefault": 6,
  "favGridCols": 6,
  "popupHeightDefault": 620,
  "popupHeight": 550,
  "sidebarButtonSizeDefault": 48,
  "sidebarButtonSize": 48,
  "sidebarIconSizeDefault": 30,
  "sidebarIconSize": 26,
  "sidebarPopupButtonSizeDefault": 36,
  "sidebarPopupButtonSize": 36
}
