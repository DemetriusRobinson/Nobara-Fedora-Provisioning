// This script is populated by shell with values:
// {{SCREEN}} ← monitor index
// {{TOP_OK}}, {{BOTTOM_OK}} ← boolean flags

function toInt(v) { return parseInt(v); }
var selectedScreen = toInt("{{SCREEN}}");

// === Top Panel === //
if ("{{TOP_OK}}" == "true") {
    var existingTopPanel = null;
    for (var i = 0; i < panelIds.length; ++i) {
        var p = panelById(panelIds[i]);
        if (p.screen == selectedScreen && p.location == "top") {
            existingTopPanel = p;
            break;
        }
    }

    if (existingTopPanel) {
        existingTopPanel.destroy();
    }

    var topPanel = new Panel;
    topPanel.location = "top";
    topPanel.height = 22;
    topPanel.screen = selectedScreen;
    topPanel.floating = false;

    while (topPanel.widgetIds.length > 0)
        topPanel.removeWidget(topPanel.widgetIds[0]);

    topPanel.addWidget("org.kde.plasma.kickerdash"); // Application Dashboard

    var centerSpacer = topPanel.addWidget("org.kde.plasma.panelspacer");
    centerSpacer.currentConfigGroup = ["General"];
    centerSpacer.writeConfig("expanding", "true");

    topPanel.addWidget("org.kde.plasma.digitalclock");

    var rightSpacer = topPanel.addWidget("org.kde.plasma.panelspacer");
    rightSpacer.currentConfigGroup = ["General"];
    rightSpacer.writeConfig("expanding", "true");

    topPanel.addWidget("org.kde.plasma.systemtray");
}

// === Bottom Panel === //
if ("{{BOTTOM_OK}}" == "true") {
    var existingBottomPanel = null;
    for (var i = 0; i < panelIds.length; ++i) {
        var p = panelById(panelIds[i]);
        if (p.screen == selectedScreen && p.location == "bottom") {
            existingBottomPanel = p;
            break;
        }
    }

    if (existingBottomPanel) {
        existingBottomPanel.destroy();
    }

    var bottomPanel = new Panel;
    bottomPanel.location = "bottom";
    bottomPanel.height = 44;
    bottomPanel.screen = selectedScreen;
    bottomPanel.floating = true;
    bottomPanel.hiding = "autohide";

    var screenGeom = screenGeometry(selectedScreen);
    var screenWidth = screenGeom.width;
    var leftMargin = Math.floor(screenWidth / 3);
    var rightMargin = Math.floor(screenWidth / 3);

    bottomPanel.minimumLength = screenWidth - leftMargin - rightMargin;
    bottomPanel.maximumLength = screenWidth - leftMargin - rightMargin;
    bottomPanel.offset = leftMargin;

    while (bottomPanel.widgetIds.length > 0)
        bottomPanel.removeWidget(bottomPanel.widgetIds[0]);

    bottomPanel.addWidget("org.kde.plasma.kickoff");            // Application Launcher
    bottomPanel.addWidget("org.kde.plasma.pager");
    bottomPanel.addWidget("org.kde.plasma.icontasks");
    bottomPanel.addWidget("org.kde.plasma.marginsseparator");
    bottomPanel.addWidget("org.kde.plasma.peekatdesktop");
}
