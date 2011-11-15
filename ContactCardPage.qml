import QtQuick 1.1
import com.nokia.meego 1.0
import MeeGo.App.Contacts 0.1

Page {
    id: detailViewPage

    ContactCardContentWidget {
        id: detailViewContact
        anchors.fill:  parent
        detailModel: peopleModel
        indexOfPerson: proxyModel.getSourceRow(window.currentContactIndex)
    }
/*            actionMenuModel: [contextShare, contextEdit]
    actionMenuPayload: [0, 1]

    onActionMenuTriggered: {
        if (selectedItem == 0) {
            console.log("TODO this needs fixing (contacts app, ask Robin)")
//                    peopleModel.exportContact(window.currentContactId,  "/tmp/vcard.vcf");
//                    var cmd = "/usr/bin/meego-qml-launcher --app meego-app-email --fullscreen --cmd openComposer --cdata \"file:///tmp/vcard.vcf\"";
//                    appModel.launch(cmd);
        }
        else if (selectedItem == 1) {
            if (window.pageStack.currentPage == detailViewPage)
                window.addPage(myAppEdit);
        }
    }
    onActivated: {
        detailViewContact.indexOfPerson = proxyModel.getSourceRow(window.currentContactIndex);
    }
*/
    tools: ToolBarLayout {
        ToolItem {
            iconId: "icon-m-toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolItem {
            iconId: "icon-m-toolbar-view-menu";
            onClicked: {
                console.log("TODO menu")
                contactEditor.openSheet()
            }
        }
    }

    Loader {
        id: contactEditor

        function openSheet() {
            if (sheetUnloadTimer.running)
                sheetUnloadTimer.stop()

            var sourceUri = Qt.resolvedUrl("EditContactSheet.qml")
            if (contactEditor.source != sourceUri)
                contactEditor.source = sourceUri;
            else
                item.open(); // already connected, just reopen it
        }

        Timer {
            id: sheetUnloadTimer
            interval: 60000 // leave it a while in case they want it again
            onTriggered: {
                console.log("SHEET: freeing resources")
                contactEditor.source = ""
            }
        }

        function closeSheet() {
            sheetUnloadTimer.start()
        }

        onLoaded: {
            item.accepted.connect(closeSheet)
            item.rejected.connect(closeSheet)
            item.open()
        }
    }

}
