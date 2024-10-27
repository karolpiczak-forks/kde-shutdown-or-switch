/*
 *  SPDX-FileCopyrightText: 2024 Davide Sandonà <sandona.davide@gmail.com>
 *  SPDX-FileCopyrightText: 2015 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.config as KConfig  // KAuthorized.authorizeControlModule
import org.kde.coreaddons as KCoreAddons // kuser
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import org.kde.plasma.private.sessions as Sessions

PlasmoidItem {
    id: root

    // from configuration
    readonly property bool showIcon: Plasmoid.configuration.showIcon
    readonly property bool showName: Plasmoid.configuration.showName
    readonly property bool showFullName: Plasmoid.configuration.showFullName
    readonly property bool showLockScreen: Plasmoid.configuration.showLockScreen
    readonly property bool showLogOut: Plasmoid.configuration.showLogOut
    readonly property bool showRestart: Plasmoid.configuration.showRestart
    readonly property bool showShutdown: Plasmoid.configuration.showShutdown
    readonly property bool showSuspend: Plasmoid.configuration.showSuspend
    readonly property bool showHibernate: Plasmoid.configuration.showHibernate
    readonly property bool showNewSession: Plasmoid.configuration.showNewSession
    readonly property bool showUsers: Plasmoid.configuration.showUsers
    readonly property bool showText: Plasmoid.configuration.showText

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool inPanel: (Plasmoid.location === PlasmaCore.Types.TopEdge
        || Plasmoid.location === PlasmaCore.Types.RightEdge
        || Plasmoid.location === PlasmaCore.Types.BottomEdge
        || Plasmoid.location === PlasmaCore.Types.LeftEdge)
    
    readonly property string avatarIcon: kuser.faceIconUrl.toString()
    readonly property string displayedName: showFullName ? kuser.fullName : kuser.loginName

    // switchWidth: Kirigami.Units.gridUnit * 10
    // switchHeight: Kirigami.Units.gridUnit * 12

    toolTipTextFormat: Text.StyledText
    toolTipSubText: i18n("You are logged in as <b>%1</b>", displayedName)

    // revert to the Plasmoid icon if no face given
    Plasmoid.icon: kuser.faceIconUrl.toString() || (inPanel ? "system-switch-user-symbolic" : "preferences-system-users" )

    KCoreAddons.KUser {
        id: kuser
    }

    compactRepresentation: MouseArea {
        id: compactRoot

        // Taken from DigitalClock to ensure uniform sizing when next to each other
        readonly property bool tooSmall: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && Math.round(2 * (compactRoot.height / 5)) <= Kirigami.Theme.smallFont.pixelSize

        Layout.minimumWidth: isVertical ? 0 : compactRow.implicitWidth
        Layout.maximumWidth: isVertical ? Infinity : Layout.minimumWidth
        Layout.preferredWidth: isVertical ? -1 : Layout.minimumWidth

        Layout.minimumHeight: isVertical ? label.height : Kirigami.Theme.smallFont.pixelSize
        Layout.maximumHeight: isVertical ? Layout.minimumHeight : Infinity
        Layout.preferredHeight: isVertical ? Layout.minimumHeight : Kirigami.Units.iconSizes.sizeForLabels * 2

        property bool wasExpanded
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        Row {
            id: compactRow

            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: shutdownIcon
                source: "system-shutdown-symbolic-custom"
                anchors.verticalCenter: parent.verticalCenter
                height: compactRoot.height - Math.round(Kirigami.Units.smallSpacing / 2)
                width: height
                visible: root.showIcon
            }

            PlasmaComponents.Label {
                id: label
                width: root.isVertical ? compactRoot.width : contentWidth
                height: root.isVertical ? contentHeight : compactRoot.height
                text: root.displayedName
                textFormat: Text.PlainText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.NoWrap
                fontSizeMode: root.isVertical ? Text.HorizontalFit : Text.VerticalFit
                font.pixelSize: tooSmall ? Kirigami.Theme.defaultFont.pixelSize : Kirigami.Units.iconSizes.roundedIconSize(Kirigami.Units.gridUnit * 2)
                minimumPointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.showName
            }
        }
    }
        
    fullRepresentation: Item {
        id: fullRoot

        implicitWidth: column.implicitWidth
        implicitHeight: column.implicitHeight

        Layout.preferredWidth: showText ? Kirigami.Units.gridUnit * 12 : Kirigami.Units.iconSizes.smallMedium * 1.6
        Layout.preferredHeight: implicitHeight
        
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        Layout.maximumWidth: Layout.preferredWidth
        Layout.maximumHeight: Layout.preferredHeight

        Sessions.SessionManagement {
            id: sm
        }

        Sessions.SessionsModel {
            id: sessionsModel
        }

        ColumnLayout {
            id: column

            anchors.fill: parent
            spacing: 0

            UserListDelegate {
                id: currentUserItem
                text: root.displayedName
                subText: i18n("Current user")
                source: root.avatarIcon
                hoverEnabled: false
                visible: showUsers
            }

            // PlasmaComponents.ScrollView {
            //     id: scroll

            //     Layout.fillWidth: true
            //     Layout.fillHeight: true

            //     // HACK: workaround for https://bugreports.qt.io/browse/QTBUG-83890
            //     PlasmaComponents.ScrollBar.horizontal.policy: PlasmaComponents.ScrollBar.AlwaysOff

            //     ListView {
                    
            //         id: userList
            //         model: sessionsModel

            //         interactive: true
            //         keyNavigationWraps: false

            //         delegate: UserListDelegate {
            //             width: ListView.view.width

            //             activeFocusOnTab: true

            //             text: {
            //                 if (!model.session) {
            //                     return i18nc("Nobody logged in on that session", "Unused")
            //                 }

            //                 if (model.realName && root.showFullName) {
            //                     return model.realName
            //                 }

            //                 return model.name
            //             }
            //             source: model.icon

            //             KeyNavigation.up: index === 0 ? currentUserItem.nextItemInFocusChain() : userList.itemAtIndex(index - 1)
            //             KeyNavigation.down: index === userList.count - 1 ? newSessionButton : userList.itemAtIndex(index + 1)

            //             Accessible.description: i18nc("@action:button", "Switch to User %1", text)

            //             onClicked: sessionsModel.switchUser(model.vtNumber, sessionsModel.shouldLock)
            //         }
            //     }

            // }

            ListView {
                id: controlsList

                implicitHeight: contentItem.height
                Layout.fillWidth: true

                keyNavigationWraps: true
                highlight: Rectangle { color: "#6193ab"; radius: 5; opacity: 0.5 }

                model: ListModel {
                    Component.onCompleted: {
                        sessionsModel.canStartNewSession && showNewSession ? append({
                            "text": "New session",
                            "iconName": "system-switch-user",
                            "action": "switch-user",
                        }) : null;
                        sm.canLock && showLockScreen ? append({
                            "text": "Lock screen",
                            "iconName": "system-lock-screen",
                            "action": "lock",
                        }) : null;
                        sm.canLogout && showLogOut ? append({
                            "text": "Log out",
                            "iconName": "system-log-out",
                            "action": "logout",
                            "confirm": true,
                        }) : null;
                        sm.canReboot && showRestart ? append({
                            "text": "Reboot",
                            "iconName": "system-reboot",
                            "action": "reboot",
                            "confirm": true,
                        }) : null;
                        sm.canSuspend && showSuspend ? append({
                            "text": "Suspend",
                            "iconName": "system-suspend",
                            "action": "suspend",
                        }) : null;
                        sm.canSuspendThenHibernate && showHibernate ? append({
                            "text": "Hibernate",
                            "iconName": "system-suspend-hibernate",
                            "action": "hibernate",
                            "confirm": true,
                        }) : null;
                        sm.canShutdown && showShutdown ? append({
                            "text": "Shutdown",
                            "iconName": "system-shutdown",
                            "action": "shutdown",
                            "confirm": true,
                        }) : null;
                    }
                }

                property var actionMap: {
                    "switch-user": () => sessionsModel.startNewSession(sessionsModel.shouldLock),
                    "lock": () => sm.lock(),
                    "logout": () => sm.requestLogout(0),
                    "reboot": () => sm.requestReboot(0),
                    "suspend": () => sm.suspend(),
                    "hibernate": () => sm.suspendThenHibernate(),
                    "shutdown": () => sm.requestShutdown(0),
                }

                delegate: ActionListDelegate {
                    width: ListView.view.width

                    text: model.text
                    icon.name: model.iconName

                    function handleAction() {
                        model.confirm ? confirmDialog.open() : controlsList.actionMap[model.action]()
                    }
                    
                    Keys.onReturnPressed: {
                        handleAction()
                    }
            
                    MouseArea {
                        anchors.fill: parent
                        onClicked: handleAction()
                    }

                    Dialog {
                        id: confirmDialog
                        modal: true
                        
                        anchors.centerIn: Overlay.overlay
                        implicitWidth: parent.width

                        title: "Confirm action"

                        footer: DialogButtonBox {
                            alignment: Qt.AlignHCenter

                            Button {
                                id: okButton
                                text: qsTr("OK")
                                focus: true
                                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                                Keys.onReturnPressed: {
                                    confirmDialog.accept()
                                }
                            }
                            Button {
                                id: cancelButton
                                text: qsTr("Cancel")
                                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                                Keys.onReturnPressed: {
                                    confirmDialog.reject()
                                }
                            }
                        }

                        contentItem: Item {
                            ColumnLayout {
                                Label {
                                    text: "%1?".arg(model.text)
                                }
                            }
                        }

                        onAccepted: controlsList.actionMap[model.action]()
                        onRejected: controlsList.forceActiveFocus()
     
                        onAboutToShow: {
                            okButton.forceActiveFocus()
                            okButton.focusReason = Qt.TabFocusReason
                        }
                    }
                }
            
                Component.onCompleted: {
                    fullRoot.activated.connect(function() {
                        controlsList.highlightMoveVelocity = 10000
                        controlsList.highlightResizeVelocity = 10000
                        controlsList.currentIndex = controlsList.count - 1
                        controlsList.forceActiveFocus()
                        controlsList.forceLayout()
                        controlsList.highlightMoveVelocity = 800
                    })
                }

            }
        }

        signal activated()

        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) {
                    fullRoot.activated()
                    sessionsModel.reload();
                }
            }
        }

    }
}
