import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import WifiManager 1.0
import BluetoothManager 1.0
import SdlGamepadKeyNavigation 1.0

Page {
    id: wirelessPage
    objectName: qsTr("Wireless")

    property int currentTab: 0

    StackView.onActivated: {
        SdlGamepadKeyNavigation.setUiNavMode(true)
        if (currentTab === 0) {
            WifiManager.scan()
        }
    }

    StackView.onDeactivating: {
        SdlGamepadKeyNavigation.setUiNavMode(false)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabBar
            Layout.fillWidth: true
            Layout.margins: 0

            TabButton {
                text: qsTr("WiFi")
                onClicked: {
                    currentTab = 0
                    WifiManager.scan()
                }
            }
            TabButton {
                text: qsTr("Bluetooth")
                onClicked: {
                    currentTab = 1
                    if (!BluetoothManager.scanning) {
                        BluetoothManager.startDiscovery()
                    }
                }
            }
        }

        StackLayout {
            id: viewStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: currentTab

            // ── WiFi Tab ──────────────────────────────────
            ColumnLayout {
                spacing: 10
                Layout.margins: 10

                Text {
                    text: qsTr("Status: %1").arg(WifiManager.status.length > 0 ? WifiManager.status : qsTr("Idle"))
                    font.pixelSize: 13
                    color: "#b0b0b0"
                }

                ListView {
                    id: wifiList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: WifiManager.networks
                    delegate: wifiDelegate
                    focus: true

                    ScrollBar.vertical: ScrollBar {}

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Scanning...")
                        color: "#808080"
                        font.pixelSize: 14
                        visible: wifiList.count === 0
                    }
                }

                Button {
                    text: qsTr("Rescan")
                    flat: true
                    onClicked: WifiManager.scan()

                    Keys.onDownPressed: {
                        wifiList.forceActiveFocus(Qt.TabFocus)
                    }
                }
            }

            // ── Bluetooth Tab ─────────────────────────────
            ColumnLayout {
                spacing: 10
                Layout.margins: 10

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
        }
    }

    // ── WiFi Delegate ────────────────────────────────────
    Component {
        id: wifiDelegate

        ItemDelegate {
            id: wifiDelegateRoot
            width: wifiList.width
            height: 50
            highlighted: ListView.isCurrentItem

            property int strength: signal

            onClicked: {
                wifiList.currentIndex = index
                if (active) return
                var ssidText = ssid
                var secText = security
                if (secText !== "" && secText !== "--") {
                    passwordDialog.ssid = ssidText
                    passwordDialog.open()
                } else {
                    WifiManager.connectToNetwork(ssidText)
                }
            }

            contentItem: RowLayout {
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: ssid
                        font.pixelSize: 14
                        font.bold: active
                        color: active ? "#a0e0a0" : "white"
                        elide: Text.ElideRight
                    }

                    Text {
                        text: {
                            if (active) return qsTr("Connected")
                            if (security && security !== "--")
                                return qsTr("Secured (%1)").arg(security)
                            return qsTr("Open")
                        }
                        font.pixelSize: 11
                        color: "#808080"
                    }
                }

                Row {
                    spacing: 2
                    visible: !active

                    Repeater {
                        model: 4
                        Rectangle {
                            width: 4
                            height: 12
                            radius: 1
                            color: index * 25 < wifiDelegateRoot.strength ? "#4CAF50" : "#404040"
                        }
                    }
                }

                Text {
                    text: "\u2713"
                    color: "#4CAF50"
                    font.pixelSize: 16
                    visible: active
                }
            }

            Keys.onReturnPressed: clicked()
            Keys.onEnterPressed: clicked()
        }
    }

    // ── Bluetooth Delegate ───────────────────────────────
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

    // ── WiFi Password Dialog ─────────────────────────────
    Dialog {
        id: passwordDialog
        property string ssid: ""
        title: qsTr("Connect to %1").arg(ssid)
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true

        onAccepted: {
            WifiManager.connectToNetwork(ssid, passwordField.text)
        }

        onOpened: {
            passwordField.forceActiveFocus()
        }

        ColumnLayout {
            Text {
                text: qsTr("Enter password for %1:").arg(passwordDialog.ssid)
                font.bold: true
                color: "white"
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                focus: true

                Keys.onReturnPressed: passwordDialog.accept()
                Keys.onEnterPressed: passwordDialog.accept()
            }
        }
    }

    Connections {
        target: WifiManager
        function onConnected(ssid) {
        }
    }

    Connections {
        target: BluetoothManager
        function onDeviceConnected(name) {
        }
    }
}
