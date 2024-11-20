({
	getSearchResults : function(cmp, event, helper) {

        //CCN-1004 Jan. 30, 2022 Xen Reyes
        var a = event.getSource();
        var id = a.getLocalId();
        //const lwcLookup = cmp.find('lookup').getElement();
        const lwcLookup = cmp.find(id).getElement();
        
        let keyword = event.getParam('searchTerm');
        let idList = event.getParam('selectedIds');
        const action = cmp.get("c.searchContactRecipient");
        action.setParams({ searchTerm : keyword, selectedIds : idList });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const returnValue = response.getReturnValue();
                // get a reference of the LWC lookup element and use the lookup's setSearchResults
                // to set Search Results based on the keyword
                lwcLookup.setSearchResults(returnValue);
            }else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        
        $A.enqueueAction(action);	
    },
    
    getJourneyParticipants : function(cmp, event, helper, filterString){
        const recordId = cmp.get('v.recordId');
        const action = cmp.get("c.getJourneyParticipants");
        action.setParams({ recordId : recordId, filter : filterString});
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const returnValue = response.getReturnValue();
                cmp.set('v.initialSelection', _.map(returnValue, function(item){
                          return { icon: "standard:contact", 
                          		   id: item.Id, 
                          		   sObjectType: "Contact", 
                                   subtitle: item.Name,
                                   title: item.Email };
                }));
                
                cmp.set('v.contactIdList', _.map(cmp.get('v.initialSelection'), function(item){ return item.id; }));
                cmp.set('v.participantList', cmp.get('v.contactIdList'));
                cmp.set('v.isLoading', false);
                
                //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
                if(cmp.get('v.isFromJourney') || cmp.get('v.isCommunicationHasJourney')) {
                    var listParticipants = [];
                    for (const element of returnValue) {
                        listParticipants.push({ value : element.Id, 
                                                label : `${element.Name} <${element.Email}>`});                        
                    }
                    listParticipants.sort((a, b) => (a.label.toLowerCase() > b.label.toLowerCase()) ? 1 : -1);
                    cmp.set("v.options", listParticipants);
                }

            } else {
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        
        $A.enqueueAction(action);	
    },

    intializeSelectedRecipients : function(cmp, event, helper){

        //CCN-1004 Jan. 30, 2022 Xen Reyes
        const initialLookupIds = cmp.get('v.contactIdList')
        const action = cmp.get("c.getContactLookupByIds");
        action.setParams({ initialLookupIds : initialLookupIds });
        action.setCallback(this, function(response) {
            const state = response.getState();
            //console.log(state);
            if(state === "SUCCESS"){
                const returnValue = response.getReturnValue();
                cmp.set('v.initialSelection', returnValue);
                //console.log('Initial Selection', JSON.stringify(cmp.get('v.initialSelection')));

                //CCN-COM-1214-DV XEN REYES Apr. 14, 2022
                if(cmp.get('v.isFromJourney') || cmp.get('v.isCommunicationHasJourney')) {

                    //EXCLUDED PARTICIPANTS (UPON OPENING DRAFT)
                    if(cmp.get("v.excludedRecipientsDefault")){
                        var excl = JSON.parse(cmp.get("v.excludedRecipientsDefault"));
                        cmp.set('v.defaultValuesIds', _.map(excl, function(item){ return item.value; }));
                    }

                    //EXCLUDED PARTICIPANTS (WITHIN THE BUILDER)
                    if(cmp.get("v.excludedIds")){
                        let defList = cmp.get("v.defaultValuesIds");
                        let excList = cmp.get("v.excludedIds");
                        let newList = [...new Set([...defList,...excList])];
                        cmp.set("v.defaultValuesIds", newList);
                    }
                    
                    if(cmp.get("v.defaultValuesIds")){
                        let eventVar = cmp.getEvent("commsEvent");
                        eventVar.setParams({ 
                            "excludedIds" : cmp.get("v.defaultValuesIds")
                        });
                        eventVar.fire();
                    }

                    //INCLUDED PARTICIPANTS
                    var listParticipants = [];
                    for (const element of returnValue) {
                        listParticipants.push({ value : element.id, 
                                                label : `${element.title} <${element.subtitle}>`});                        
                    }
                    listParticipants.sort((a, b) => (a.label.toLowerCase() > b.label.toLowerCase()) ? 1 : -1);
                    cmp.set("v.options", listParticipants);
                }

            } else {
                helper.showToastError(helper.logError(response.getError()));
            }

            //LOAD CC CONTACTS
            const initialLookupIdsCC = cmp.get('v.contactIdListCC')
            const actionCC = cmp.get("c.getContactLookupByIds");
            actionCC.setParams({ initialLookupIds : initialLookupIdsCC });
            actionCC.setCallback(this, function(responseCC) {
                const stateCC = responseCC.getState();
                if(stateCC === "SUCCESS"){
                    const returnValue = responseCC.getReturnValue();
                    cmp.set('v.initialSelectionCC', returnValue);
                    //console.log('Initial Selection CC', JSON.stringify(cmp.get('v.initialSelectionCC')));
                } else {
                    helper.showToastError(helper.logError(responseCC.getError()));
                }

                //LOAD BCC CONTACTS
                const initialLookupIdsBCC = cmp.get('v.contactIdListBCC')
                const actionBCC = cmp.get("c.getContactLookupByIds");
                actionBCC.setParams({ initialLookupIds : initialLookupIdsBCC });
                actionBCC.setCallback(this, function(responseBCC) {
                    const stateBCC = responseBCC.getState();
                    if(stateBCC === "SUCCESS"){
                        const returnValue = responseBCC.getReturnValue();
                        cmp.set('v.initialSelectionBCC', returnValue);
                        //console.log('Initial Selection BCC', JSON.stringify(cmp.get('v.initialSelectionBCC')));
                    } else {
                        helper.showToastError(helper.logError(responseBCC.getError()));
                    }
                    cmp.set('v.isLoading', false);
                });
                $A.enqueueAction(actionBCC);

            });
            $A.enqueueAction(actionCC);

        });
        $A.enqueueAction(action);
    },

    showToastError : function(error) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type" : "error",
            "message": error
        });
        toastEvent.fire();
    },
    
    logError : function(errors){
        if (errors) {
            if (errors[0] && errors[0].message) {
                // log the error passed in to AuraHandledException
                let errorMessage = "Error message: " + errors[0].message
                console.log(errorMessage);
                return errorMessage;
            }
            else{
                console.log("Unknown error", JSON.stringify(errors));
                return "Unknown error", JSON.stringify(errors);
            }
        } else {
        	console.log("Unknown error", JSON.stringify(errors));
            return "Unknown error", JSON.stringify(errors);
        }
	},

    getCheckIfRecordIsSurvey : function(component, event, helper){
        const record = component.get("v.recordId");
        const action = component.get("c.isSurveyRecord");

        action.setParams({ recordId : record });
        action.setCallback(this, function(response) {
            const state = response.getState();
            if(state === "SUCCESS"){
                const returnValue = response.getReturnValue();
                component.set('v.isSurveyRecord', returnValue);
            } else {
                helper.showToastError(helper.logError(response.getError()));
            }
        });

        $A.enqueueAction(action);	
    }
})