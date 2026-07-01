import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string label: ""
    property string subtitle: ""
    property bool highlight: false

    signal clicked()

    width: parent ? parent.width : 360
    height: 56

    color: root.highlight ? "#3a7bd5" : "#222244"
    radius: 6

    border.color: root.highlight ? "#5a9bf5" : "transparent"
    border.width: root.highlight ? 2 : 0

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            text: root.label
            color: "#ffffff"
            font.pixelSize: 18
            font.bold: true
        }
        Text {
            text: root.subtitle
            color: "#a0a0a0"
            font.pixelSize: 13
            visible: root.subtitle !== ""
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
