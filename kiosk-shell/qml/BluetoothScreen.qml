import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property int _focusIndex: 0
    property var _focusItems: [scanBtn]

    function moveFocus(delta) {
        _focusItems[_focusIndex].focus = false;
        _focusIndex = (_focusIndex + delta + _focusItems.length) % _focusItems.length;
        _focusItems[_focusIndex].focus = true;
    }

    function activate() {
        _focusItems[_focusIndex].clicked();
    }

    function rebuildFocusItems() {
        var items = [scanBtn];
        for (var i = 0; i < deviceList.count; i++) {
            var del = deviceList.itemAtIndex(i);
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
                text: "Bluetooth Devices"
                font.pixelSize: 28
                font.bold: true
                color: "#e0e0e0"
            }

            ControllerButton {
                id: scanBtn
                text: bluetoothManager.scanning ? "Scanning..." : "Scan"
                desc: "Discover nearby Bluetooth devices"
                onClicked: {
                    bluetoothManager.startDiscovery();
                    Qt.callLater(rebuildFocusItems);
                }
            }

            ListView {
                id: deviceList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: bluetoothManager.devices
                clip: true

                delegate: ControllerButton {
                    width: ListView.view.width
                    text: modelData.name
                    desc: modelData.connected ? "Connected" :
                          modelData.paired ? "Paired" : "Not paired"
                    onClicked: {
                        if (!modelData.paired)
                            bluetoothManager.pairDevice(modelData.address);
                        else if (!modelData.connected)
                            bluetoothManager.connectDevice(modelData.address);
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
}
