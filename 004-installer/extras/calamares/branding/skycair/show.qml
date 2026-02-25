/* SkyCAIR OS — Calamares slideshow */
import QtQuick 2.15

Rectangle {
    anchors.fill: parent
    color: "#0a1628"

    Column {
        anchors.centerIn: parent
        spacing: 24

        Image {
            id: logo
            source: "skycair-logo.png"
            width: 200
            height: 200
            anchors.horizontalCenter: parent.horizontalCenter
            fillMode: Image.PreserveAspectFit
        }

        Text {
            text: "Installing SkyCAIR OS"
            color: "#ffffff"
            font.pixelSize: 28
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Care About AI Readiness"
            color: "#00aaff"
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "EODv9 — End of Days Edition"
            color: "#88aacc"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "2XR, LLC  |  Evolve2Linux  |  123Tech.net"
            color: "#556677"
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
