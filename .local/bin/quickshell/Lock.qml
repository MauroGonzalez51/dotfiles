import "../"
import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property color color0: _theme.palette[0]
    readonly property color color1: _theme.palette[1]
    readonly property color color2: _theme.palette[2]
    readonly property color color3: _theme.palette[3]
    readonly property color color4: _theme.palette[4]
    readonly property color color5: _theme.palette[5]
    readonly property color color6: _theme.palette[6]
    readonly property color color7: _theme.palette[7]
    readonly property color color8: _theme.palette[8]
    readonly property color color9: _theme.palette[9]
    readonly property color color10: _theme.palette[10]
    readonly property color color11: _theme.palette[11]
    readonly property color color12: _theme.palette[12]
    readonly property color color13: _theme.palette[13]
    readonly property color color14: _theme.palette[14]
    readonly property color color15: _theme.palette[15]
    readonly property color base: _theme.background
    readonly property color text: _theme.text

    Colors {
        id: _theme
    }

    // Session Settings (Changed from Settings to QtObject to fix the Qt 6.11 initialization error)
    QtObject {
        id: lockSettings

        property bool hidePassword: true
        property int revealDuration: 300
    }

    // Shared state across all monitors
    QtObject {
        id: lockUI

        property bool failed: false
        property bool authenticating: false
        property string statusText: "Locked"
    }

    // Timer to safely decouple PAM execution from the main QML event loop
    Timer {
        id: pamActionTimer

        interval: 50
        onTriggered: pam.start()
    }

    // System Authentication hook
    PamContext {
        id: pam

        // Defer start until after component initialization to prevent memory segfaults
        Component.onCompleted: pamActionTimer.start()
        onCompleted: (result) => {
            lockUI.authenticating = false;
            if (result === PamResult.Success) {
                rootLock.locked = false;
                Qt.quit();
            } else {
                lockUI.failed = true;
                lockUI.statusText = "Access Denied";
                // Defer the restart to prevent a recursive crash loop
                pamActionTimer.start();
            }
        }
    }

    Process {
        id: suspendProcess

        command: ["systemctl", "suspend"]
    }

    Process {
        id: poweroffProcess

        command: ["systemctl", "poweroff"]
    }

    Process {
        id: reloadProcess

        command: ["systemctl", "reboot"]
    }

    WlSessionLock {
        id: rootLock

        locked: true

        WlSessionLockSurface {
            id: surface

            Item {
                id: screenRoot

                readonly property real sc: scaler.baseScale
                property string staticWallpaperPath: "file:///tmp/lock_bg.png"
                property string batPct: "100"
                property string batStatus: "AC"
                property string currentUser: "User"
                property string faceIconPath: ""
                property string kbLayout: "US"
                property string weatherIcon: ""
                property string weatherTemp: "--°C"
                property real introState: 0
                property bool powerMenuOpen: false
                property bool inputActive: false
                property bool isPlayingIntro: true
                property bool isDesktop: false
                property real globalOrbitAngle: 0

                anchors.fill: parent
                Component.onCompleted: {
                    introSequence.start();
                }

                Scaler {
                    id: scaler

                    currentWidth: screenRoot.width > 0 ? screenRoot.width : Screen.width
                }

                Timer {
                    id: idleTimer

                    interval: 15000
                    running: screenRoot.inputActive && inputField.text.length === 0
                    repeat: false
                    onTriggered: screenRoot.inputActive = false
                }

                Process {
                    id: chassisDetector

                    running: true
                    command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            screenRoot.isDesktop = (this.text.trim() === "desktop");
                        }
                    }

                }

                Process {
                    id: userPoller

                    command: ["bash", "-c", "USER_VAR=$(whoami); ICON_PATH=\"\"; if [ -f ~/.face.icon ]; then ICON_PATH=$(readlink -f ~/.face.icon); elif [ -f ~/.face ]; then ICON_PATH=$(readlink -f ~/.face); fi; echo -n \"$USER_VAR|$ICON_PATH\""]
                    Component.onCompleted: running = true

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let parts = this.text.trim().split("|");
                            if (parts.length > 0 && parts[0] !== "")
                                screenRoot.currentUser = parts[0];

                            if (parts.length > 1 && parts[1].trim() !== "") {
                                let path = parts[1].trim();
                                screenRoot.faceIconPath = path.startsWith("file://") ? path : "file://" + path;
                            }
                        }
                    }

                }

                Process {
                    id: kbPoller

                    command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let layout = this.text.trim();
                            if (layout !== "" && layout !== "null")
                                screenRoot.kbLayout = layout;

                        }
                    }

                }

                Timer {
                    interval: 150
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: kbPoller.running = true
                }

                Process {
                    id: batPoller

                    running: !screenRoot.isDesktop
                    command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '100'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'AC'"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n");
                            if (lines.length >= 2) {
                                screenRoot.batPct = lines[0] || "100";
                                screenRoot.batStatus = lines[1] || "Unknown";
                            }
                        }
                    }

                }

                Timer {
                    interval: 5000
                    running: !screenRoot.isDesktop
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: batPoller.running = true
                }

                Timer {
                    interval: 900000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: weatherPoller.running = true
                }

                Rectangle {
                    anchors.fill: parent
                    color: root.base
                }

                Image {
                    id: bgWallpaper

                    anchors.fill: parent
                    source: screenRoot.staticWallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    cache: false
                }

                MultiEffect {
                    source: bgWallpaper
                    anchors.fill: bgWallpaper
                    blurEnabled: true
                    blurMax: 64 * screenRoot.sc
                    blur: 1
                }

                Rectangle {
                    id: dimmer

                    anchors.fill: parent
                    color: "black"
                    opacity: 0.25
                }

                Item {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width * 0.8
                        height: width
                        radius: width / 2
                        x: (parent.width / 2 - width / 2) + Math.cos(screenRoot.globalOrbitAngle * 2) * (200 * screenRoot.sc)
                        y: (parent.height / 2 - height / 2) + Math.sin(screenRoot.globalOrbitAngle * 2) * (150 * screenRoot.sc)
                        scale: 1 + Math.sin(screenRoot.globalOrbitAngle * 6) * 0.05
                        opacity: screenRoot.inputActive ? 0.04 : 0.08
                        color: root.color5

                        Behavior on color {
                            ColorAnimation {
                                duration: 1000
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 600
                            }

                        }

                    }

                    Rectangle {
                        width: parent.width * 0.9
                        height: width
                        radius: width / 2
                        x: (parent.width / 2 - width / 2) + Math.sin(screenRoot.globalOrbitAngle * 1.5) * (-200 * screenRoot.sc)
                        y: (parent.height / 2 - height / 2) + Math.cos(screenRoot.globalOrbitAngle * 1.5) * (-150 * screenRoot.sc)
                        scale: 1 + Math.cos(screenRoot.globalOrbitAngle * 5) * 0.05
                        opacity: screenRoot.inputActive ? 0.03 : 0.06
                        color: root.color4

                        Behavior on color {
                            ColorAnimation {
                                duration: 1000
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 600
                            }

                        }

                    }

                    Item {
                        anchors.fill: parent
                        opacity: screenRoot.introState
                        scale: 1.1 - (0.1 * screenRoot.introState)

                        Repeater {
                            model: 4

                            Rectangle {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -40 * screenRoot.sc
                                width: (400 * screenRoot.sc) + (index * (220 * screenRoot.sc))
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.color: lockUI.failed ? root.color1 : root.text
                                border.width: Math.max(1, 1 * screenRoot.sc)
                                opacity: lockUI.failed ? (0.1 - (index * 0.02)) : (screenRoot.inputActive ? (0.02 - (index * 0.005)) : (0.04 - (index * 0.01)))

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 600
                                        easing.type: Easing.OutExpo
                                    }

                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 600
                                        easing.type: Easing.OutExpo
                                    }

                                }

                            }

                        }

                    }

                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !screenRoot.isPlayingIntro
                    onClicked: {
                        if (screenRoot.powerMenuOpen)
                            screenRoot.powerMenuOpen = false;

                        if (!screenRoot.inputActive)
                            screenRoot.inputActive = true;

                        inputField.forceActiveFocus();
                    }
                }

                Item {
                    anchors.fill: parent
                    opacity: screenRoot.introState

                    ColumnLayout {
                        id: clockModule

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive ? (-120 * screenRoot.sc) : (-40 * screenRoot.sc)
                        spacing: -10 * screenRoot.sc
                        opacity: screenRoot.inputActive ? 0 : 1
                        scale: screenRoot.inputActive ? 0.9 : 1
                        visible: opacity > 0.01

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0

                            Text {
                                id: clockHours

                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 140 * screenRoot.sc
                                font.weight: Font.Bold
                                color: root.text

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                            }

                            Text {
                                text: ":"
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 140 * screenRoot.sc
                                font.weight: Font.Bold
                                opacity: 0.5
                                color: root.text

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                            }

                            Text {
                                id: clockMinutes

                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 140 * screenRoot.sc
                                font.weight: Font.Bold
                                color: root.text

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                            }

                        }

                        Text {
                            id: dateText

                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 22 * screenRoot.sc
                            font.weight: Font.Bold
                            color: root.text
                        }

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            triggeredOnStart: true
                            onTriggered: {
                                let d = new Date();
                                clockHours.text = Qt.formatDateTime(d, "hh");
                                clockMinutes.text = Qt.formatDateTime(d, "mm");
                                dateText.text = Qt.formatDateTime(d, "dddd, MMMM dd");
                            }
                        }

                        Behavior on anchors.verticalCenterOffset {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutBack
                            }

                        }

                    }

                    RowLayout {
                        id: authModule

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive ? (-40 * screenRoot.sc) : (40 * screenRoot.sc)
                        spacing: 32 * screenRoot.sc
                        opacity: screenRoot.inputActive ? 1 : 0
                        scale: screenRoot.inputActive ? 1 : 0.9
                        visible: opacity > 0.01

                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            width: 170 * screenRoot.sc
                            height: width

                            Rectangle {
                                id: avatarMask

                                anchors.fill: parent
                                radius: height / 2
                                color: "black"
                                visible: false
                                layer.enabled: true
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.5)
                                visible: avatarImg.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄽"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 64 * screenRoot.sc
                                    color: root.color7
                                }

                            }

                            Image {
                                id: avatarImg

                                anchors.fill: parent
                                source: screenRoot.faceIconPath !== "" ? screenRoot.faceIconPath : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                                cache: false
                                asynchronous: true
                            }

                            MultiEffect {
                                source: avatarImg
                                anchors.fill: avatarImg
                                maskEnabled: true
                                maskSource: avatarMask
                                visible: avatarImg.status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: "transparent"
                                border.color: lockUI.failed ? root.color1 : (lockUI.authenticating ? root.color3 : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.5))
                                border.width: Math.max(1, 3 * screenRoot.sc)

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                            }

                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 16 * screenRoot.sc

                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text: screenRoot.currentUser
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 28 * screenRoot.sc
                                font.weight: Font.Bold
                                color: root.text
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignLeft
                                spacing: 12 * screenRoot.sc

                                Rectangle {
                                    width: 36 * screenRoot.sc
                                    height: width
                                    radius: height / 2
                                    color: lockUI.failed ? Qt.rgba(root.color1.r, root.color1.g, root.color1.b, 0.2) : (lockUI.authenticating ? Qt.rgba(root.color3.r, root.color3.g, root.color3.b, 0.2) : Qt.rgba(root.color5.r, root.color5.g, root.color5.b, 0.15))
                                    border.color: lockUI.failed ? root.color1 : (lockUI.authenticating ? root.color3 : root.color5)
                                    border.width: Math.max(1, 1 * screenRoot.sc)

                                    Text {
                                        anchors.centerIn: parent
                                        text: lockUI.failed ? "󰌾" : (lockUI.authenticating ? "󰌿" : "󰌾")
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 18 * screenRoot.sc
                                        color: lockUI.failed ? root.color1 : (lockUI.authenticating ? root.color3 : root.color5)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 300
                                            }

                                        }

                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 300
                                        }

                                    }

                                    Behavior on border.color {
                                        ColorAnimation {
                                            duration: 300
                                        }

                                    }

                                }

                                Text {
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 14 * screenRoot.sc
                                    font.weight: Font.Medium
                                    font.letterSpacing: 2
                                    color: lockUI.failed ? root.color1 : (lockUI.authenticating ? root.color3 : root.text)
                                    text: lockUI.statusText.toUpperCase()

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 300
                                        }

                                    }

                                }

                            }

                            Rectangle {
                                id: pinPill

                                Layout.alignment: Qt.AlignLeft
                                width: 280 * screenRoot.sc
                                height: 60 * screenRoot.sc
                                radius: height / 2
                                clip: true
                                color: lockUI.failed ? Qt.rgba(root.color1.r, root.color1.g, root.color1.b, 0.1) : Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.5)
                                border.width: Math.max(1, 2 * screenRoot.sc)
                                border.color: {
                                    if (lockUI.failed)
                                        return root.color1;

                                    if (lockUI.authenticating)
                                        return root.color3;

                                    if (inputField.text.length > 0)
                                        return root.text;

                                    return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08);
                                }
                                scale: lockUI.failed ? 1.05 : (lockUI.authenticating ? 0.98 : 1)

                                SequentialAnimation {
                                    id: shakeAnim

                                    NumberAnimation {
                                        target: shakeTranslate
                                        property: "x"
                                        from: 0
                                        to: -8 * screenRoot.sc
                                        duration: 120
                                        easing.type: Easing.InOutSine
                                    }

                                    NumberAnimation {
                                        target: shakeTranslate
                                        property: "x"
                                        from: -8 * screenRoot.sc
                                        to: 8 * screenRoot.sc
                                        duration: 120
                                        easing.type: Easing.InOutSine
                                    }

                                    NumberAnimation {
                                        target: shakeTranslate
                                        property: "x"
                                        from: 8 * screenRoot.sc
                                        to: 0
                                        duration: 120
                                        easing.type: Easing.InOutSine
                                    }

                                }

                                Connections {
                                    function onFailedChanged() {
                                        if (lockUI.failed)
                                            shakeAnim.restart();

                                    }

                                    target: lockUI
                                }

                                TextInput {
                                    id: inputField

                                    property string oldText: ""

                                    anchors.fill: parent
                                    opacity: 0
                                    echoMode: TextInput.Password
                                    enabled: !screenRoot.isPlayingIntro
                                    Component.onCompleted: forceActiveFocus()
                                    onActiveFocusChanged: {
                                        if (!activeFocus && !screenRoot.powerMenuOpen && !screenRoot.isPlayingIntro)
                                            forceActiveFocus();

                                    }
                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Escape) {
                                            screenRoot.inputActive = false;
                                            text = "";
                                            passModel.clear();
                                            event.accepted = true;
                                        } else if (!screenRoot.inputActive) {
                                            screenRoot.inputActive = true;
                                        }
                                    }
                                    onAccepted: {
                                        if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
                                            lockUI.authenticating = true;
                                            lockUI.statusText = "Authenticating...";
                                            lockUI.failed = false;
                                            pam.respond(text);
                                            text = "";
                                            oldText = "";
                                            passModel.clear();
                                        }
                                    }
                                    onTextChanged: {
                                        if (lockUI.authenticating)
                                            return ;

                                        if (text.length > 0 && !screenRoot.inputActive)
                                            screenRoot.inputActive = true;

                                        idleTimer.restart();
                                        if (text !== oldText) {
                                            if (text.length > oldText.length) {
                                                for (let i = oldText.length; i < text.length; i++) {
                                                    passModel.append({
                                                        "charStr": text.charAt(i),
                                                        "isDot": lockSettings.hidePassword
                                                    });
                                                }
                                            } else if (text.length < oldText.length) {
                                                let diff = oldText.length - text.length;
                                                for (let i = 0; i < diff; i++) {
                                                    passModel.remove(passModel.count - 1);
                                                }
                                            } else {
                                                passModel.clear();
                                                for (let i = 0; i < text.length; i++) {
                                                    passModel.append({
                                                        "charStr": text.charAt(i),
                                                        "isDot": lockSettings.hidePassword
                                                    });
                                                }
                                            }
                                            oldText = text;
                                        }
                                        if (text.length > 0) {
                                            lockUI.failed = false;
                                            lockUI.statusText = "Enter PIN";
                                        } else {
                                            if (!lockUI.failed)
                                                lockUI.statusText = "Locked";

                                        }
                                    }
                                }

                                ListModel {
                                    id: passModel
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20 * screenRoot.sc
                                    anchors.rightMargin: 20 * screenRoot.sc
                                    clip: true

                                    Row {
                                        id: dotRow

                                        anchors.verticalCenter: parent.verticalCenter
                                        x: width > parent.width ? parent.width - width : (parent.width - width) / 2
                                        spacing: 4 * screenRoot.sc

                                        Repeater {
                                            model: passModel

                                            delegate: Text {
                                                text: model.isDot ? "•" : model.charStr
                                                font.family: "JetBrains Mono Nerd Font"
                                                font.pixelSize: model.isDot ? (32 * screenRoot.sc) : (24 * screenRoot.sc)
                                                font.weight: Font.Bold
                                                color: lockUI.failed ? root.color1 : (lockUI.authenticating ? root.color3 : root.text)
                                                verticalAlignment: Text.AlignVCenter
                                                height: pinPill.height

                                                Timer {
                                                    interval: lockSettings.revealDuration
                                                    running: !model.isDot && !lockSettings.hidePassword
                                                    onTriggered: {
                                                        if (index >= 0 && index < passModel.count)
                                                            passModel.setProperty(index, "isDot", true);

                                                    }
                                                }

                                                NumberAnimation on opacity {
                                                    from: 0
                                                    to: 1
                                                    duration: 150
                                                }

                                            }

                                        }

                                        Behavior on x {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutQuad
                                            }

                                        }

                                    }

                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 250
                                        easing.type: Easing.OutExpo
                                    }

                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 250
                                        easing.type: Easing.OutExpo
                                    }

                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutBack
                                    }

                                }

                                transform: Translate {
                                    id: shakeTranslate

                                    x: 0
                                }

                            }

                        }

                        Behavior on anchors.verticalCenterOffset {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }

                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutBack
                            }

                        }

                    }

                    transform: Translate {
                        y: (30 * screenRoot.sc) * (1 - screenRoot.introState)
                    }

                }

                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40 * screenRoot.sc
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16 * screenRoot.sc
                    opacity: screenRoot.introState

                    // KEYBOARD LAYOUT MODULE
                    Rectangle {
                        property bool isHovered: kbMouse.containsMouse

                        Layout.preferredHeight: 48 * screenRoot.sc
                        Layout.preferredWidth: kbLayoutRow.implicitWidth + (36 * screenRoot.sc)
                        radius: height / 2
                        color: isHovered ? Qt.rgba(root.color11.r, root.color11.g, root.color11.b, 0.6) : Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.4)
                        border.color: isHovered ? root.color5 : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        border.width: Math.max(1, 1 * screenRoot.sc)
                        scale: isHovered ? 1.05 : 1

                        RowLayout {
                            id: kbLayoutRow

                            anchors.centerIn: parent
                            spacing: 8 * screenRoot.sc

                            Text {
                                text: "󰌌"
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 18 * screenRoot.sc
                                color: parent.parent.isHovered ? root.color3 : root.color6

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }

                                }

                            }

                            Text {
                                text: screenRoot.kbLayout
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 14 * screenRoot.sc
                                font.weight: Font.Black
                                color: root.text
                            }

                        }

                        MouseArea {
                            id: kbMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !screenRoot.isPlayingIntro
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    // BATTERY MODULE
                    Rectangle {
                        property bool isHovered: batMouse.containsMouse

                        visible: !screenRoot.isDesktop
                        Layout.preferredHeight: 48 * screenRoot.sc
                        Layout.preferredWidth: batLayoutRow.implicitWidth + (36 * screenRoot.sc)
                        radius: height / 2
                        color: isHovered ? Qt.rgba(root.color11.r, root.color11.g, root.color11.b, 0.6) : Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.4)
                        border.color: isHovered ? batLayoutRow.dynamicBatColor : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        border.width: Math.max(1, 1 * screenRoot.sc)
                        scale: isHovered ? 1.05 : 1

                        RowLayout {
                            id: batLayoutRow

                            property color dynamicBatColor: {
                                if (screenRoot.batStatus === "Charging")
                                    return root.color4;

                                let pct = parseInt(screenRoot.batPct);
                                if (pct >= 60)
                                    return root.color4;

                                if (pct >= 25)
                                    return root.color9;

                                return root.color3;
                            }

                            anchors.centerIn: parent
                            spacing: 8 * screenRoot.sc

                            Text {
                                text: screenRoot.batStatus === "Charging" ? "󰂄" : (parseInt(screenRoot.batPct) < 20 ? "󰂃" : "󰁹")
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 20 * screenRoot.sc
                                color: batLayoutRow.dynamicBatColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }

                                }

                            }

                            Text {
                                text: screenRoot.batPct + "%"
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 14 * screenRoot.sc
                                font.weight: Font.Black
                                color: root.text

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }

                                }

                            }

                        }

                        MouseArea {
                            id: batMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !screenRoot.isPlayingIntro
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }

                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    transform: Translate {
                        y: (20 * screenRoot.sc) * (1 - screenRoot.introState)
                    }

                }

                // POWER MENU DROPDOWN
                Rectangle {
                    id: powerMenu

                    anchors.bottom: powerBtn.top
                    anchors.right: parent.right
                    anchors.bottomMargin: 15 * screenRoot.sc
                    anchors.rightMargin: 40 * screenRoot.sc
                    width: 280 * screenRoot.sc
                    height: screenRoot.powerMenuOpen ? (menuLayout.implicitHeight + (20 * screenRoot.sc)) : 0
                    radius: 18 * screenRoot.sc
                    clip: true
                    opacity: screenRoot.powerMenuOpen ? 1 : 0
                    color: Qt.rgba(root.color0.r, root.color0.g, root.color0.b, 0.96)
                    border.color: Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.18)
                    border.width: Math.max(1, 1 * screenRoot.sc)

                    ColumnLayout {
                        id: menuLayout

                        anchors.top: parent.top
                        anchors.topMargin: 10 * screenRoot.sc
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 6 * screenRoot.sc

                        Text {
                            text: "SETTINGS"
                            font.family: "JetBrains Mono Nerd Font"
                            font.weight: Font.Black
                            font.pixelSize: 12 * screenRoot.sc
                            font.letterSpacing: 1.5
                            color: root.color15
                            Layout.leftMargin: 18 * screenRoot.sc
                            Layout.topMargin: 4 * screenRoot.sc
                            Layout.bottomMargin: 4 * screenRoot.sc
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18 * screenRoot.sc
                            Layout.rightMargin: 18 * screenRoot.sc
                            Layout.topMargin: 4 * screenRoot.sc

                            Text {
                                text: "Hide password"
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 14 * screenRoot.sc
                                font.weight: Font.Medium
                                color: root.color15
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 40 * screenRoot.sc
                                height: 22 * screenRoot.sc
                                radius: height / 2
                                color: lockSettings.hidePassword ? root.color4 : root.color8

                                Rectangle {
                                    width: height
                                    height: 18 * screenRoot.sc
                                    radius: height / 2
                                    x: lockSettings.hidePassword ? parent.width - width - (2 * screenRoot.sc) : (2 * screenRoot.sc)
                                    y: (parent.height - height) / 2
                                    color: root.color15

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                        }

                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        lockSettings.hidePassword = !lockSettings.hidePassword;
                                        if (lockSettings.hidePassword) {
                                            for (let i = 0; i < passModel.count; i++) passModel.setProperty(i, "isDot", true)
                                        }
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 250
                                    }

                                }

                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18 * screenRoot.sc
                            Layout.rightMargin: 18 * screenRoot.sc
                            Layout.topMargin: 8 * screenRoot.sc
                            Layout.bottomMargin: 8 * screenRoot.sc
                            spacing: 8 * screenRoot.sc
                            opacity: lockSettings.hidePassword ? 0.3 : 1

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Reveal delay"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 14 * screenRoot.sc
                                    font.weight: Font.Medium
                                    color: root.color15
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: lockSettings.revealDuration >= 1000 ? (lockSettings.revealDuration / 1000).toFixed(1) + " s" : lockSettings.revealDuration + " ms"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 13 * screenRoot.sc
                                    font.weight: Font.Bold
                                    color: root.color8
                                }

                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28 * screenRoot.sc

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 8 * screenRoot.sc
                                    radius: height / 2
                                    color: root.color8

                                    Rectangle {
                                        width: ((lockSettings.revealDuration - 100) / 2900) * parent.width
                                        height: parent.height
                                        radius: height / 2
                                        color: root.color4
                                    }

                                }

                                Rectangle {
                                    id: sliderThumb

                                    width: 20 * screenRoot.sc
                                    height: width
                                    radius: height / 2
                                    color: root.color15
                                    border.color: root.color0
                                    border.width: Math.max(1, 2 * screenRoot.sc)
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(((lockSettings.revealDuration - 100) / 2900) * parent.width - (width / 2), parent.width - width))
                                    scale: sliderMouse.pressed ? 1.3 : (sliderMouse.containsMouse ? 1.15 : 1)

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutBack
                                        }

                                    }

                                }

                                MultiEffect {
                                    source: sliderThumb
                                    anchors.fill: sliderThumb
                                    shadowEnabled: true
                                    shadowBlur: 0.5
                                    shadowColor: "#000000"
                                    shadowOpacity: 0.4
                                    shadowVerticalOffset: 2 * screenRoot.sc
                                }

                                MouseArea {
                                    id: sliderMouse

                                    function updateVal(mouseX) {
                                        let pct = Math.max(0, Math.min(1, mouseX / width));
                                        let ms = Math.round(100 + (pct * 2900));
                                        if (ms % 100 < 10)
                                            ms -= (ms % 100);
                                        else if (ms % 100 > 90)
                                            ms += (100 - (ms % 100));
                                        lockSettings.revealDuration = ms;
                                    }

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !lockSettings.hidePassword
                                    preventStealing: true
                                    onPositionChanged: (mouse) => {
                                        if (pressed)
                                            updateVal(mouse.x);

                                    }
                                    onPressed: (mouse) => {
                                        return updateVal(mouse.x);
                                    }
                                }

                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(1, 1 * screenRoot.sc)
                            color: Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.12)
                            Layout.leftMargin: 18 * screenRoot.sc
                            Layout.rightMargin: 18 * screenRoot.sc
                            Layout.topMargin: 4 * screenRoot.sc
                            Layout.bottomMargin: 4 * screenRoot.sc
                        }

                        Text {
                            text: "SYSTEM"
                            font.family: "JetBrains Mono Nerd Font"
                            font.weight: Font.Black
                            font.pixelSize: 12 * screenRoot.sc
                            font.letterSpacing: 1.5
                            color: root.color15
                            Layout.leftMargin: 18 * screenRoot.sc
                            Layout.bottomMargin: 4 * screenRoot.sc
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48 * screenRoot.sc
                            Layout.leftMargin: 10 * screenRoot.sc
                            Layout.rightMargin: 10 * screenRoot.sc
                            radius: 12 * screenRoot.sc
                            color: ma1.containsMouse ? Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.08) : "transparent"
                            scale: ma1.pressed ? 0.95 : (ma1.containsMouse ? 1.02 : 1)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * screenRoot.sc
                                anchors.rightMargin: 16 * screenRoot.sc
                                spacing: 0

                                Text {
                                    text: "󰜉"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 18 * screenRoot.sc
                                    color: ma1.containsMouse ? root.color15 : Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "Reboot"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 15 * screenRoot.sc
                                    font.weight: Font.Medium
                                    color: ma1.containsMouse ? root.color15 : Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: ma1

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    screenRoot.powerMenuOpen = false;
                                    reloadProcess.running = true;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }

                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48 * screenRoot.sc
                            Layout.leftMargin: 10 * screenRoot.sc
                            Layout.rightMargin: 10 * screenRoot.sc
                            radius: 12 * screenRoot.sc
                            color: ma2.containsMouse ? Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.08) : "transparent"
                            scale: ma2.pressed ? 0.95 : (ma2.containsMouse ? 1.02 : 1)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * screenRoot.sc
                                anchors.rightMargin: 16 * screenRoot.sc
                                spacing: 0

                                Text {
                                    text: "󰒲"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 18 * screenRoot.sc
                                    color: ma2.containsMouse ? root.color15 : Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "Suspend"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 15 * screenRoot.sc
                                    font.weight: Font.Medium
                                    color: ma2.containsMouse ? root.color15 : Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: ma2

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    screenRoot.powerMenuOpen = false;
                                    suspendProcess.running = true;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }

                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48 * screenRoot.sc
                            Layout.leftMargin: 10 * screenRoot.sc
                            Layout.rightMargin: 10 * screenRoot.sc
                            Layout.bottomMargin: 8 * screenRoot.sc
                            radius: 12 * screenRoot.sc
                            color: ma3.containsMouse ? Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.08) : "transparent"
                            scale: ma3.pressed ? 0.95 : (ma3.containsMouse ? 1.02 : 1)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * screenRoot.sc
                                anchors.rightMargin: 16 * screenRoot.sc
                                spacing: 0

                                Text {
                                    text: "󰐥"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 18 * screenRoot.sc
                                    color: ma3.containsMouse ? root.color15 : Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "Power Off"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 15 * screenRoot.sc
                                    font.weight: Font.Medium
                                    color: ma3.containsMouse ? root.color15 : Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: ma3

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    screenRoot.powerMenuOpen = false;
                                    poweroffProcess.running = true;
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }

                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }

                            }

                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutExpo
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }

                    }

                }

                Rectangle {
                    id: powerBtn

                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 40 * screenRoot.sc
                    width: 52 * screenRoot.sc
                    height: width
                    radius: height / 2
                    color: screenRoot.powerMenuOpen ? root.color12 : (powerBtnMa.containsMouse ? Qt.rgba(root.color11.r, root.color11.g, root.color11.b, 0.8) : Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.4))
                    border.color: screenRoot.powerMenuOpen ? root.text : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15)
                    border.width: Math.max(1, 1 * screenRoot.sc)
                    opacity: screenRoot.introState
                    scale: powerBtnMa.pressed ? 0.9 : (powerBtnMa.containsMouse ? 1.08 : 1)

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 22 * screenRoot.sc
                        color: screenRoot.powerMenuOpen ? root.color1 : (powerBtnMa.containsMouse ? root.text : root.color7)

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    MouseArea {
                        id: powerBtnMa

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !screenRoot.isPlayingIntro
                        onClicked: {
                            screenRoot.powerMenuOpen = !screenRoot.powerMenuOpen;
                            if (!screenRoot.powerMenuOpen)
                                inputField.forceActiveFocus();

                        }
                    }

                    transform: Translate {
                        y: (20 * screenRoot.sc) * (1 - screenRoot.introState)
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }

                    }

                }

                Item {
                    id: introOverlay

                    anchors.fill: parent
                    z: 999
                    visible: screenRoot.isPlayingIntro || opacity > 0

                    Rectangle {
                        id: ring3

                        width: 360 * screenRoot.sc
                        height: width
                        radius: height / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: root.color5
                        border.width: Math.max(1, 1 * screenRoot.sc)
                        scale: 0.5
                        opacity: 0
                    }

                    Rectangle {
                        id: ring2

                        width: 300 * screenRoot.sc
                        height: width
                        radius: height / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: root.text
                        border.width: Math.max(1, 1 * screenRoot.sc)
                        scale: 0.8
                        opacity: 0
                    }

                    Rectangle {
                        id: ring1

                        width: 240 * screenRoot.sc
                        height: width
                        radius: height / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: root.text
                        border.width: Math.max(1, 2 * screenRoot.sc)
                        scale: 0.8
                        opacity: 0
                    }

                    Item {
                        id: introLockOrb

                        width: 170 * screenRoot.sc
                        height: width
                        anchors.centerIn: parent
                        scale: 0
                        opacity: 0

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.9)
                            border.color: root.text
                            border.width: Math.max(1, 2 * screenRoot.sc)
                        }

                        Text {
                            id: introIconUnlocked

                            anchors.centerIn: parent
                            text: "󰌿"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 64 * screenRoot.sc
                            color: root.text
                            opacity: 1
                            scale: 1
                            transformOrigin: Item.Center
                        }

                        Text {
                            id: introIconLocked

                            anchors.centerIn: parent
                            text: "󰌾"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 64 * screenRoot.sc
                            color: root.text
                            opacity: 0
                            scale: 1.6
                            transformOrigin: Item.Center
                        }

                    }

                    SequentialAnimation {
                        id: introSequence

                        ParallelAnimation {
                            NumberAnimation {
                                target: introLockOrb
                                property: "scale"
                                from: 0
                                to: 1
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: introLockOrb
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring1
                                property: "scale"
                                from: 0.8
                                to: 1.25
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring1
                                property: "opacity"
                                from: 0.6
                                to: 0
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring2
                                property: "scale"
                                from: 0.8
                                to: 1.4
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring2
                                property: "opacity"
                                from: 0.4
                                to: 0
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring3
                                property: "scale"
                                from: 0.5
                                to: 1.5
                                duration: 350
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring3
                                property: "opacity"
                                from: 0.3
                                to: 0
                                duration: 350
                                easing.type: Easing.OutCubic
                            }

                            SequentialAnimation {
                                PauseAnimation {
                                    duration: 300
                                }

                                ParallelAnimation {
                                    NumberAnimation {
                                        target: introIconUnlocked
                                        property: "scale"
                                        from: 1
                                        to: 0.5
                                        duration: 100
                                        easing.type: Easing.InCubic
                                    }

                                    NumberAnimation {
                                        target: introIconUnlocked
                                        property: "opacity"
                                        from: 1
                                        to: 0
                                        duration: 50
                                    }

                                    NumberAnimation {
                                        target: introIconLocked
                                        property: "scale"
                                        from: 1.6
                                        to: 1
                                        duration: 200
                                        easing.type: Easing.OutBack
                                    }

                                    NumberAnimation {
                                        target: introIconLocked
                                        property: "opacity"
                                        from: 0
                                        to: 1
                                        duration: 100
                                    }

                                    SequentialAnimation {
                                        NumberAnimation {
                                            target: introLockOrb
                                            property: "anchors.verticalCenterOffset"
                                            from: 0
                                            to: 3 * screenRoot.sc
                                            duration: 40
                                            easing.type: Easing.OutQuad
                                        }

                                        NumberAnimation {
                                            target: introLockOrb
                                            property: "anchors.verticalCenterOffset"
                                            from: 3 * screenRoot.sc
                                            to: 0
                                            duration: 120
                                            easing.type: Easing.OutBack
                                        }

                                    }

                                }

                            }

                        }

                        PauseAnimation {
                            duration: 50
                        }

                        SequentialAnimation {
                            ParallelAnimation {
                                NumberAnimation {
                                    target: introLockOrb
                                    property: "scale"
                                    to: 1.8
                                    duration: 100
                                    easing.type: Easing.InCubic
                                }

                                NumberAnimation {
                                    target: introOverlay
                                    property: "opacity"
                                    to: 0
                                    duration: 100
                                    easing.type: Easing.InCubic
                                }

                            }

                            NumberAnimation {
                                target: screenRoot
                                property: "introState"
                                from: 0
                                to: 1
                                duration: 100
                                easing.type: Easing.OutCubic
                            }

                        }

                        PropertyAction {
                            target: screenRoot
                            property: "isPlayingIntro"
                            value: false
                        }

                        ScriptAction {
                            script: {
                                inputField.text = "";
                                inputField.forceActiveFocus();
                            }
                        }

                    }

                }

                NumberAnimation on globalOrbitAngle {
                    from: 0
                    to: Math.PI * 2
                    duration: 90000
                    loops: Animation.Infinite
                    running: true
                }

            }

        }

    }

}
