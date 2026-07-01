import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property int _focusIndex: 0
    property var _focusItems: [resolutionGroup, audioBtn, overscanUp, overscanDown, applyBtn]

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

    property int _resIndex: 1
    readonly property var resolutions: [
        "720x480", "720x576", "1280x720", "1920x1080", "3840x2160"
    ]

    Rectangle {
        anchors.fill: parent
        color: "#1a1a2e"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: "Settings"
                font.pixelSize: 28
                font.bold: true
                color: "#e0e0e0"
            }

            GroupBox {
                id: resolutionGroup
                title: "Resolution"
                Layout.fillWidth: true
                focus: true

                background: Rectangle {
                    color: parent.activeFocus ? "#2a2a4a" : "#222244"
                    radius: 8
                    border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                    border.width: parent.activeFocus ? 2 : 0
                }

                label: Text {
                    text: "Resolution"
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    font.bold: true
                }

                RowLayout {
                    spacing: 12
                    Button {
                        text: "\u25C0"
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 40
                        onClicked: {
                            root._resIndex = (root._resIndex - 1 + root.resolutions.length) % root.resolutions.length;
                        }
                        background: Rectangle {
                            color: parent.activeFocus ? "#3a7bd5" : "#2a2a4a"
                            radius: 6
                            border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                            border.width: parent.activeFocus ? 2 : 0
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        text: root.resolutions[root._resIndex]
                        font.pixelSize: 20
                        color: "#e0e0e0"
                        Layout.preferredWidth: 180
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Button {
                        text: "\u25B6"
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 40
                        onClicked: {
                            root._resIndex = (root._resIndex + 1) % root.resolutions.length;
                        }
                        background: Rectangle {
                            color: parent.activeFocus ? "#3a7bd5" : "#2a2a4a"
                            radius: 6
                            border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                            border.width: parent.activeFocus ? 2 : 0
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            ControllerButton {
                id: audioBtn
                text: "Audio Output"
                desc: "HDMI (default)"
                onClicked: {
                    // Cycle audio output mode
                    var modes = ["HDMI", "Analog", "Auto"];
                    var idx = modes.indexOf(audioBtn.desc);
                    audioBtn.desc = modes[(idx + 1) % modes.length];
                }
            }

            GroupBox {
                title: "Overscan"
                Layout.fillWidth: true

                background: Rectangle {
                    color: parent.activeFocus ? "#2a2a4a" : "#222244"
                    radius: 8
                    border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                    border.width: parent.activeFocus ? 2 : 0
                }

                label: Text {
                    text: "Overscan"
                    color: "#e0e0e0"
                    font.pixelSize: 16
                    font.bold: true
                }

                RowLayout {
                    spacing: 12
                    Button {
                        id: overscanUp
                        text: "Increase"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        onClicked: overscanSlider.value = Math.min(overscanSlider.value + 5, 100)
                        background: Rectangle {
                            color: parent.activeFocus ? "#3a7bd5" : "#2a2a4a"
                            radius: 6
                            border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                            border.width: parent.activeFocus ? 2 : 0
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Slider {
                        id: overscanSlider
                        from: 0
                        to: 100
                        value: 0
                        Layout.fillWidth: true
                        focus: true
                    }

                    Button {
                        id: overscanDown
                        text: "Decrease"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        onClicked: overscanSlider.value = Math.max(overscanSlider.value - 5, 0)
                        background: Rectangle {
                            color: parent.activeFocus ? "#3a7bd5" : "#2a2a4a"
                            radius: 6
                            border.color: parent.activeFocus ? "#5a9bf5" : "transparent"
                            border.width: parent.activeFocus ? 2 : 0
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            ControllerButton {
                id: applyBtn
                text: "Apply & Save"
                desc: "Save settings and return to menu"
                onClicked: {
                    // Save settings to config file
                    stack.pop();
                }
            }
        }
    }
}
