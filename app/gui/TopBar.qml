import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import WifiManager 1.0
import BluetoothManager 1.0

Item {
    id: topBar
    height: 32

    property bool btConnected: BluetoothManager.hasConnectedGamepad
    property string wifiSsid: WifiManager.connectedSsid

    signal openWifiPanel()
    signal openBluetoothPanel()

    function focusFirstButton() {
        btButton.forceActiveFocus(Qt.TabFocus)
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 8
            spacing: 2

            Button {
                id: btButton
                flat: true
                implicitWidth: 28
                implicitHeight: 28
                focusPolicy: Qt.StrongFocus

                contentItem: Image {
                    source: "qrc:/res/bluetooth.svg"
                    sourceSize.width: 16
                    sourceSize.height: 16
                    opacity: topBar.btConnected ? 1.0 : 0.35
                    anchors.centerIn: parent
                }

                background: Rectangle {
                    color: btButton.activeFocus ? "#3F51B5" : "transparent"
                    radius: 3
                }

                onClicked: topBar.openBluetoothPanel()

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: topBar.btConnected
                              ? qsTr("Bluetooth gamepad connected")
                              : qsTr("No Bluetooth gamepad")
            }

            Button {
                id: wifiButton
                flat: true
                implicitHeight: 28
                focusPolicy: Qt.StrongFocus

                contentItem: Text {
                    text: topBar.wifiSsid.length > 0
                          ? topBar.wifiSsid
                          : qsTr("WiFi: --")
                    color: topBar.wifiSsid.length > 0 ? "#a0e0a0" : "#808080"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                }

                background: Rectangle {
                    color: wifiButton.activeFocus ? "#3F51B5" : "transparent"
                    radius: 3
                }

                onClicked: topBar.openWifiPanel()

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: topBar.wifiSsid.length > 0
                              ? qsTr("Connected to %1").arg(topBar.wifiSsid)
                              : qsTr("Not connected")
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: qsTr("Moonlight")
                color: "#606060"
                font.pixelSize: 11
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Connections {
        target: BluetoothManager
        function onHasConnectedGamepadChanged() {
            topBar.btConnected = BluetoothManager.hasConnectedGamepad
        }
    }

    Connections {
        target: WifiManager
        function onConnectedSsidChanged() {
            topBar.wifiSsid = WifiManager.connectedSsid
        }
    }
}
