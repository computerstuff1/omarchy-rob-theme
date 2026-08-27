import QtQuick
import qs.Ui

BarWidget {
    id: root
    moduleName: "rob.menubutton"

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    WidgetButton {
        id: button

        bar: root.bar
        hasVisualContent: true

        fixedWidth: root.barSize
        fixedHeight: root.barSize

        Image {
            anchors.centerIn: parent
            width: 24
            height: 24
            source: "my-logo.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        onPressed: function(mouseButton) {
            if (!root.bar) return

            if (mouseButton === Qt.RightButton)
                root.bar.run("xdg-terminal-exec")
            else
                root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
        }
    }
}
