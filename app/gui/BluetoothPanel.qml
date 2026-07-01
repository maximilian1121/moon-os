import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import BluetoothManager 1.0
import SdlGamepadKeyNavigation 1.0

Page {
    id: btPage
    objectName: qsTr("Bluetooth")

    StackView.onActivated: {
        SdlGamepadKeyNavigation.setUiNavMode(true)
    }

    StackView.onDeactivating: {
        SdlGamepadKeyNavigation.setUiNavMode(false)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            text: qsTr("Bluetooth Devices")
            font.pixelSize: 18
            font.bold: true
            color: "white"
        }

        Text {
            text: BluetoothManager.scanning
                  ? qsTr("Scanning...")
                  : qsTr("Scan stopped")
            font.pixelSize: 13
            color: BluetoothManager.scanning ? "#a0e0a0" : "#808080"
        }

        ListView {
            id: btList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: BluetoothManager.devices
            delegate: btDelegate
            focus: true

            ScrollBar.vertical: ScrollBar {}

            Text {
                anchors.centerIn: parent
                text: qsTr("No devices found")
                color: "#808080"
                font.pixelSize: 14
                visible: btList.count === 0 && !BluetoothManager.scanning
            }
        }

        RowLayout {
            spacing: 8

            Button {
                text: BluetoothManager.scanning ? qsTr("Stop Scan") : qsTr("Scan")
                flat: true
                onClicked: {
                    if (BluetoothManager.scanning) {
                        BluetoothManager.stopDiscovery()
                    } else {
                        BluetoothManager.startDiscovery()
                    }
                }

                Keys.onDownPressed: {
                    btList.forceActiveFocus(Qt.TabFocus)
                }
            }

            Button {
                text: qsTr("Scan & Connect Gamepads")
                flat: true
                onClicked: {
                    BluetoothManager.scanAndConnectGamepads()
                }

                Keys.onDownPressed: {
                    btList.forceActiveFocus(Qt.TabFocus)
                }
            }
        }
    }

    Component {
        id: btDelegate

        ItemDelegate {
            width: btList.width
            height: 50
            highlighted: ListView.isCurrentItem

            onClicked: {
                btList.currentIndex = index
                if (connected) return
                if (!paired) {
                    BluetoothManager.pairDevice(address)
                } else {
                    BluetoothManager.connectDevice(address)
                }
            }

            contentItem: RowLayout {
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: name
                        font.pixelSize: 14
                        font.bold: connected
                        color: connected ? "#a0e0a0" : "white"
                        elide: Text.ElideRight
                    }

                    Text {
                        text: {
                            var parts = []
                            if (isGamepad) parts.push(qsTr("Gamepad"))
                            if (connected) parts.push(qsTr("Connected"))
                            else if (paired) parts.push(qsTr("Paired"))
                            else parts.push(qsTr("Not paired"))
                            return parts.join(" \u00B7 ")
                        }
                        font.pixelSize: 11
                        color: "#808080"
                    }
                }

                Text {
                    text: qsTr("[Gamepad]")
                    font.pixelSize: 13
                    color: "#4CAF50"
                    visible: isGamepad
                }
            }

            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
        }
    }

    Connections {
        target: BluetoothManager
        function onDeviceConnected(name) {
        }
    }
}
