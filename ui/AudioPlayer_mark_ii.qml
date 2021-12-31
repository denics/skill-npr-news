/*
* Copyright 2021 by Aditya Mehra <aix.m@outlook.com>
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/

import QtQuick 2.12
import QtMultimedia 5.12
import QtQuick.Controls 2.12 as Controls
import QtQuick.Templates 2.12 as T
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Mycroft.CardDelegate {
    id: root
    fillWidth: true
    skillBackgroundColorOverlay: "black"
    property var theme: sessionData.theme
    cardBackgroundOverlayColor: Qt.darker(theme.bgColor)
    cardRadius: Mycroft.Units.gridUnit

    // Track_Lengths, Durations, Positions are always in milliseconds
    // Position is always in milleseconds and relative to track_length if track_length = 530000, position values range from 0 to 530000

    property var media: sessionData.media
    property var playerDuration: media.length
    property real playerPosition: 0
    property var playerState: sessionData.status
    property bool isStreaming: media.streaming
    property bool countdowntimerpaused: false

    function formatTime(ms) {
        if (typeof(ms) !== "number") {
            return "";
        }
        var minutes = Math.floor(ms / 60000);
        var seconds = ((ms % 60000) / 1000).toFixed(0);
        return minutes + ":" + (seconds < 10 ? '0' : '') + seconds;
    }

    onPlayerStateChanged: {
        console.log(playerState)
        if(playerState === "Playing"){
            root.playerPosition = media.position
            countdowntimer.running = true
        } else if(playerState === "Paused") {
            root.playerPosition = media.position
            countdowntimer.running = false
        }
    }

    Timer {
        id: countdowntimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if(media.length > playerPosition){
                if(!countdowntimerpaused){
                    playerPosition = playerPosition + 1000
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Mycroft.Units.gridUnit
        color: Qt.darker(theme.bgColor)

        Item {
            id: topArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bottomArea.top
            anchors.topMargin: Mycroft.Units.gridUnit * 2
            anchors.leftMargin: Mycroft.Units.gridUnit * 2
            anchors.rightMargin: Mycroft.Units.gridUnit * 2

            Rectangle {
                id: imageContainer
                width: Mycroft.Units.gridUnit * 18
                height: Mycroft.Units.gridUnit * 18
                anchors.top: parent.top // remove this on scalable
                color: theme.fgColor
                radius: Mycroft.Units.gridUnit

                Image {
                    id: trackImage
                    visible: true
                    enabled: true
                    anchors.fill: parent
                    anchors.leftMargin: Mycroft.Units.gridUnit / 2
                    anchors.topMargin: Mycroft.Units.gridUnit / 2
                    anchors.rightMargin: Mycroft.Units.gridUnit / 2
                    anchors.bottomMargin: Mycroft.Units.gridUnit / 2
                    source: media.image
                    fillMode: Image.PreserveAspectFit
                    z: 100
                }
            }

            Rectangle {
                id: mediaControlsContainer
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: bottomArea.top
                anchors.left: imageContainer.right
                anchors.topMargin: Mycroft.Units.gridUnit * 2
                // anchors.rightMargin: provided by root container
                anchors.bottomMargin: Mycroft.Units.gridUnit * 2
                anchors.leftMargin: Mycroft.Units.gridUnit * 2
                width: Mycroft.Units.gridUnit * 24
                height: Mycroft.Units.gridUnit * 22 - bottomArea.height
                color: "transparent"

                Item {
                    id: trackInfo
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: Mycroft.Units.gridUnit * 10

                    Title {
                        id: newsBriefingTitle
                        anchors.top: parent.top
                        anchors.topMargin: Mycroft.Units.gridUnit
                        anchors.horizontalCenter: parent.horizontalCenter
                        fontSize: 35
                        fontStyle: "Bold"
                        color: theme.fgColor
                        heightUnits: 2
                        text: "News Briefing"
                    }

                    Title {
                        id: station
                        anchors.top: newsBriefingTitle.bottom
                        anchors.topMargin: Mycroft.Units.gridUnit
                        anchors.horizontalCenter: parent.horizontalCenter
                        fontSize: 47
                        fontStyle: "Bold"
                        color: theme.fgColor
                        heightUnits: 4
                        text: media.artist
                    }

                    Item {
                        id: mediaControls
                        anchors.top: trackInfo.bottom
                        anchors.right: mediaControlsContainer.right
                        width: mediaControlsContainer.width
                        height: mediaControlsContainer.height - trackInfo.height

                        Controls.Button {
                            id: restartButton
                            anchors.right: playButton.left
                            anchors.rightMargin: Mycroft.Units.gridUnit * 4
                            anchors.top: mediaControls.top
                            height: Mycroft.Units.gridUnit * 5
                            width: Mycroft.Units.gridUnit * 5
                            focus: false
                            KeyNavigation.right: playButton
                            KeyNavigation.down: seekableslider
                            onClicked: {
                                triggerGuiEvent("cps.gui.restart", {})
                            }

                            contentItem: Kirigami.Icon {
                                source: Qt.resolvedUrl("images/media-restart.svg")
                                color: theme.fgColor
                            }

                            background: Rectangle {
                                color: "transparent"
                            }

                            Keys.onReturnPressed: {
                                clicked()
                            }
                        }

                        Controls.Button {
                            id: playButton
                            anchors.right: mediaControls.right
                            anchors.rightMargin: Mycroft.Units.gridUnit * 4
                            anchors.top: mediaControls.top
                            height: Mycroft.Units.gridUnit * 5
                            width: Mycroft.Units.gridUnit * 5
                            onClicked: {
                                if (playerState != "Playing"){
                                    triggerGuiEvent("cps.gui.play", {"media": {
                                                            "image": media.image,
                                                            "track": media.track,
                                                            "album": media.album,
                                                            "skill_id": media.skill,
                                                            "length": media.length,
                                                            "position": playerPosition
                                                            }})
                                } else {
                                    triggerGuiEvent("cps.gui.pause", {"media": {
                                                            "image": media.image,
                                                            "track": media.track,
                                                            "album": media.album,
                                                            "skill_id":media.skill,
                                                            "length": media.length,
                                                            "position": playerPosition
                                                            }})
                                }
                            }

                            background: Rectangle {
                                color: "transparent"
                            }

                            contentItem: Kirigami.Icon {
                                color: theme.fgColor
                                source: playerState === "Playing" ? Qt.resolvedUrl("images/media-playback-pause.svg") : Qt.resolvedUrl("images/media-playback-start.svg")
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: bottomArea
            width: parent.width
            anchors.bottom: parent.bottom
            height: Mycroft.Units.gridUnit * 5
            color: "transparent"

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                visible: media.length !== -1 ? 1 : 0
                enabled: media.length !== -1 ? 1 : 0
                
                Controls.Label {
                    anchors.left: parent.left
                    anchors.leftMargin: Mycroft.Units.gridUnit * 2
                    font.pixelSize: Mycroft.Units.gridUnit * 2
                    font.bold: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    text: formatTime(playerPosition)
                    color: theme.fgColor
                }

                Controls.Label {
                    anchors.right: parent.right
                    anchors.rightMargin: Mycroft.Units.gridUnit * 2
                    font.pixelSize: Mycroft.Units.gridUnit * 2
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: formatTime(playerDuration)
                    color: theme.fgColor
                }
            }

            T.Slider {
                id: seekableslider
                to: playerDuration
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Mycroft.Units.gridUnit * 2
                property bool sync: false
                live: false
                visible: media.length !== -1 ? 1 : 0
                enabled: media.length !== -1 ? 1 : 0
                value: playerPosition

                onPressedChanged: {
                    if(seekableslider.pressed){
                        root.countdowntimerpaused = true
                    } else {
                        root.countdowntimerpaused = false
                    }
                }

                onValueChanged: {
                    if(root.countdowntimerpaused){
                        triggerGuiEvent("cps.gui.seek", {"seekValue": value})
                    }
                }

                handle: Item {
                    x: seekableslider.visualPosition * (parent.width - (Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing))
                    anchors.verticalCenter: parent.verticalCenter
                    height: Mycroft.Units.gridUnit * 2

                    Rectangle {
                        id: positionMarker
                        visible: !isStreaming
                        enabled: !isStreaming
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: Mycroft.Units.gridUnit * 2
                        implicitHeight: Mycroft.Units.gridUnit * 2
                        radius: 100
                        color: seekableslider.pressed ? "#f0f0f0" : "#f6f6f6"
                        border.color: theme.bgColor
                    }
                }

                Controls.Label {
                    id: streamingLabel
                    visible: isStreaming
                    enabled: isStreaming
                    width: seekableslider.availableWidth
                    height: seekableslider.availableHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "STREAMING"
                    font.pixelSize: Mycroft.Units.gridUnit * 1.5
                    font.capitalization: Font.Capitalize
                    font.bold: true
                    color: theme.fgColor
                }

                background: Rectangle {
                    id: sliderBackground
                    x: seekableslider.leftPadding
                    y: seekableslider.topPadding + seekableslider.availableHeight / 2 - height / 2
                    width: seekableslider.availableWidth
                    height: Mycroft.Units.gridUnit * 2
                    radius: Mycroft.Units.gridUnit
                    color: theme.bgColor

                    Rectangle {
                        width: seekableslider.visualPosition * parent.width
                        height: parent.height
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#21bea6" }
                            GradientStop { position: 1.0; color: "#2194be" }
                        }
                        radius: Mycroft.Units.gridUnit
                    }
                }
            }
        }
    }
}
