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

    Rectangle {
        anchors.fill: parent
        color: "#1e1e1e"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Image {
                id: btIcon
                source: "qrc:/res/bluetooth.svg"
                sourceSize.width: 18
                sourceSize.height: 18
                opacity: topBar.btConnected ? 1.0 : 0.4

                MouseArea {
                    anchors.fill: parent
                    onClicked: topBar.openBluetoothPanel()
                }
            }

            Text {
                id: wifiLabel
                text: topBar.wifiSsid.length > 0
                      ? topBar.wifiSsid
                      : qsTr("No WiFi")
                color: topBar.wifiSsid.length > 0 ? "#a0e0a0" : "#808080"
                font.pixelSize: 12
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: topBar.openWifiPanel()
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
