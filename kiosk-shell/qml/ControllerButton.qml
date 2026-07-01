import QtQuick
import QtQuick.Controls

Button {
    id: root

    property string desc: ""

    implicitWidth: 360
    implicitHeight: 56

    background: Rectangle {
        color: root.activeFocus ? "#3a7bd5" : (root.hovered ? "#2a5aa5" : "#2a2a4a")
        radius: 8
        border.color: root.activeFocus ? "#5a9bf5" : "transparent"
        border.width: root.activeFocus ? 2 : 0
    }

    contentItem: Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            text: root.text
            color: "#ffffff"
            font.pixelSize: 18
            font.bold: true
        }
        Text {
            text: root.desc
            color: "#a0a0a0"
            font.pixelSize: 13
            visible: root.desc !== ""
        }
    }
}
