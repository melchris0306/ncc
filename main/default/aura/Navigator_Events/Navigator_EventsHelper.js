({
    retrieveContactsEvent : function(component, contact_Id, basecampId) {
    
        let retrieveContactEvents = component.get("c.getContactEvents");
        //START: CCN-NAV-428-DV
        retrieveContactEvents.setParams({
            contactId: contact_Id,
            //strFilter: component.get("v.filter"),
            basecampId: basecampId
        });
        //END: CCN-NAV-428-DV

        retrieveContactEvents.setCallback(this, function (response) {
            let state = response.getState();
            //START: CCN-NAV-428-DV
            if (state === "SUCCESS") {
                let contactEvent = response.getReturnValue();
                console.log('meltest');
                console.log(JSON.stringify(contactEvent));
                component.set('v.contactHasEvent', contactEvent.hasEvent);
                //component.set('v.EventURL', contactEvent.communityURL);
                //let sPageURL = decodeURIComponent(window.location.search.substring(1));
                //let eventURL;

                component.set("v.showSpinner", false);
                
                /*if(contactEvent.eventId !== undefined){
                    eventURL = component.get('v.EventURL') + '/s/navigator-events?id='+ contactEvent.eventId + '&' + sPageURL;
                    //location.href = eventURL;
                }else{*/
                component.set('v.listEvents', contactEvent.eventList);
                let EventRecords = [];
                for(let i = 0; i < contactEvent.eventList.length; i++){
                    /*let eId = eventList[i].Event_Id__c;
                    eventURL = component.get('v.EventURL') + '/s/navigator-events?id='+ eId + '&' + sPageURL;*/
                    EventRecords.push({
                        value: contactEvent.eventList[i].Event_Page_URL__c,
                        key: contactEvent.eventList[i].Name
                    });
                }
                
                component.set('v.ListEventRecords', EventRecords);
                //}
            }
            else{
                let error = response.getError();
                console.log('getContactEvents state'+JSON.stringify(error));
            }
            //END: CCN-NAV-428-DV
        });
        $A.enqueueAction(retrieveContactEvents);
    }
})