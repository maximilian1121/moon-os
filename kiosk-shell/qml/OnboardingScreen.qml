import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property int _focusIndex: 0
    property var _focusItems: [scanButton, exitButton]

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
            spacing: 24

            Text {
                text: "Welcome to Moonlight"
                font.pixelSize: 36
                font.bold: true
                color: "#e0e0e0"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "Let's get your gamepad connected and display configured."
                font.pixelSize: 18
                color: "#a0a0a0"
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: 500
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
            }

            Item { height: 16 }

            Button {
                id: scanButton
                text: bluetoothManager.scanning ? "Scanning..." : "Scan for Gamepads"
                focus: true
                Layout.preferredWidth: 320
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter

                onClicked: bluetoothManager.scanAndConnectGamepads()

                background: Rectangle {
                    color: parent.activeFocus ? "#3a7bd5" : (parent.hovered ? "#2a5aa5" : "#2a2a4a")
                    radius: 8
                    border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                    border.width: parent.activeFocus ? 2 : 0
                }
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Column {
                spacing: 4
                Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: bluetoothManager.devices
                    Text {
                        text: modelData.name + (modelData.connected ? " \u2713" : modelData.paired ? " pairing..." : "")
                        color: modelData.connected ? "#4caf50" : "#ffa726"
                        font.pixelSize: 14
                    }
                }
            }

            Item { height: 16 }

            Button {
                id: exitButton
                text: "Continue"
                Layout.preferredWidth: 320
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter

                onClicked: {
                    moonlightLauncher.writeConfig();
                    stack.replace(mainMenu);
                }

                background: Rectangle {
                    color: parent.activeFocus ? "#3a7bd5" : (parent.hovered ? "#2a5aa5" : "#2a2a4a")
                    radius: 8
                    border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                    border.width: parent.activeFocus ? 2 : 0
                }
                contentItem: Text {
                    text: parent.text
                    color: "#ffffff"
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
