import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property int _focusIndex: 0
    property var _focusItems: [launchBtn, wifiBtn, btBtn, settingsBtn]

    function moveFocus(delta) {
        _focusItems[_focusIndex].focus = false;
        _focusIndex = (_focusIndex + delta + _focusItems.length) % _focusItems.length;
        _focusItems[_focusIndex].focus = true;
    }

    function activate() {
        _focusItems[_focusIndex].clicked();
    }

    Connections {
        target: controllerInput
        function onNavUp()    { root.moveFocus(-1); }
        function onNavDown()  { root.moveFocus(1); }
        function onNavLeft()  { root.moveFocus(-1); }
        function onNavRight() { root.moveFocus(1); }
        function onAccept()   { root.activate(); }
    }

    Connections {
        target: cecManager
        function onUpPressed()    { root.moveFocus(-1); }
        function onDownPressed()  { root.moveFocus(1); }
        function onSelectPressed(){ root.activate(); }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1a1a2e"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            Text {
                text: "Moonlight"
                font.pixelSize: 48
                font.bold: true
                color: "#e0e0e0"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Game Streaming for Raspberry Pi"
                font.pixelSize: 16
                color: "#808080"
                Layout.alignment: Qt.AlignHCenter
                bottomPadding: 24
            }

            ControllerButton {
                id: launchBtn
                text: "Launch Moonlight"
                desc: "Start streaming from your PC"
                focus: true
                onClicked: moonlightLauncher.launch()
            }

            ControllerButton {
                id: wifiBtn
                text: "Wi-Fi Settings"
                desc: "Connect to wireless networks"
                onClicked: stack.push("qrc:/qml/WifiScreen.qml")
            }

            ControllerButton {
                id: btBtn
                text: "Bluetooth"
                desc: "Pair gamepads and accessories"
                onClicked: stack.push("qrc:/qml/BluetoothScreen.qml")
            }

            ControllerButton {
                id: settingsBtn
                text: "Settings"
                desc: "Display, audio, and system"
                onClicked: stack.push("qrc:/qml/SettingsScreen.qml")
            }
        }
    }
}
