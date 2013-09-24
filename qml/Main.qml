
/**
 *
 * gPodder QML UI Reference Implementation
 * Copyright (c) 2013, Thomas Perl <m@thp.io>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 *
 */

import QtQuick 2.0
import io.thp.pyotherside 1.0

Item {
    id: pgst
    property bool ready: false

    property real scalef: width / 480

    anchors.fill: parent

    function update(page, x) {
        var index = -1;
        for (var i=0; i<children.length; i++) {
            if (children[i] === page) {
                index = i;
                break;
            }
        }

        children[index-1].opacity = x / width;
    }

    signal downloading(int episode_id)
    signal downloadProgress(int episode_id, real progress)
    signal downloaded(int episode_id)

    function loadPage(filename, properties) {
        var component = Qt.createComponent(filename);
        console.log('error: ' + component.errorString());
        if (properties === undefined) {
            component.createObject(pgst);
        } else {
            component.createObject(pgst, properties);
        }
    }

    Python {
        id: py

        Component.onCompleted: {
            addImportPath('.');

            setHandler('hello', function (version, copyright) {
                console.log('gPodder version ' + version + ' starting up');
                console.log('Copyright: ' + copyright);
            });

            setHandler('downloading', pgst.downloading);
            setHandler('download-progress', pgst.downloadProgress);
            setHandler('downloaded', pgst.downloaded);

            var path = Qt.resolvedUrl('..').substr('file://'.length);
            addImportPath(path);

            // Load the Python side of things
            importModule('main', function() {
                pgst.ready = true;
            });
        }

        onReceived: {
            console.log('unhandled message: ' + data);
        }

        onError: {
            console.log('Python failure: ' + traceback);
        }
    }

    Player {
        id: player
    }

    PBusyIndicator {
        anchors.centerIn: parent
        visible: !pgst.ready
    }

    StartPage {
        id: startPage
        visible: pgst.ready
    }
}
