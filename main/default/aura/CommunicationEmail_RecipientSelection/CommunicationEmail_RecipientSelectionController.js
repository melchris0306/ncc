({
	doInit : function(cmp, event, helper) {
        //console.log('v.ccRecipients', cmp.get('v.ccRecipients'));
        //console.log('v.bccRecipients', cmp.get('v.bccRecipients'));

        helper.getCheckIfRecordIsSurvey(cmp, event, helper);
	},

    // using afterScriptsLoaded instead of doInit to make sure that lodash is loaded before using it.
    afterScriptsLoaded : function(cmp, event, helper){
        if(!cmp.get('v.contactIdList').length){
        	helper.getJourneyParticipants(cmp, event, helper, '');
        }
        else {
            helper.intializeSelectedRecipients(cmp, event, helper);
        }
	},

    handleContactSearch : function(cmp, event, helper){
		helper.getSearchResults(cmp, event, helper);
	},
    
    handleContactSelect : function(cmp, event, helper){
        try{

            //CCN-1004 Jan. 30, 2022 Xen Reyes
            var a = event.getSource();
            var id = a.getLocalId();
            const lookupElement = cmp.find(id).getElement();

            //const lookupElement = cmp.find('lookup').getElement();
            const selection = lookupElement.getSelection();
            //cmp.set('v.initialSelection', selection);

            if(id == 'lookup') {
                cmp.set('v.initialSelection', selection);
                cmp.set('v.contactIdList', _.map(selection, function(item){ return item.id; }));

                //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
                if(cmp.get('v.isFromJourney') || cmp.get('v.isCommunicationHasJourney')) {
                    var lastElement = selection[selection.length - 1];
                    var listParticipants = [], options = cmp.get('v.options');
                    if(options) listParticipants = listParticipants.concat(options);
                    listParticipants.push({ value : lastElement.id, 
                                            label : `${lastElement.title} <${lastElement.subtitle}>`});
                    listParticipants.sort((a, b) => (a.label.toLowerCase() > b.label.toLowerCase()) ? 1 : -1);
                    cmp.set('v.options', listParticipants);
                }
                
            }

            if(id == 'lookup2') {
                cmp.set('v.initialSelectionCC', selection);
                cmp.set('v.contactIdListCC', _.map(selection, function(item){ return item.id; })); 
            }

            if(id == 'lookup3') {
                cmp.set('v.initialSelectionBCC', selection);
                cmp.set('v.contactIdListBCC', _.map(selection, function(item){ return item.id; })); 
            }

        } catch(e) {
            console.log('Error', e);
        }

	},
    
    handleRemoveRecipient : function(cmp, event, helper){

        //CCN-1004 Jan. 30, 2022 Xen Reyes        
        const bucketRecipient = event.currentTarget.name;
        const selectedId = event.currentTarget.dataset.contactid;

        if(bucketRecipient == 'removeTo'){
            let contactRecipientsToBeRemoved = cmp.get('v.contactRecipientsToBeRemoved');
            contactRecipientsToBeRemoved.push(selectedId);
            cmp.set('v.contactRecipientsToBeRemoved', contactRecipientsToBeRemoved);
            cmp.set('v.initialSelection', _.filter(cmp.get('v.initialSelection'), function(item){
                return item.id !== selectedId
            }));
            // using contactIdList attribute as a reference for removing a selected recipient
            cmp.set('v.contactIdList', _.filter(cmp.get('v.contactIdList'), function(item){
                return item !== selectedId;
            }));
        }

        if(bucketRecipient == 'removeCC'){
            let contactRecipientsToBeRemovedCC = cmp.get('v.contactRecipientsToBeRemovedCC');
            contactRecipientsToBeRemovedCC.push(selectedId);
            cmp.set('v.contactRecipientsToBeRemovedCC', contactRecipientsToBeRemovedCC);
            cmp.set('v.initialSelectionCC', _.filter(cmp.get('v.initialSelectionCC'), function(item){
                return item.id !== selectedId
            }));
            // using contactIdList attribute as a reference for removing a selected recipient
            cmp.set('v.contactIdListCC', _.filter(cmp.get('v.contactIdListCC'), function(item){
                return item !== selectedId;
            }));
        }

        if(bucketRecipient == 'removeBCC'){
            let contactRecipientsToBeRemovedBCC = cmp.get('v.contactRecipientsToBeRemovedBCC');
            contactRecipientsToBeRemovedBCC.push(selectedId);
            cmp.set('v.contactRecipientsToBeRemovedBCC', contactRecipientsToBeRemovedBCC);
            cmp.set('v.initialSelectionBCC', _.filter(cmp.get('v.initialSelectionBCC'), function(item){
                return item.id !== selectedId
            }));
            // using contactIdList attribute as a reference for removing a selected recipient
            cmp.set('v.contactIdListBCC', _.filter(cmp.get('v.contactIdListBCC'), function(item){
                return item !== selectedId;
            }));
        }

    },
    
    handleRecipientsChange : function(cmp, event, helper){
        const fieldName = event.getParam('name');
        const emailList = event.getParam('emailList');
        if(fieldName === 'cc'){
            cmp.set('v.ccRecipients', emailList);
            //console.log('ccRecipients', emailList);
        }
        else if(fieldName === 'bcc'){
            cmp.set('v.bccRecipients', emailList);
            //console.log('bccRecipients', emailList);
        }
    },

    handleParticipantChange : function(cmp, event, helper){
        let participantStatus = cmp.get("v.participantStatus");
        helper.getJourneyParticipants(cmp, event, helper, participantStatus);
    },

    handleChangeDualList : function(cmp, event, helper){      
        //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
        cmp.set("v.excludedIds", event.getParam("value"));
        if(cmp.get('v.isFromJourney') || cmp.get('v.isCommunicationHasJourney')) {
            let eventVar = cmp.getEvent("commsEvent");
            eventVar.setParams({ 
                "options" : cmp.get("v.options"),
                "excludedIds" : cmp.get("v.excludedIds")
            });
            eventVar.fire();
        }
    }
    
})