import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 720
    color: "#1a1a2e"

    title: "Moonlight Kiosk"

    StackView {
        id: stack
        anchors.fill: parent
        initialItem: onboardingDone ? mainMenu : onboardingScreen

        Component { id: onboardingScreen; OnboardingScreen {} }
        Component { id: mainMenu;          MainMenu {} }
    }

    Connections {
        target: controllerInput
        function onBack() {
            if (stack.depth > 1)
                stack.pop();
        }
    }

    Connections {
        target: cecManager
        function onBackPressed() {
            if (stack.depth > 1)
                stack.pop();
        }
    }
}
