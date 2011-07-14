/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Labs.Components 0.1 as Labs
import MeeGo.App.Contacts 0.1
import TelepathyQML 0.1

Window {
    id: window 
    toolBarTitle: qsTr("Contacts")
    showToolBarSearch: false;
    automaticBookSwitching: false 

    property string currentContactId: ""
    property int currentContactIndex: 0
    property string currentContactName: ""
    property bool callFromRemote: false

    property string filterNew: qsTr("New contact")
    property string filterAll: qsTr("All")
    property string filterFavorites: qsTr("Favorites")
    property string filterWhosOnline: qsTr("Who's online")

    //: Load the details for the selected contact
    property string contextView: qsTr("View")
    property string contextShare: qsTr("Share")
    property string contextEmail: qsTr("Email")

    //: Add favorite flag / add contact to favorites list
    property string contextFavorite: qsTr("Favorite", "Verb")

    //: Remove favorite flag / remove contact from favorites list 
    property string contextUnFavorite: qsTr("Unfavorite")

    property string contextEdit: qsTr("Edit")
    property string contextSave: qsTr("Save")
    property string contextCancel: qsTr("Cancel")
    property string contextDelete: qsTr("Delete")

    //: Confirmation of deletion - ensure the user wants to delete the contact
    property string deleteConfirmation: qsTr("Delete Confirmation")
    property int dateFormat: Qt.DefaultLocaleLongDate

    property string labelGroupedView: qsTr("Contacts")
    property string labelDetailView: qsTr("Contact details")
    property string labelNewContactView: qsTr("New contact")
    property string labelEditView: qsTr("Edit contacts")

    //: If we are unable to get the contact name, use 'this contact' instead
    property string contactname : (window.currentContactName ? window.currentContactName : qsTr("this contact"))
    property string promptStr: qsTr("Are you sure you want to remove %1 from your contacts?").arg(contactname)

    property int animationDuration: 250

    bookMenuModel: [filterAll, filterFavorites, filterWhosOnline];
    bookMenuPayload: [myAppAllContacts, myAppFavContacts, myAppOnlineContacts];

    SaveRestoreState {
        id: srsUnsavedContact
        onSaveRequired: {
            var currentlyActivePage = 0
            switch(window.pageStack.currentPage.pageTitle){
            case filterFavorites:
                currentlyActivePage = 1
                break;
            case filterWhosOnline:
                currentlyActivePage = 2
                break;
            case labelGroupedView:
                currentlyActivePage = 3
                break;
            case labelDetailView:
                currentlyActivePage = 4
                break;
            case labelEditView:
                currentlyActivePage = 5
                break;
            case labelNewContactView:
                currentlyActivePage = 6
                break;
            }

            setValue("contacts.currentlyActivePage", currentlyActivePage)
            setValue("contacts.currentContactIndex", window.currentContactIndex)
            setValue("contacts.currentContactId", window.currentContactId)
            setValue("contacts.currentContactName", window.currentContactName)

            sync()
        }
    }

    overlayItem:  Item {
        id: globalSpaceItems
        anchors.fill: parent

        ModalDialog {
            id:confirmDelete
            cancelButtonText: contextCancel
            showCancelButton: true
            acceptButtonText: contextDelete
            showAcceptButton: true
            title:  deleteConfirmation
            acceptButtonImage: "image://themedimage/widgets/common/button/button-negative"
            acceptButtonImagePressed: "image://themedimage/widgets/common/button/button-negative-pressed"
            anchors {verticalCenter: window.verticalCenter;
                     horizontalCenter: window.horizontalCenter}
            content: Text {
                id: text
                wrapMode: Text.WordWrap
                width: parent.width-60
                text: promptStr
                color: theme_fontColorNormal
                font.pointSize: theme_fontPixelSizeMedium
                anchors {horizontalCenter: parent.horizontalCenter;
                         verticalCenter: parent.verticalCenter}
                smooth: true
                opacity: 1
            }
            onAccepted: {
                peopleModel.deletePerson(window.currentContactId);
                window.switchBook(myAppAllContacts);
            }
        }
    } 

    Component.onCompleted: {
	if (srsUnsavedContact.restoreRequired) {
	    
            var currentlyActivePage = srsUnsavedContact.restoreOnce("contacts.currentlyActivePage", 0)
            var contactIndex = srsUnsavedContact.restoreOnce("contacts.currentContactIndex", window.currentContactIndex)
            var contactId = srsUnsavedContact.restoreOnce("contacts.currentContactId", "")
            var contactName = srsUnsavedContact.restoreOnce("contacts.currentContactName", "")
            window.currentContactId = contactId
            window.currentContactIndex = contactIndex
            window.currentContactName = contactName
	    
            // // Adding first the "main" page
            if (currentlyActivePage == 1) {
                addPage(myAppFavContacts)
            } else if (currentlyActivePage == 2) {
                addPage(myAppOnlineContacts)
            } else if (currentlyActivePage == 4
                       || currentlyActivePage == 5
                       || currentlyActivePage == 6) {
                addPage(myAppAllContacts)
            } else {
                addPage(myAppAllContacts)
            }

            // Add pages that are not "main" pages
	    if (currentlyActivePage == 4) {
		addPage(myAppDetails)
	    } else if (currentlyActivePage == 5) {
		addPage(myAppEdit)
	    } else if (currentlyActivePage == 6) {
                addPage(myAppNewContact)
	    }
	} else { // nothing to restore
	    addPage(myAppAllContacts)
        }
    }

    function getOnlinePeople() {
        var onlinePeoples = [];
        for (var sourceIndex = 0; sourceIndex < peopleModel.rowCount(); sourceIndex++) {
            var uri = peopleModel.data(sourceIndex,
                                       PeopleModel.OnlineAccountUriRole);
            var provider = peopleModel.data(sourceIndex,
                                            PeopleModel.OnlineServiceProviderRole);

            if ((uri.length < 1) || (provider.length < 1))
                continue;

            var account = provider[0].split("\n");
            if (account.length != 2)
                continue;
            account = account[1];

            var buddy = uri[0].split(") ");
            if (buddy.length != 2)
                continue;
            buddy = buddy[1];

            var contactItem = accountsModel.contactItemForId(account, buddy);
            var presence = contactItem.data(AccountsModel.PresenceTypeRole);

            if (presence == TelepathyTypes.ConnectionPresenceTypeAvailable)
                onlinePeoples.push(peopleModel.data(sourceIndex, PeopleModel.ContactRole));
        }
        return onlinePeoples;
    }

    Connections {
        target: mainWindow
        onCall: {
            var cmd = parameters[0];
            //var data = parameters[1]; //data: one of 234-2342 or joe@gmail.com
            //var type = parameters[2]; //type: one of email or phone

            //callFromRemote = true;
            if (cmd == "launchNewContact") {
                //REVISIT: need to pass data and type to NewContactPage
                window.addPage(myAppNewContact);
            }
            else if (cmd == "launchDetailView")
            {
                var contactId = parameters[1];
                if(contactId)
                    window.currentContactIndex = contactId;
                window.addPage(myAppDetails);
            }
        }
    }

    Loader{
        id: dialogLoader
        anchors.fill: parent
    }

    onBookMenuTriggered: {
        if (bookMenuModel[index] == filterAll) {
            peopleModel.setFilter(PeopleModel.AllFilter);
        } else if (bookMenuModel[index] == filterFavorites) {
            peopleModel.setFilter(PeopleModel.FavoritesFilter);
        } else if (bookMenuModel[index] == filterWhosOnline) {
            var onlineIds = getOnlinePeople();
            peopleModel.fetchOnlineOnly(onlineIds);
        }
    }

    //Need empty page place holder for filtering
    Component {
        id: myAppFavContacts
        AppPage {
            id: favContactsPage
            pageTitle: filterFavorites 
        }
    }

    //Need empty page place holder for filtering
    Component {
        id: myAppOnlineContacts
        AppPage {
            id: onlineContactsPage
            pageTitle: filterWhosOnline
        }
    }

    Component {
        id: myAppAllContacts
        AppPage {
            id: groupedViewPage
            pageTitle: labelGroupedView
            Component.onCompleted : {
                window.toolBarTitle = labelGroupedView;
                groupedViewPage.disableSearch = false;
		groupedViewPage.showSearch = false;
            }
            onSearch: {
                if(needle != "")
                    peopleModel.searchContacts(needle);
            }

            Item {
                id: groupedView
                anchors {top: parent.top; bottom: groupedViewFooter.top; left: parent.left; right: parent.right;}

                GroupedViewPortrait{
                    id: gvp
                    anchors.fill: parent
                    dataModel: peopleModel
                    sortModel: proxyModel
                    onAddNewContact:{
                        window.addPage(myAppNewContact);
                    }
                    visible: (window.orientation == 0 || window.orientation == 2) // portrait
                }

                GroupedViewLandscape {
                    id: gvl
                    anchors.fill: parent
                    dataModel: peopleModel
                    sortModel: proxyModel
                    onAddNewContact:{
                        window.addPage(myAppNewContact);
                    }
                    visible: (window.orientation == 1 || window.orientation == 3) // landscape
                }
            }

            FooterBar { 
                id: groupedViewFooter 
                type: ""
                currentView: gvp
                pageToLoad: myAppAllContacts
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
            actionMenuModel: [labelNewContactView]
            actionMenuPayload: [0]

            onActionMenuTriggered: {
                if (selectedItem == 0) {
                    if (window.pageStack.currentPage == groupedViewPage)
                        window.addPage(myAppNewContact);
                }
            }
            onActivating: {
                peopleModel.setFilter(PeopleModel.AllFilter, false);
            }
        }
    }

    Component {
        id: myAppDetails
        AppPage {
            id: detailViewPage
            pageTitle: labelDetailView
            Component.onCompleted : {
                window.toolBarTitle = labelDetailView;
                detailViewPage.disableSearch = true;
            }
            DetailViewPortrait{
                id: detailViewContact
                anchors.fill:  parent
                detailModel: peopleModel
                indexOfPerson: proxyModel.getSourceRow(window.currentContactIndex)
            }
            FooterBar { 
                id: detailsFooter 
                type: "details"
                currentView: detailViewContact
                pageToLoad: myAppEdit
            }
            actionMenuModel: [contextShare, contextEdit]
            actionMenuPayload: [0, 1]

            onActionMenuTriggered: {
                if (selectedItem == 0) {
                    peopleModel.exportContact(window.currentContactId,  "/tmp/vcard.vcf");
                    var cmd = "/usr/bin/meego-qml-launcher --app meego-app-email --fullscreen --cmd openComposer --cdata \"file:///tmp/vcard.vcf\"";
                    appModel.launch(cmd);
                }
                else if (selectedItem == 1) {
                    if (window.pageStack.currentPage == detailViewPage)
                        window.addPage(myAppEdit);
                }
            }
            onActivated: {
                detailViewContact.indexOfPerson = proxyModel.getSourceRow(window.currentContactIndex);
            }
        }
    }

    Component {
        id: myAppEdit
	AppPage {
            id: editViewPage
            pageTitle: labelEditView
            Component.onCompleted : {
                window.toolBarTitle = labelEditView;
                editViewPage.disableSearch = true;
            }
            EditViewPortrait{
                id: editContact
                dataModel: peopleModel
                index: proxyModel.getSourceRow(window.currentContactIndex, "editviewportrait")
                anchors.fill: parent
            }
            FooterBar { 
                id: editFooter 
                type: "edit"
                currentView: editContact
                pageToLoad: myAppAllContacts
            }
            actionMenuModel: (window.currentContactId == 2147483647 ? (editContact.validInput ? [contextSave, contextCancel] : [contextCancel]) : (editContact.validInput ? [contextSave, contextCancel, contextDelete] : [contextCancel, contextDelete]))
            actionMenuPayload: (window.currentContactId == 2147483647 ? (editContact.validInput ? [0, 1] : [0]) : (editContact.validInput ? [0, 1, 2] : [0, 1]))
            onActionMenuTriggered: {
                if(actionMenuModel[selectedItem] == contextSave) {
                    window.switchBook(myAppAllContacts);
                    editContact.contactSave(window.currentContactId);
                }
                else if(actionMenuModel[selectedItem] == contextCancel) {
                    window.switchBook(myAppAllContacts);
                }
                else if(actionMenuModel[selectedItem] == contextDelete) {
                    confirmDelete.show();
                }
            }
            onActivated: {
                editContact.index = proxyModel.getSourceRow(window.currentContactIndex);
                editContact.finishPageLoad();
            }
        }
    }

    Component {
        id: myAppNewContact

        AppPage {
            id: newContactViewPage
            pageTitle: labelNewContactView
            Component.onCompleted : {
                window.toolBarTitle = labelNewContactView;
                newContactViewPage.disableSearch = true;
            }
            NewContactViewPortrait{
                id: newContact
                dataModel: peopleModel
            }
            FooterBar { 
                id: newFooter 
                type: "new"
                currentView: newContact
                pageToLoad: myAppAllContacts
            }
            actionMenuModel: (newContact.validInput) ? [contextSave, contextCancel] : [contextCancel]
            actionMenuPayload: (newContact.validInput) ? [0, 1] : [0]

            onActionMenuTriggered: {
                if(actionMenuModel[selectedItem] == contextSave) {
                    window.switchBook(myAppAllContacts);
                    newContact.contactSave();
                }else if(actionMenuModel[selectedItem] == contextCancel) {
                    window.switchBook(myAppAllContacts);
                }
            }

            onActivated: {
                newContact.finishPageLoad();
            }
        }
    }

    PeopleModel{
        id: peopleModel
    }

    ProxyModel{
        id: proxyModel
        Component.onCompleted:{
            proxyModel.setModel(peopleModel); //Calls setSorting() on model
        }
    }

    Labs.ApplicationsModel{
        id: appModel
    }
}

