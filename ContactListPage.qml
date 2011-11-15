import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: groupedViewPage

/*            onSearch: {
        if(needle != "")
            peopleModel.searchContacts(needle);
    }*/

    Item {
        id: groupedView
        anchors {top: parent.top; bottom: groupedViewFooter.top; left: parent.left; right: parent.right;}

        GroupedViewPortrait {
            id: gvp
            anchors.fill: parent
            dataModel: peopleModel
            sortModel: proxyModel
            onAddNewContact:{
                window.addPage(myAppNewContact);
            }
        }
    }

    FooterBar { 
        id: groupedViewFooter 
        type: ""
        currentView: gvp
        letterBar: true
        proxy:  proxyModel
        people: peopleModel
        onDirectoryCharacterClicked: {
            // Update landscape view
            gvl.cards.positionViewAtHeader(character)

            // Update portrait view
            for(var i=0; i < gvp.cards.count; i++){
                var c = peopleModel.data(proxyModel.getSourceRow(i), PeopleModel.FirstCharacterRole);
                var exemplar = localeUtils.getExemplarForString(c);
                if(exemplar == character){
                    gvp.cards.positionViewAtIndex(i, ListView.Beginning);
                    break;
                }
            }
        }
    }

    tools: ToolBarLayout {
        ToolItem {
            iconId: "icon-m-common-add"
            onClicked: {
                newContactLoader.source = Qt.resolvedUrl("NewContactSheet.qml")
            }
        }
        ToolItem { iconId: "icon-m-toolbar-view-menu" }
    }

    Loader {
        id: newContactLoader

        // I first tried to use stateChanged from item, but this doesn't seem to
        // be emitted, so let's use a timer to destroy the resource...
        Timer {
            id: sheetUnloadTimer
            interval: 3000 // plenty of time for the animation
            onTriggered: {
                console.log("SHEET: freeing resources")
                newContactLoader.source = ""
            }
        }

        function closeSheet() {
            console.log("SHEET: Closing sheet")
            sheetUnloadTimer.start()
        }

        onLoaded: {
            console.log("SHEET: Opened sheet")
            item.accepted.connect(closeSheet)
            item.rejected.connect(closeSheet)
            item.open()
        }
    }

/*
// FIXME
            onActivating: {
                setAllFilter(false, false);

                if (window.currentFilter == PeopleModel.FavoritesFilter)
                    setFavoritesFilter();
            }
*/
}
