import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"

            Image {
                id: logo1
                source: "nimok-logo.png"
                width: 140
                height: 140
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 60
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.top: logo1.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Welcome to Nimok Linux 0.1 (Nifoun)"
                color: "#cdd6f4"
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                anchors.top: logo1.bottom
                anchors.topMargin: 64
                anchors.horizontalCenter: parent.horizontalCenter
                text: "A modular Coding and Gaming Distro powered by Linux 7.3.5-nimok."
                color: "#a6adc8"
                font.pixelSize: 16
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"

            Text {
                id: title2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 120
                text: "Built for Low-Latency Gaming"
                color: "#89b4fa"
                font.pixelSize: 26
                font.bold: true
            }

            Text {
                anchors.top: title2.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Equipped with the BORE v7.0.0 CPU scheduler, 1000Hz tick rate,\nand KDE Plasma Wayland out of the box."
                horizontalAlignment: Text.AlignHCenter
                color: "#cdd6f4"
                font.pixelSize: 16
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1e1e2e"

            Text {
                id: title3
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 120
                text: "Unlocked for Developers"
                color: "#a6e3a1"
                font.pixelSize: 26
                font.bold: true
            }

            Text {
                anchors.top: title3.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Full apt, Node.js, npm, Python, and C/C++ build tools\nwith zero locked-down system restrictions."
                horizontalAlignment: Text.AlignHCenter
                color: "#cdd6f4"
                font.pixelSize: 16
            }
        }
    }
}
