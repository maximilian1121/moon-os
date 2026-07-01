import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property int _focusIndex: 0
    property var _focusItems: [refreshBtn]
    property bool _showingPassword: false

    function moveFocus(delta) {
        _focusItems[_focusIndex].focus = false;
        _focusIndex = (_focusIndex + delta + _focusItems.length) % _focusItems.length;
        _focusItems[_focusIndex].focus = true;
    }

    function activate() {
        _focusItems[_focusIndex].clicked();
    }

    function rebuildFocusItems() {
        var items = [refreshBtn];
        for (var i = 0; i < networkList.count; i++) {
            var del = networkList.itemAtIndex(i);
            if (del) items.push(del);
        }
        _focusItems = items;
    }

    Connections {
        target: controllerInput
        function onNavUp()    { root.moveFocus(-1); }
        function onNavDown()  { root.moveFocus(1); }
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
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Text {
                text: "Wi-Fi Networks"
                font.pixelSize: 28
                font.bold: true
                color: "#e0e0e0"
            }

            Text {
                text: wifiManager.status
                font.pixelSize: 14
                color: "#a0a0a0"
                visible: wifiManager.status !== ""
            }

            ControllerButton {
                id: refreshBtn
                text: "Refresh"
                desc: "Scan for networks"
                onClicked: {
                    wifiManager.scan();
                    // Rebuild focus after scan populates
                    Qt.callLater(rebuildFocusItems);
                }
            }

            ListView {
                id: networkList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: wifiManager.networks
                clip: true

                delegate: ControllerButton {
                    width: ListView.view.width
                    text: modelData.ssid + " (" + modelData.signal + "%)"
                    desc: modelData.active ? "Connected" : modelData.security
                    onClicked: {
                        if (modelData.security !== "" && modelData.security !== "--") {
                            passwordDialog.ssid = modelData.ssid;
                            passwordDialog.open();
                        } else {
                            wifiManager.connect(modelData.ssid);
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }

    Dialog {
        id: passwordDialog
        property string ssid: ""
        title: "Connect to " + ssid
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        contentItem: ColumnLayout {
            spacing: 12
            TextField {
                id: passwordField
                placeholderText: "Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
                focus: true
            }
        }

        onAccepted: {
            wifiManager.connect(passwordDialog.ssid, passwordField.text);
        }
    }
}
