//
//  InteractiveWindow.qml
//
//  Created by Thijs Wenker on 2018-06-25
//  Copyright 2018 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import QtQuick 2.3
import QtQuick.Window 2.3;

import "windows" as Windows
import "controls"
import controlsUit 1.0 as Controls
import "styles"
import stylesUit 1.0

Windows.Window {
    id: root;
    HifiConstants { id: hifi }
    title: "InteractiveWindow";
    resizable: true;
    // Virtual window visibility
    shown: true;
    focus: true;
    property var channel;
    // Don't destroy on close... otherwise the JS/C++ will have a dangling pointer
    destroyOnCloseButton: false;

    signal selfDestruct();

    property var additionalFlags: 0;
    property var overrideFlags: 0;

    property var source;
    property var dynamicContent;
    property var nativeWindow;

    // custom visibility flag for interactiveWindow to proxy virtualWindow.shown / nativeWindow.visible
    // property var interactiveWindowVisible: true;

    property point interactiveWindowPosition;

    property size interactiveWindowSize;

    // Keyboard control properties in case needed by QML content.
    property bool keyboardEnabled: false;
    property bool keyboardRaised: false;
    property bool punctuationMode: false;

    property int presentationMode: 0;

    property var initialized: false;

    property var windowsFlags = Qt.Window |
            Qt.WindowTitleHint |
            Qt.WindowSystemMenuHint |
            Qt.WindowCloseButtonHint |
            Qt.WindowMaximizeButtonHint |
            Qt.WindowMinimizeButtonHint;

    // only use the always on top feature for non Windows OS
    property var nonWindowsFlags = windowsFlags |= Qt.WindowStaysOnTopHint;
    flags: root.overrideFlags || (Qt.platform.os !== "windows" && (root.additionalFlags & Desktop.ALWAYS_ON_TOP) ? nonWindowsFlags : windowsFlags;

    onSourceChanged: {
        if (dynamicContent) {
            dynamicContent.destroy();
            dynamicContent = null;
        }
        QmlSurface.load(source, contentHolder, function(newObject) {
            dynamicContent = newObject;
            updateInteractiveWindowSize();
            if (dynamicContent && dynamicContent.anchors) {
                dynamicContent.anchors.fill = contentHolder;
            }
        });
    }

    function updateInteractiveWindowPosition() {
            x = interactiveWindowPosition.x;
            y = interactiveWindowPosition.y;
    }

    function updateInteractiveWindowSize() {
        root.width = interactiveWindowSize.width;
        root.height = interactiveWindowSize.height;
        contentHolder.width = interactiveWindowSize.width;
        contentHolder.height = interactiveWindowSize.height;
    }

    // Handle message traffic from the script that launched us to the loaded QML
    function fromScript(message) {
        if (root.dynamicContent && root.dynamicContent.fromScript) {
            root.dynamicContent.fromScript(message);
        }
    }

    function show() {
        raiseWindow();
    }

    // TODO get rid of redundant fns ^^ VV
    function raiseWindow() {
        raise();
    }

    // Handle message traffic from our loaded QML to the script that launched us
    signal sendToScript(var message);

    // Children of this InteractiveWindow Item are able to request a new width and height
    // for the parent Item (this one) and its associated C++ InteractiveWindow using these methods.
    function onRequestNewWidth(newWidth) {
        interactiveWindowSize.width = newWidth;
        updateInteractiveWindowSize();
    }
    function onRequestNewHeight(newHeight) {
        interactiveWindowSize.height = newHeight;
        updateInteractiveWindowSize();
    }
    
    // These signals are used to forward key-related events from the QML to the C++.
    signal keyPressEvent(int key, int modifiers);
    signal keyReleaseEvent(int key, int modifiers);

    onDynamicContentChanged: {
        if (dynamicContent && dynamicContent.sendToScript) {
            dynamicContent.sendToScript.connect(sendToScript);
        }

        if (dynamicContent && dynamicContent.requestNewWidth) {
            dynamicContent.requestNewWidth.connect(onRequestNewWidth);
        }

        if (dynamicContent && dynamicContent.requestNewHeight) {
            dynamicContent.requestNewHeight.connect(onRequestNewHeight);
        }

        if (dynamicContent && dynamicContent.keyPressEvent) {
            dynamicContent.keyPressEvent.connect(keyPressEvent);
        }

        if (dynamicContent && dynamicContent.keyReleaseEvent) {
            dynamicContent.keyReleaseEvent.connect(keyReleaseEvent);
        }
    }

    onXChanged: {
        if (presentationMode === Desktop.PresentationMode.VIRTUAL) {
            interactiveWindowPosition = Qt.point(x, interactiveWindowPosition.y);
        }
    }

    onYChanged: {
        if (presentationMode === Desktop.PresentationMode.VIRTUAL) {
            interactiveWindowPosition = Qt.point(interactiveWindowPosition.x, y);
        }
    }

    onWidthChanged: {
        if (presentationMode === Desktop.PresentationMode.VIRTUAL) {
            interactiveWindowSize = Qt.size(width, interactiveWindowSize.height);
        }
    }

    onHeightChanged: {
        if (presentationMode === Desktop.PresentationMode.VIRTUAL) {
            interactiveWindowSize = Qt.size(interactiveWindowSize.width, height);
        }
    }

    onWindowClosed: {
        if ((root.additionalFlags & Desktop.CLOSE_BUTTON_HIDES) !== Desktop.CLOSE_BUTTON_HIDES) {
            selfDestruct();
        }
    }

    Rectangle {
        color: hifi.colors.baseGray
        anchors.fill: parent
    }

    Item {
        id: contentHolder
        anchors.fill: parent
    }
}
