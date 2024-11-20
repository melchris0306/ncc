({
    retrieveContactsJourney : function(component, contact_Id, basecampId) {
        let retrieveContactJourney = component.get("c.getContactJourney");
        
        // START: CCN-NAV-427-DV
        retrieveContactJourney.setParams({
            contactId: contact_Id,
            basecampId: basecampId
        });
        // END: CCN-NAV-427-DV

        retrieveContactJourney.setCallback(this, function (response) {
            let state = response.getState();
            console.log('!@# Return: ' + state);
            console.log('!@# Return: ' + JSON.stringify(response.getError()));
            if (state === "SUCCESS") {
                let contactJourney = response.getReturnValue();
                console.log('!@# contactJourney: ' + JSON.stringify(contactJourney));
                component.set('v.contactHasJourney', contactJourney.hasJourney);
                component.set('v.JourneyURL', contactJourney.communityURL);
                let sPageURL = decodeURIComponent(window.location.search.substring(1));
                let journeyURL;

                component.set("v.showSpinner", false);
                
                if(contactJourney.journeyId !== undefined){
                    // START: CCN-NAV-427-DV
                    journeyURL = component.get('v.JourneyURL') + '/s/navigator-journey?journeyId='+ contactJourney.journeyId + '&' + sPageURL;
                    location.href = journeyURL;
                    //location.href = contactJourney.communityURL;
                    // END: CCN-NAV-427-DV
                }else{
                    component.set('v.listJourney', contactJourney.lstJourney);
                    console.log('!@# lstJourney size : ' + contactJourney.lstJourney.length);
                    let JourneyRecords = [];
                    let journeyList = component.get("v.listJourney");
                    for(let i = 0; i < journeyList.length; i++){
                        console.log('!@# Journey Id: ' + journeyList[i].Id );
                        // START: CCN-NAV-427-DV
                        //let jId = journeyList[i].Id;
                        //journeyURL = component.get('v.JourneyURL') + '/s/navigator-journey?journeyId='+ jId + '&' + sPageURL;
                        JourneyRecords.push({
                            //value: journeyURL,
                            value: journeyList[i].Journey_URL__c,
                            key: journeyList[i].Journey__r.Name
                        });
                        console.log('!@# New URL: ' + journeyURL);
                        // END: CCN-NAV-427-DV

                    }
                    component.set('v.ListJourneyRecords', JourneyRecords);
                }
            }
        });
        $A.enqueueAction(retrieveContactJourney);

    }
})