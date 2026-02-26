/* =============================================================================
 *  SkyCAIR OS — Calamares: SkyDESKTOP Mode Selection Page
 *  Presents 3 boot mode options to the user during installation
 *
 *  Selected value written to globalstorage["skyDesktopMode"]
 *  Read by: skydesktop/main.py
 *
 *  2XR, LLC | Evolve2Linux | 123Tech.net
 * =========================================================================== */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: root
    width:  parent.width
    height: parent.height

    // Selected mode — default is "server"
    property string selectedMode: "server"

    // Pass value to Calamares globalstorage
    Component.onCompleted: {
        Calamares.globalStorage.insert("skyDesktopMode", selectedMode)
    }
    onSelectedModeChanged: {
        Calamares.globalStorage.insert("skyDesktopMode", selectedMode)
    }

    // ─── Color palette (SkyCAIR dark theme) ──────────────────────────────────
    readonly property color clrBackground: "#060611"
    readonly property color clrCard:       "#0d0d2b"
    readonly property color clrCardSel:    "#0a1a4a"
    readonly property color clrBorder:     "#1a1a4a"
    readonly property color clrBorderSel:  "#3a6aff"
    readonly property color clrAccent:     "#3a6aff"
    readonly property color clrTextPrimary:  "#e8eaf6"
    readonly property color clrTextSecondary: "#8892b0"
    readonly property color clrTextMuted:    "#4a5568"

    Rectangle {
        anchors.fill: parent
        color: clrBackground

        ColumnLayout {
            anchors {
                fill: parent
                margins: 32
            }
            spacing: 20

            // ─── Header ──────────────────────────────────────────────────────
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true

                Text {
                    text: "Boot Mode"
                    font { pixelSize: 26; bold: true }
                    color: clrTextPrimary
                }
                Text {
                    text: "How should SkyCAIR OS start? This configures what you see when the system boots."
                    font.pixelSize: 14
                    color: clrTextSecondary
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // ─── Mode cards ──────────────────────────────────────────────────
            ButtonGroup { id: modeGroup }

            // --- SERVER (default) ---
            ModeCard {
                id: cardServer
                Layout.fillWidth: true
                modeId:      "server"
                title:       "Server  ·  Recommended"
                badge:       "DEFAULT"
                badgeColor:  clrAccent
                iconText:    "⚙"
                subtitle:    "Headless — Mission Control from any browser on your network"
                description: "SkyCAIR boots as a headless server. No monitor required.\n" +
                             "Access Mission Control and the COSMIC Desktop from any browser:\n" +
                             "https://<host>:8443/mc/  ·  COSMIC Desktop tab streams via WebRTC.\n\n" +
                             "Best for: servers, mini PCs without monitors, VMs, remote deployments."
                selected:    root.selectedMode === "server"
                onClicked:   root.selectedMode = "server"
                buttonGroup: modeGroup
                palette:     root
            }

            // --- FULL KIOSK ---
            ModeCard {
                id: cardFull
                Layout.fillWidth: true
                modeId:      "full"
                title:       "Full Kiosk"
                badge:       ""
                iconText:    "🖥"
                subtitle:    "Physical display boots directly to Mission Control"
                description: "SkyCAIR boots to a full-screen Mission Control dashboard on the\n" +
                             "physical display (Sway compositor → Chromium kiosk mode).\n" +
                             "The COSMIC Desktop tab is still accessible via WebRTC.\n\n" +
                             "Best for: dedicated SkyCAIR workstations, reception kiosks, wall displays."
                selected:    root.selectedMode === "full"
                onClicked:   root.selectedMode = "full"
                buttonGroup: modeGroup
                palette:     root
            }

            // --- CLI ---
            ModeCard {
                id: cardCli
                Layout.fillWidth: true
                modeId:      "cli"
                title:       "CLI Only"
                badge:       ""
                iconText:    ">"
                subtitle:    "Text mode — no GUI, no WebRTC, tty/SSH login only"
                description: "SkyCAIR boots to a terminal login prompt. No graphical interface.\n" +
                             "All containers still run (SkyOMEGAi, SkyVAULT, etc.).\n" +
                             "Managed via SSH or tty only.\n\n" +
                             "Best for: data center servers, embedded systems, SSH-only deployments."
                selected:    root.selectedMode === "cli"
                onClicked:   root.selectedMode = "cli"
                buttonGroup: modeGroup
                palette:     root
            }

            Item { Layout.fillHeight: true }

            // ─── Footer note ─────────────────────────────────────────────────
            Text {
                text: "ⓘ  You can change the boot mode after install by editing /etc/skycair/skydesktop.env"
                font.pixelSize: 12
                color: clrTextMuted
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }


    // ─── ModeCard component ──────────────────────────────────────────────────
    component ModeCard: Rectangle {
        id: card

        required property string  modeId
        required property string  title
        required property string  badge
        required property color   badgeColor
        required property string  iconText
        required property string  subtitle
        required property string  description
        required property bool    selected
        required property var     buttonGroup
        required property var     palette

        signal clicked()

        height:  cardContent.implicitHeight + 32
        radius:  10
        border.width: selected ? 2 : 1
        border.color: selected ? palette.clrBorderSel : palette.clrBorder
        color:         selected ? palette.clrCardSel   : palette.clrCard

        Behavior on color        { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Hover highlight
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: card.clicked()
            cursorShape: Qt.PointingHandCursor
        }
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: ma.containsMouse && !card.selected ? "#ffffff08" : "transparent"
        }

        RowLayout {
            id: cardContent
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 16

            // Icon
            Rectangle {
                width: 44; height: 44
                radius: 8
                color: card.selected ? "#1a2a6a" : "#0f1230"
                Text {
                    anchors.centerIn: parent
                    text: card.iconText
                    font.pixelSize: 22
                    color: card.selected ? palette.clrAccent : palette.clrTextSecondary
                }
            }

            // Text column
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    spacing: 8
                    Text {
                        text: card.title
                        font { pixelSize: 15; bold: true }
                        color: palette.clrTextPrimary
                    }
                    Rectangle {
                        visible:  card.badge !== ""
                        width:    badgeLabel.implicitWidth + 10
                        height:   18
                        radius:   4
                        color:    Qt.rgba(
                            card.badgeColor.r,
                            card.badgeColor.g,
                            card.badgeColor.b, 0.25
                        )
                        border.color: card.badgeColor
                        border.width: 1
                        Text {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: card.badge
                            font { pixelSize: 10; bold: true; letterSpacing: 0.5 }
                            color: card.badgeColor
                        }
                    }
                }

                Text {
                    text: card.subtitle
                    font.pixelSize: 13
                    color: card.selected ? "#a0c0ff" : palette.clrTextSecondary
                }

                Text {
                    text: card.description
                    font.pixelSize: 12
                    color: palette.clrTextMuted
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    topPadding: 4
                }
            }

            // Radio indicator
            Rectangle {
                width: 20; height: 20
                radius: 10
                border.width: 2
                border.color: card.selected ? palette.clrAccent : palette.clrTextMuted
                color: "transparent"
                Rectangle {
                    anchors.centerIn: parent
                    width: 10; height: 10; radius: 5
                    color: palette.clrAccent
                    visible: card.selected
                }
            }
        }
    }
}
