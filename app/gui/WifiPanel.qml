import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import WifiManager 1.0
import SdlGamepadKeyNavigation 1.0

Page {
    id: wifiPage
    objectName: qsTr("WiFi Networks")

    property string connectingSsid: ""
    property var signalStrength: 0

    StackView.onActivated: {
        SdlGamepadKeyNavigation.setUiNavMode(true)
        WifiManager.scan()
    }

    StackView.onDeactivating: {
        SdlGamepadKeyNavigation.setUiNavMode(false)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Text {
            text: qsTr("WiFi Networks")
            font.pixelSize: 18
            font.bold: true
            color: "white"
        }

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

    Component {
        id: wifiDelegate

        ItemDelegate {
            id: delegateRoot
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
                            color: index * 25 < delegateRoot.strength ? "#4CAF50" : "#404040"
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
            wifiPage.connectingSsid = ""
        }
    }
}
