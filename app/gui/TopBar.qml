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

    signal openWirelessPanel()

    function focusFirstButton() {
        wirelessButton.forceActiveFocus(Qt.TabFocus)
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 10
            spacing: 6

            Button {
                id: wirelessButton
                flat: true
                implicitHeight: 26
                focusPolicy: Qt.StrongFocus
                spacing: 0
                leftPadding: 8
                rightPadding: 8

                contentItem: RowLayout {
                    spacing: 6

                    Image {
                        source: "qrc:/res/bluetooth.svg"
                        sourceSize.width: 14
                        sourceSize.height: 14
                        opacity: topBar.btConnected ? 1.0 : 0.35
                    }

                    Text {
                        text: topBar.wifiSsid.length > 0
                              ? topBar.wifiSsid
                              : qsTr("WiFi: --")
                        color: topBar.wifiSsid.length > 0 ? "#a0e0a0" : "#808080"
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        width: 1
                        height: 14
                        color: "#404040"
                        visible: topBar.btConnected
                    }

                    Text {
                        text: "\u25CF"
                        color: topBar.btConnected ? "#4CAF50" : "#404040"
                        font.pixelSize: 10
                        visible: topBar.btConnected
                    }
                }

                background: Rectangle {
                    color: wirelessButton.activeFocus ? "#3F51B5" : "transparent"
                    radius: 3
                }

                onClicked: topBar.openWirelessPanel()

                ToolTip.delay: 1000
                ToolTip.timeout: 3000
                ToolTip.visible: hovered
                ToolTip.text: {
                    var parts = []
                    if (topBar.wifiSsid.length > 0)
                        parts.push(qsTr("WiFi: %1").arg(topBar.wifiSsid))
                    if (topBar.btConnected)
                        parts.push(qsTr("BT gamepad connected"))
                    return parts.length > 0
                        ? parts.join("  |  ")
                        : qsTr("Wireless")
                }
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
