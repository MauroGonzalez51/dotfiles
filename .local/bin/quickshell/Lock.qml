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

    readonly property color color0: theme.palette[0]
    readonly property color color1: theme.palette[1]
    readonly property color color2: theme.palette[2]
    readonly property color color3: theme.palette[3]
    readonly property color color4: theme.palette[4]
    readonly property color color5: theme.palette[5]
    readonly property color color6: theme.palette[6]
    readonly property color color7: theme.palette[7]
    readonly property color color8: theme.palette[8]
    readonly property color color9: theme.palette[9]
    readonly property color color10: theme.palette[10]
    readonly property color color11: theme.palette[11]
    readonly property color color12: theme.palette[12]
    readonly property color color13: theme.palette[13]
    readonly property color color14: theme.palette[14]
    readonly property color color15: theme.palette[15]
    readonly property color base: theme.background
    readonly property color text: theme.text

    Colors {
        id: theme
    }

    // Session Settings (Changed from Settings to QtObject to fix the Qt 6.11 initialization error)
    QtObject {
        id: lock_settings

        property bool hide_password: true
        property int reveal_duration: 300
    }

    // Shared state across all monitors
    QtObject {
        id: lock_ui

        property bool failed: false
        property bool authenticating: false
        property string status_text: "Locked"
    }

    // Timer to safely decouple PAM execution from the main QML event loop
    Timer {
        id: pam_action_timer

        interval: 50
        onTriggered: pam_context.start()
    }

    // System Authentication hook
    PamContext {
        id: pam_context

        // Defer start until after component initialization to prevent memory segfaults
        Component.onCompleted: pam_action_timer.start()
        onCompleted: (result) => {
            lock_ui.authenticating = false;
            if (result === PamResult.Success) {
                root_lock.locked = false;
                Qt.quit();
            } else {
                lock_ui.failed = true;
                lock_ui.status_text = "Access Denied";
                // Defer the restart to prevent a recursive crash loop
                pam_action_timer.start();
            }
        }
    }

    Process {
        id: suspend_process

        command: ["systemctl", "suspend"]
    }

    Process {
        id: poweroff_process

        command: ["systemctl", "poweroff"]
    }

    Process {
        id: reload_process

        command: ["systemctl", "reboot"]
    }

    WlSessionLock {
        id: root_lock

        locked: true

        WlSessionLockSurface {
            id: lock_surface

            Item {
                id: screen_root

                readonly property real sc: ui_scaler.baseScale
                property string static_wallpaper_path: "file:///tmp/lock_bg.png"
                property string bat_pct: "100"
                property string bat_status: "AC"
                property string current_user: "User"
                property string face_icon_path: ""
                property string kb_layout: "US"
                property string weather_icon: ""
                property string weather_temp: "--°C"
                property real intro_state: 0
                property bool power_menu_open: false
                property bool input_active: false
                property bool is_playing_intro: true
                property bool is_desktop: false
                property real global_orbit_angle: 0

                anchors.fill: parent
                Component.onCompleted: {
                    intro_sequence.start();
                }

                Scaler {
                    id: ui_scaler

                    currentWidth: {
                        if (screen_root.width > 0) return screen_root.width;
                        return Screen.width;
                    }
                }

                Timer {
                    id: idle_timer

                    interval: 15000
                    running: screen_root.input_active && input_field.text.length === 0
                    repeat: false
                    onTriggered: screen_root.input_active = false
                }

                Process {
                    id: chassis_detector

                    running: true
                    command: ["bash", "-c", "if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then echo 'laptop'; else echo 'desktop'; fi"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            screen_root.is_desktop = (this.text.trim() === "desktop");
                        }
                    }

                }

                Process {
                    id: user_poller

                    command: ["bash", "-c", "USER_VAR=$(whoami); ICON_PATH=\"\"; if [ -f ~/.face.icon ]; then ICON_PATH=$(readlink -f ~/.face.icon); elif [ -f ~/.face ]; then ICON_PATH=$(readlink -f ~/.face); fi; echo -n \"$USER_VAR|$ICON_PATH\""]
                    Component.onCompleted: running = true

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let parts = this.text.trim().split("|");
                            if (parts.length > 0 && parts[0] !== "")
                                screen_root.current_user = parts[0];

                            if (parts.length > 1 && parts[1].trim() !== "") {
                                let path = parts[1].trim();
                                if (path.startsWith("file://")) {
                                    screen_root.face_icon_path = path;
                                } else {
                                    screen_root.face_icon_path = "file://" + path;
                                }
                            }
                        }
                    }

                }

                Process {
                    id: kb_poller

                    command: ["bash", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let layout = this.text.trim();
                            if (layout !== "" && layout !== "null")
                                screen_root.kb_layout = layout;

                        }
                    }

                }

                Timer {
                    interval: 150
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: kb_poller.running = true
                }

                Process {
                    id: bat_poller

                    running: !screen_root.is_desktop
                    command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '100'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'AC'"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n");
                            if (lines.length >= 2) {
                                screen_root.bat_pct = lines[0] || "100";
                                screen_root.bat_status = lines[1] || "Unknown";
                            }
                        }
                    }

                }

                Timer {
                    interval: 5000
                    running: !screen_root.is_desktop
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: bat_poller.running = true
                }

                Timer {
                    interval: 900000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: weather_poller.running = true
                }

                Rectangle {
                    // [CHANGE WALLPAPER]
                    anchors.fill: parent
                    color: root.base
                }

                Image {
                    id: bg_wallpaper

                    anchors.fill: parent
                    source: screen_root.static_wallpaper_path
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    cache: false
                }

                MultiEffect {
                    source: bg_wallpaper
                    anchors.fill: bg_wallpaper
                    blurEnabled: true
                    blurMax: 64 * screen_root.sc
                    blur: 1
                }

                Rectangle {
                    id: dimmer_rect

                    anchors.fill: parent
                    // [CHANGE-COLOR]
                    color: root.color0
                    opacity: 0.2
                }

                Item {
                    anchors.fill: parent

                    Rectangle {
                        width: parent.width * 0.8
                        height: width
                        radius: width / 2
                        x: (parent.width / 2 - width / 2) + Math.cos(screen_root.global_orbit_angle * 2) * (200 * screen_root.sc)
                        y: (parent.height / 2 - height / 2) + Math.sin(screen_root.global_orbit_angle * 2) * (150 * screen_root.sc)
                        scale: 1 + Math.sin(screen_root.global_orbit_angle * 6) * 0.05
                        // [OPACITY]
                        opacity: {
                            if (screen_root.input_active) return 0.15;
                            return 0.30;
                        }
                        // [CHANGE-COLOR]
                        color: root.color6

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
                        x: (parent.width / 2 - width / 2) + Math.sin(screen_root.global_orbit_angle * 1.5) * (-200 * screen_root.sc)
                        y: (parent.height / 2 - height / 2) + Math.cos(screen_root.global_orbit_angle * 1.5) * (-150 * screen_root.sc)
                        scale: 1 + Math.cos(screen_root.global_orbit_angle * 5) * 0.05
                        // [CHANGE-OPACITY]
                        opacity: {
                            if (screen_root.input_active) return 0.10;
                            return 0.25;
                        }
                        // [CHANGE-COLOR]
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
                        opacity: screen_root.intro_state
                        scale: 1.1 - (0.1 * screen_root.intro_state)

                        Repeater {
                            model: 4

                            Rectangle {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -40 * screen_root.sc
                                width: (400 * screen_root.sc) + (index * (220 * screen_root.sc))
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.color: {
                                    if (lock_ui.failed) return root.color1;
                                    return root.text;
                                }
                                border.width: Math.max(1, 1 * screen_root.sc)
                                opacity: {
                                    if (lock_ui.failed) return 0.1 - (index * 0.02);
                                    if (screen_root.input_active) return 0.02 - (index * 0.005);
                                    return 0.04 - (index * 0.01);
                                }

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
                    enabled: !screen_root.is_playing_intro
                    onClicked: {
                        if (screen_root.power_menu_open)
                            screen_root.power_menu_open = false;

                        if (!screen_root.input_active)
                            screen_root.input_active = true;

                        input_field.forceActiveFocus();
                    }
                }

                Item {
                    anchors.fill: parent
                    opacity: screen_root.intro_state

                    ColumnLayout {
                        id: clock_module

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: {
                            if (screen_root.input_active) return -120 * screen_root.sc;
                            return -40 * screen_root.sc;
                        }
                        spacing: -10 * screen_root.sc
                        opacity: {
                            if (screen_root.input_active) return 0;
                            return 1;
                        }
                        scale: {
                            if (screen_root.input_active) return 0.9;
                            return 1;
                        }
                        visible: opacity > 0.01

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0

                            Text {
                                id: clock_hours

                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 140 * screen_root.sc
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
                                font.pixelSize: 140 * screen_root.sc
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
                                id: clock_minutes

                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 140 * screen_root.sc
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
                            id: date_text

                            Layout.alignment: Qt.AlignHCenter
                            font.family: "JetBrains Mono Nerd Font"
                            font.pixelSize: 22 * screen_root.sc
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
                                clock_hours.text = Qt.formatDateTime(d, "hh");
                                clock_minutes.text = Qt.formatDateTime(d, "mm");
                                date_text.text = Qt.formatDateTime(d, "dddd, MMMM dd");
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
                        id: auth_module

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: {
                            if (screen_root.input_active) return -40 * screen_root.sc;
                            return 40 * screen_root.sc;
                        }
                        spacing: 32 * screen_root.sc
                        opacity: {
                            if (screen_root.input_active) return 1;
                            return 0;
                        }
                        scale: {
                            if (screen_root.input_active) return 1;
                            return 0.9;
                        }
                        visible: opacity > 0.01

                        Item {
                            Layout.alignment: Qt.AlignVCenter
                            width: 170 * screen_root.sc
                            height: width

                            Rectangle {
                                id: avatar_mask

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
                                visible: avatar_img.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄽"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 64 * screen_root.sc
                                    color: root.color7
                                }

                            }

                            Image {
                                id: avatar_img

                                anchors.fill: parent
                                source: {
                                    if (screen_root.face_icon_path !== "") return screen_root.face_icon_path;
                                    return "";
                                }
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                                cache: false
                                asynchronous: true
                            }

                            MultiEffect {
                                source: avatar_img
                                anchors.fill: avatar_img
                                maskEnabled: true
                                maskSource: avatar_mask
                                visible: avatar_img.status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: "transparent"
                                border.color: {
                                    if (lock_ui.failed) return root.color1;
                                    if (lock_ui.authenticating) return root.color3;
                                    return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.5);
                                }
                                border.width: Math.max(1, 3 * screen_root.sc)

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                            }

                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 16 * screen_root.sc

                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text: screen_root.current_user
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 28 * screen_root.sc
                                font.weight: Font.Bold
                                color: root.text
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignLeft
                                spacing: 12 * screen_root.sc

                                Rectangle {
                                    width: 36 * screen_root.sc
                                    height: width
                                    radius: height / 2
                                    color: {
                                        if (lock_ui.failed) return Qt.rgba(root.color1.r, root.color1.g, root.color1.b, 0.2);
                                        if (lock_ui.authenticating) return Qt.rgba(root.color3.r, root.color3.g, root.color3.b, 0.2);
                                        return Qt.rgba(root.color5.r, root.color5.g, root.color5.b, 0.15);
                                    }
                                    border.color: {
                                        if (lock_ui.failed) return root.color1;
                                        if (lock_ui.authenticating) return root.color3;
                                        return root.color5;
                                    }
                                    border.width: Math.max(1, 1 * screen_root.sc)

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (lock_ui.failed) return "󰌾";
                                            if (lock_ui.authenticating) return "󰌿";
                                            return "󰌾";
                                        }
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 18 * screen_root.sc
                                        color: {
                                            if (lock_ui.failed) return root.color1;
                                            if (lock_ui.authenticating) return root.color3;
                                            return root.color5;
                                        }

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
                                    font.pixelSize: 14 * screen_root.sc
                                    font.weight: Font.Medium
                                    font.letterSpacing: 2
                                    color: {
                                                    if (lock_ui.failed) return root.color1;
                                                    if (lock_ui.authenticating) return root.color3;
                                                    return root.text;
                                                }
                                    text: lock_ui.status_text.toUpperCase()

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 300
                                        }

                                    }

                                }

                            }

                            Rectangle {
                                id: pin_pill

                                Layout.alignment: Qt.AlignLeft
                                width: 280 * screen_root.sc
                                height: 60 * screen_root.sc
                                radius: height / 2
                                clip: true
                                color: {
                                    if (lock_ui.failed) return Qt.rgba(root.color1.r, root.color1.g, root.color1.b, 0.1);
                                    return Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.5);
                                }
                                border.width: Math.max(1, 2 * screen_root.sc)
                                border.color: {
                                    if (lock_ui.failed)
                                        return root.color1;

                                    if (lock_ui.authenticating)
                                        return root.color3;

                                    if (input_field.text.length > 0)
                                        return root.text;

                                    return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08);
                                }
                                scale: {
                                    if (lock_ui.failed) return 1.05;
                                    if (lock_ui.authenticating) return 0.98;
                                    return 1;
                                }

                                SequentialAnimation {
                                    id: shake_anim

                                    NumberAnimation {
                                        target: shake_translate
                                        property: "x"
                                        from: 0
                                        to: -8 * screen_root.sc
                                        duration: 120
                                        easing.type: Easing.InOutSine
                                    }

                                    NumberAnimation {
                                        target: shake_translate
                                        property: "x"
                                        from: -8 * screen_root.sc
                                        to: 8 * screen_root.sc
                                        duration: 120
                                        easing.type: Easing.InOutSine
                                    }

                                    NumberAnimation {
                                        target: shake_translate
                                        property: "x"
                                        from: 8 * screen_root.sc
                                        to: 0
                                        duration: 120
                                        easing.type: Easing.InOutSine
                                    }

                                }

                                Connections {
                                    function onFailedChanged() {
                                        if (lock_ui.failed)
                                            shake_anim.restart();

                                    }

                                    target: lock_ui
                                }

                                TextInput {
                                    id: input_field

                                    property string old_text: ""

                                    anchors.fill: parent
                                    opacity: 0
                                    echoMode: TextInput.Password
                                    enabled: !screen_root.is_playing_intro
                                    Component.onCompleted: forceActiveFocus()
                                    onActiveFocusChanged: {
                                        if (!activeFocus && !screen_root.power_menu_open && !screen_root.is_playing_intro)
                                            forceActiveFocus();

                                    }
                                    Keys.onPressed: (event) => {
                                        if (event.key === Qt.Key_Escape) {
                                            screen_root.input_active = false;
                                            text = "";
                                            pass_model.clear();
                                            event.accepted = true;
                                        } else if (!screen_root.input_active) {
                                            screen_root.input_active = true;
                                        }
                                    }
                                    onAccepted: {
                                        if (text.length > 0 && pam_context.responseRequired && !lock_ui.authenticating) {
                                            lock_ui.authenticating = true;
                                            lock_ui.status_text = "Authenticating...";
                                            lock_ui.failed = false;
                                            pam_context.respond(text);
                                            text = "";
                                            old_text = "";
                                            pass_model.clear();
                                        }
                                    }
                                    onTextChanged: {
                                        if (lock_ui.authenticating)
                                            return ;

                                        if (text.length > 0 && !screen_root.input_active)
                                            screen_root.input_active = true;

                                        idle_timer.restart();
                                        if (text !== old_text) {
                                            if (text.length > old_text.length) {
                                                for (let i = old_text.length; i < text.length; i++) {
                                                    pass_model.append({
                                                        "char_str": text.charAt(i),
                                                        "is_dot": lock_settings.hide_password
                                                    });
                                                }
                                            } else if (text.length < old_text.length) {
                                                let diff = old_text.length - text.length;
                                                for (let i = 0; i < diff; i++) {
                                                    pass_model.remove(pass_model.count - 1);
                                                }
                                            } else {
                                                pass_model.clear();
                                                for (let i = 0; i < text.length; i++) {
                                                    pass_model.append({
                                                        "char_str": text.charAt(i),
                                                        "is_dot": lock_settings.hide_password
                                                    });
                                                }
                                            }
                                            old_text = text;
                                        }
                                        if (text.length > 0) {
                                            lock_ui.failed = false;
                                            lock_ui.status_text = "Enter PIN";
                                        } else {
                                            if (!lock_ui.failed)
                                                lock_ui.status_text = "Locked";

                                        }
                                    }
                                }

                                ListModel {
                                    id: pass_model
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20 * screen_root.sc
                                    anchors.rightMargin: 20 * screen_root.sc
                                    clip: true

                                    Row {
                                        id: dot_row

                                        anchors.verticalCenter: parent.verticalCenter
                                        x: {
                                            if (width > parent.width) return parent.width - width;
                                            return (parent.width - width) / 2;
                                        }
                                        spacing: 4 * screen_root.sc

                                        Repeater {
                                            model: pass_model

                                            delegate: Text {
                                                text: {
                                                    if (model.is_dot) return "•";
                                                    return model.char_str;
                                                }
                                                font.family: "JetBrains Mono Nerd Font"
                                                font.pixelSize: {
                                                    if (model.is_dot) return 32 * screen_root.sc;
                                                    return 24 * screen_root.sc;
                                                }
                                                font.weight: Font.Bold
                                                color: {
                                                    if (lock_ui.failed) return root.color1;
                                                    if (lock_ui.authenticating) return root.color3;
                                                    return root.text;
                                                }
                                                verticalAlignment: Text.AlignVCenter
                                                height: pin_pill.height

                                                Timer {
                                                    interval: lock_settings.reveal_duration
                                                    running: !model.is_dot && !lock_settings.hide_password
                                                    onTriggered: {
                                                        if (index >= 0 && index < pass_model.count)
                                                            pass_model.setProperty(index, "is_dot", true);

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
                                    id: shake_translate

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
                        y: (30 * screen_root.sc) * (1 - screen_root.intro_state)
                    }

                }

                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40 * screen_root.sc
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16 * screen_root.sc
                    opacity: screen_root.intro_state

                    // KEYBOARD LAYOUT MODULE
                    Rectangle {
                        property bool is_hovered: kb_mouse.containsMouse

                        Layout.preferredHeight: 48 * screen_root.sc
                        Layout.preferredWidth: kb_layout_row.implicitWidth + (36 * screen_root.sc)
                        radius: height / 2
                        color: {
                            if (is_hovered) return Qt.rgba(root.color11.r, root.color11.g, root.color11.b, 0.8);
                            return Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.4);
                        }
                        border.color: {
                            if (is_hovered) return root.color5;
                            return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08);
                        }
                        border.width: Math.max(1, 1 * screen_root.sc)
                        scale: {
                            if (is_hovered) return 1.05;
                            return 1;
                        }

                        RowLayout {
                            id: kb_layout_row

                            anchors.centerIn: parent
                            spacing: 8 * screen_root.sc

                            Text {
                                text: "󰌌"
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 18 * screen_root.sc
                                color: {
                                    if (parent.parent.is_hovered) return root.color3;
                                    return root.color6;
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }

                                }

                            }

                            Text {
                                text: screen_root.kb_layout
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 14 * screen_root.sc
                                font.weight: Font.Black
                                color: root.text
                            }

                        }

                        MouseArea {
                            id: kb_mouse

                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !screen_root.is_playing_intro
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
                        property bool is_hovered: bat_mouse.containsMouse

                        visible: !screen_root.is_desktop
                        Layout.preferredHeight: 48 * screen_root.sc
                        Layout.preferredWidth: bat_layout_row.implicitWidth + (36 * screen_root.sc)
                        radius: height / 2
                        color: {
                            if (is_hovered) return Qt.rgba(root.color11.r, root.color11.g, root.color11.b, 0.6);
                            return Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.4);
                        }
                        border.color: {
                            if (is_hovered) return bat_layout_row.dynamic_bat_color;
                            return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08);
                        }
                        border.width: Math.max(1, 1 * screen_root.sc)
                        scale: {
                            if (is_hovered) return 1.05;
                            return 1;
                        }

                        RowLayout {
                            id: bat_layout_row

                            property color dynamic_bat_color: {
                                if (screen_root.bat_status === "Charging")
                                    return root.color4;

                                let pct = parseInt(screen_root.bat_pct);
                                if (pct >= 60)
                                    return root.color4;

                                if (pct >= 25)
                                    return root.color9;

                                return root.color3;
                            }

                            anchors.centerIn: parent
                            spacing: 8 * screen_root.sc

                            Text {
                                text: {
                                    if (screen_root.bat_status === "Charging") return "󰂄";
                                    if (parseInt(screen_root.bat_pct) < 20) return "󰂃";
                                    return "󰁹";
                                }
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 20 * screen_root.sc
                                color: bat_layout_row.dynamic_bat_color

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }

                                }

                            }

                            Text {
                                text: screen_root.bat_pct + "%"
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 14 * screen_root.sc
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
                            id: bat_mouse

                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !screen_root.is_playing_intro
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
                        y: (20 * screen_root.sc) * (1 - screen_root.intro_state)
                    }

                }

                // POWER MENU DROPDOWN
                Rectangle {
                    id: power_menu

                    anchors.bottom: power_btn.top
                    anchors.right: parent.right
                    anchors.bottomMargin: 15 * screen_root.sc
                    anchors.rightMargin: 40 * screen_root.sc
                    width: 280 * screen_root.sc
                    height: {
                        if (screen_root.power_menu_open) return menu_layout.implicitHeight + (20 * screen_root.sc);
                        return 0;
                    }
                    radius: 18 * screen_root.sc
                    clip: true
                    opacity: {
                        if (screen_root.power_menu_open) return 1;
                        return 0;
                    }
                    color: Qt.rgba(root.color0.r, root.color0.g, root.color0.b, 0.96)
                    border.color: Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.18)
                    border.width: Math.max(1, 1 * screen_root.sc)

                    ColumnLayout {
                        id: menu_layout

                        anchors.top: parent.top
                        anchors.topMargin: 10 * screen_root.sc
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 6 * screen_root.sc

                        Text {
                            text: "SETTINGS"
                            font.family: "JetBrains Mono Nerd Font"
                            font.weight: Font.Black
                            font.pixelSize: 12 * screen_root.sc
                            font.letterSpacing: 1.5
                            color: root.color15
                            Layout.leftMargin: 18 * screen_root.sc
                            Layout.topMargin: 4 * screen_root.sc
                            Layout.bottomMargin: 4 * screen_root.sc
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18 * screen_root.sc
                            Layout.rightMargin: 18 * screen_root.sc
                            Layout.topMargin: 4 * screen_root.sc

                            Text {
                                text: "Hide password"
                                font.family: "JetBrains Mono Nerd Font"
                                font.pixelSize: 14 * screen_root.sc
                                font.weight: Font.Medium
                                color: root.color15
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 40 * screen_root.sc
                                height: 22 * screen_root.sc
                                radius: height / 2
                                color: {
                                    if (lock_settings.hide_password) return root.color4;
                                    return root.color8;
                                }

                                Rectangle {
                                    width: height
                                    height: 18 * screen_root.sc
                                    radius: height / 2
                                    x: {
                                        if (lock_settings.hide_password) return parent.width - width - (2 * screen_root.sc);
                                        return 2 * screen_root.sc;
                                    }
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
                                        lock_settings.hide_password = !lock_settings.hide_password;
                                        if (lock_settings.hide_password) {
                                            for (let i = 0; i < pass_model.count; i++) pass_model.setProperty(i, "is_dot", true)
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
                            Layout.leftMargin: 18 * screen_root.sc
                            Layout.rightMargin: 18 * screen_root.sc
                            Layout.topMargin: 8 * screen_root.sc
                            Layout.bottomMargin: 8 * screen_root.sc
                            spacing: 8 * screen_root.sc
                            opacity: {
                                if (lock_settings.hide_password) return 0.3;
                                return 1;
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Reveal delay"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 14 * screen_root.sc
                                    font.weight: Font.Medium
                                    color: root.color15
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: {
                                        if (lock_settings.reveal_duration >= 1000) return (lock_settings.reveal_duration / 1000).toFixed(1) + " s";
                                        return lock_settings.reveal_duration + " ms";
                                    }
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 13 * screen_root.sc
                                    font.weight: Font.Bold
                                    color: root.color8
                                }

                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28 * screen_root.sc

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 8 * screen_root.sc
                                    radius: height / 2
                                    color: root.color8

                                    Rectangle {
                                        width: ((lock_settings.reveal_duration - 100) / 2900) * parent.width
                                        height: parent.height
                                        radius: height / 2
                                        color: root.color4
                                    }

                                }

                                Rectangle {
                                    id: slider_thumb

                                    width: 20 * screen_root.sc
                                    height: width
                                    radius: height / 2
                                    color: root.color15
                                    border.color: root.color0
                                    border.width: Math.max(1, 2 * screen_root.sc)
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(((lock_settings.reveal_duration - 100) / 2900) * parent.width - (width / 2), parent.width - width))
                                    scale: {
                                        if (slider_mouse.pressed) return 1.3;
                                        if (slider_mouse.containsMouse) return 1.15;
                                        return 1;
                                    }

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutBack
                                        }

                                    }

                                }

                                MultiEffect {
                                    source: slider_thumb
                                    anchors.fill: slider_thumb
                                    shadowEnabled: true
                                    shadowBlur: 0.5
                                    shadowColor: "#000000"
                                    shadowOpacity: 0.4
                                    shadowVerticalOffset: 2 * screen_root.sc
                                }

                                MouseArea {
                                    id: slider_mouse

                                    function updateVal(mouseX) {
                                        let pct = Math.max(0, Math.min(1, mouseX / width));
                                        let ms = Math.round(100 + (pct * 2900));
                                        if (ms % 100 < 10)
                                            ms -= (ms % 100);
                                        else if (ms % 100 > 90)
                                            ms += (100 - (ms % 100));
                                        lock_settings.reveal_duration = ms;
                                    }

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !lock_settings.hide_password
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
                            Layout.preferredHeight: Math.max(1, 1 * screen_root.sc)
                            color: Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.12)
                            Layout.leftMargin: 18 * screen_root.sc
                            Layout.rightMargin: 18 * screen_root.sc
                            Layout.topMargin: 4 * screen_root.sc
                            Layout.bottomMargin: 4 * screen_root.sc
                        }

                        Text {
                            text: "SYSTEM"
                            font.family: "JetBrains Mono Nerd Font"
                            font.weight: Font.Black
                            font.pixelSize: 12 * screen_root.sc
                            font.letterSpacing: 1.5
                            color: root.color15
                            Layout.leftMargin: 18 * screen_root.sc
                            Layout.bottomMargin: 4 * screen_root.sc
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48 * screen_root.sc
                            Layout.leftMargin: 10 * screen_root.sc
                            Layout.rightMargin: 10 * screen_root.sc
                            radius: 12 * screen_root.sc
                            color: {
                                if (reboot_mouse_area.containsMouse) return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.08);
                                return "transparent";
                            }
                            scale: {
                                if (reboot_mouse_area.pressed) return 0.95;
                                if (reboot_mouse_area.containsMouse) return 1.02;
                                return 1;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * screen_root.sc
                                anchors.rightMargin: 16 * screen_root.sc
                                spacing: 0

                                Text {
                                    text: "󰜉"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 18 * screen_root.sc
                                    color: {
                                            if (reboot_mouse_area.containsMouse) return root.color15;
                                            return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75);
                                        }

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
                                    font.pixelSize: 15 * screen_root.sc
                                    font.weight: Font.Medium
                                    color: {
                                            if (reboot_mouse_area.containsMouse) return root.color15;
                                            return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75);
                                        }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: reboot_mouse_area

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    screen_root.power_menu_open = false;
                                    reload_process.running = true;
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
                            Layout.preferredHeight: 48 * screen_root.sc
                            Layout.leftMargin: 10 * screen_root.sc
                            Layout.rightMargin: 10 * screen_root.sc
                            radius: 12 * screen_root.sc
                            color: {
                                if (suspend_mouse_area.containsMouse) return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.08);
                                return "transparent";
                            }
                            scale: {
                                if (suspend_mouse_area.pressed) return 0.95;
                                if (suspend_mouse_area.containsMouse) return 1.02;
                                return 1;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * screen_root.sc
                                anchors.rightMargin: 16 * screen_root.sc
                                spacing: 0

                                Text {
                                    text: "󰒲"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 18 * screen_root.sc
                                    color: {
                                            if (suspend_mouse_area.containsMouse) return root.color15;
                                            return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75);
                                        }

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
                                    font.pixelSize: 15 * screen_root.sc
                                    font.weight: Font.Medium
                                    color: {
                                            if (suspend_mouse_area.containsMouse) return root.color15;
                                            return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75);
                                        }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: suspend_mouse_area

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    screen_root.power_menu_open = false;
                                    suspend_process.running = true;
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
                            Layout.preferredHeight: 48 * screen_root.sc
                            Layout.leftMargin: 10 * screen_root.sc
                            Layout.rightMargin: 10 * screen_root.sc
                            Layout.bottomMargin: 8 * screen_root.sc
                            radius: 12 * screen_root.sc
                            color: {
                                if (poweroff_mouse_area.containsMouse) return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.08);
                                return "transparent";
                            }
                            scale: {
                                if (poweroff_mouse_area.pressed) return 0.95;
                                if (poweroff_mouse_area.containsMouse) return 1.02;
                                return 1;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16 * screen_root.sc
                                anchors.rightMargin: 16 * screen_root.sc
                                spacing: 0

                                Text {
                                    text: "󰐥"
                                    font.family: "JetBrains Mono Nerd Font"
                                    font.pixelSize: 18 * screen_root.sc
                                    color: {
                                            if (poweroff_mouse_area.containsMouse) return root.color15;
                                            return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75);
                                        }

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
                                    font.pixelSize: 15 * screen_root.sc
                                    font.weight: Font.Medium
                                    color: {
                                            if (poweroff_mouse_area.containsMouse) return root.color15;
                                            return Qt.rgba(root.color15.r, root.color15.g, root.color15.b, 0.75);
                                        }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }

                                    }

                                }

                            }

                            MouseArea {
                                id: poweroff_mouse_area

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    screen_root.power_menu_open = false;
                                    poweroff_process.running = true;
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
                    id: power_btn

                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 40 * screen_root.sc
                    width: 52 * screen_root.sc
                    height: width
                    radius: height / 2
                    color: {
                            if (screen_root.power_menu_open) return root.color12;
                            if (power_btn_mouse_area.containsMouse) return Qt.rgba(root.color11.r, root.color11.g, root.color11.b, 0.8);
                            return Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.4);
                        }
                    border.color: {
                            if (screen_root.power_menu_open) return root.text;
                            return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15);
                        }
                    border.width: Math.max(1, 1 * screen_root.sc)
                    opacity: screen_root.intro_state
                    scale: {
                            if (power_btn_mouse_area.pressed) return 0.9;
                            if (power_btn_mouse_area.containsMouse) return 1.08;
                            return 1;
                        }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: "JetBrains Mono Nerd Font"
                        font.pixelSize: 22 * screen_root.sc
                        color: {
                                if (screen_root.power_menu_open) return root.color1;
                                if (power_btn_mouse_area.containsMouse) return root.text;
                                return root.color7;
                            }

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }

                        }

                    }

                    MouseArea {
                        id: power_btn_mouse_area

                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !screen_root.is_playing_intro
                        onClicked: {
                            screen_root.power_menu_open = !screen_root.power_menu_open;
                            if (!screen_root.power_menu_open)
                                input_field.forceActiveFocus();

                        }
                    }

                    transform: Translate {
                        y: (20 * screen_root.sc) * (1 - screen_root.intro_state)
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
                    id: intro_overlay

                    anchors.fill: parent
                    z: 999
                    visible: screen_root.is_playing_intro || opacity > 0

                    Rectangle {
                        id: ring_3

                        width: 360 * screen_root.sc
                        height: width
                        radius: height / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: root.color5
                        border.width: Math.max(1, 1 * screen_root.sc)
                        scale: 0.5
                        opacity: 0
                    }

                    Rectangle {
                        id: ring_2

                        width: 300 * screen_root.sc
                        height: width
                        radius: height / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: root.text
                        border.width: Math.max(1, 1 * screen_root.sc)
                        scale: 0.8
                        opacity: 0
                    }

                    Rectangle {
                        id: ring_1

                        width: 240 * screen_root.sc
                        height: width
                        radius: height / 2
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: root.text
                        border.width: Math.max(1, 2 * screen_root.sc)
                        scale: 0.8
                        opacity: 0
                    }

                    Item {
                        id: intro_lock_orb

                        width: 170 * screen_root.sc
                        height: width
                        anchors.centerIn: parent
                        scale: 0
                        opacity: 0

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Qt.rgba(root.color10.r, root.color10.g, root.color10.b, 0.9)
                            border.color: root.text
                            border.width: Math.max(1, 2 * screen_root.sc)
                        }

                        Text {
                            id: intro_icon_unlocked

                            anchors.centerIn: parent
                            text: "󰌿"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 64 * screen_root.sc
                            color: root.text
                            opacity: 1
                            scale: 1
                            transformOrigin: Item.Center
                        }

                        Text {
                            id: intro_icon_locked

                            anchors.centerIn: parent
                            text: "󰌾"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 64 * screen_root.sc
                            color: root.text
                            opacity: 0
                            scale: 1.6
                            transformOrigin: Item.Center
                        }

                    }

                    SequentialAnimation {
                        id: intro_sequence

                        ParallelAnimation {
                            NumberAnimation {
                                target: intro_lock_orb
                                property: "scale"
                                from: 0
                                to: 1
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: intro_lock_orb
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring_1
                                property: "scale"
                                from: 0.8
                                to: 1.25
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring_1
                                property: "opacity"
                                from: 0.6
                                to: 0
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring_2
                                property: "scale"
                                from: 0.8
                                to: 1.4
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring_2
                                property: "opacity"
                                from: 0.4
                                to: 0
                                duration: 300
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring_3
                                property: "scale"
                                from: 0.5
                                to: 1.5
                                duration: 350
                                easing.type: Easing.OutCubic
                            }

                            NumberAnimation {
                                target: ring_3
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
                                        target: intro_icon_unlocked
                                        property: "scale"
                                        from: 1
                                        to: 0.5
                                        duration: 100
                                        easing.type: Easing.InCubic
                                    }

                                    NumberAnimation {
                                        target: intro_icon_unlocked
                                        property: "opacity"
                                        from: 1
                                        to: 0
                                        duration: 50
                                    }

                                    NumberAnimation {
                                        target: intro_icon_locked
                                        property: "scale"
                                        from: 1.6
                                        to: 1
                                        duration: 200
                                        easing.type: Easing.OutBack
                                    }

                                    NumberAnimation {
                                        target: intro_icon_locked
                                        property: "opacity"
                                        from: 0
                                        to: 1
                                        duration: 100
                                    }

                                    SequentialAnimation {
                                        NumberAnimation {
                                            target: intro_lock_orb
                                            property: "anchors.verticalCenterOffset"
                                            from: 0
                                            to: 3 * screen_root.sc
                                            duration: 40
                                            easing.type: Easing.OutQuad
                                        }

                                        NumberAnimation {
                                            target: intro_lock_orb
                                            property: "anchors.verticalCenterOffset"
                                            from: 3 * screen_root.sc
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
                                    target: intro_lock_orb
                                    property: "scale"
                                    to: 1.8
                                    duration: 100
                                    easing.type: Easing.InCubic
                                }

                                NumberAnimation {
                                    target: intro_overlay
                                    property: "opacity"
                                    to: 0
                                    duration: 100
                                    easing.type: Easing.InCubic
                                }

                            }

                            NumberAnimation {
                                target: screen_root
                                property: "intro_state"
                                from: 0
                                to: 1
                                duration: 100
                                easing.type: Easing.OutCubic
                            }

                        }

                        PropertyAction {
                            target: screen_root
                            property: "is_playing_intro"
                            value: false
                        }

                        ScriptAction {
                            script: {
                                input_field.text = "";
                                input_field.forceActiveFocus();
                            }
                        }

                    }

                }

                NumberAnimation on global_orbit_angle {
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
