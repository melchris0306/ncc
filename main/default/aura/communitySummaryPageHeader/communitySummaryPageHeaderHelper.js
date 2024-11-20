({
    //Start [CCN-EVE-2173-DV] Add Param MelMallorca Nov262022
    getEvents : function(component, event, helper, isFilter, isLoadMap) {
    //End [CCN-EVE-2173-DV] MelMallorca Nov262022
        //CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
        var action = component.get("c.getEventsExceptShowToLinks");
        //CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
        const queryString = decodeURIComponent(window.location.search);
        var eventId = (queryString.split('id=')[1]).split('&')[0];
        component.set('v.eventId', eventId);
        
        //Start [CCN-EVE-2173-DV] Add Event Type and Event Name Param MelMallorca Nov262022
        action.setParams({ 
            sObjectName : component.get("v.sObjectName"),
            titleField : component.get("v.titleField"),
            startDateTimeField : component.get("v.startDateTimeField"),
            endDateTimeField : component.get("v.endDateTimeField"),
            descriptionField : component.get("v.descriptionField"),
            userField : component.get("v.userField"),
            filterByUserField : component.get("v.filterByUserField"),
            eventId : component.get("v.eventId"),
            eventType : component.get("v.filterByValue"),
            eventName : component.get("v.eventNameValue")
        });
        //End [CCN-EVE-2173-DV] MelMallorca Nov262022
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.eventsMap",response.getReturnValue());
                //Start [CCN-EVE-2173-DV] MelMallorca Nov262022
                let eventListMap = component.get("v.eventsMap");
                var eventList = [];
                var eventNames = [];  
                for (var i = 0; i < eventListMap.length; i++) {    
                    eventList.push({    
                        label: eventListMap[i].eventName,    
                        value: eventListMap[i].eventName    
                    });    
                    eventNames.push(eventListMap[i].eventName);
                } 
                component.set("v.eventNames", eventNames);
                
                if(isFilter){
                    component.set("v.eventNameOptions", eventList);
                }
                if(isLoadMap){
                    component.set("v.eventsMapApply", eventListMap);
                }
                //End [CCN-EVE-2173-DV] MelMallorca Nov262022
                
                var defaultDte = eventListMap[0].startDateTime.substring(0,10);
                if(defaultDte != null && defaultDte != undefined){
                    component.set("v.defaultDate", defaultDte);
                }
            } else if (state === "INCOMPLETE") {
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error("Error message: " + errors[0].message); // Updated by Jayson Labnao [CCN-2450] January42023
                    }
                } else {
                    console.error("Unknown error"); // Updated by Jayson Labnao [CCN-2450] January42023
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    getCampaign : function(component, event, helper) {
        var action = component.get("c.getCampaign");
        const queryString = decodeURIComponent(window.location.search);
        var campaignId = (queryString.split('id=')[1]).split('&')[0];
        action.setParams({ 
            campaignId : campaignId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // updated [Namespace Issue Fixes] JaysonLabnao Aug152022
                component.set("v.campaignObject", helper.cleanUpNamespace(response.getReturnValue()));
            } else if (state === "INCOMPLETE") {
                // do something
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error("Error message: " + errors[0].message); // Updated by Jayson Labnao [CCN-2450] January42023
                    }
                } else {
                    console.error("Unknown error"); // Updated by Jayson Labnao [CCN-2450] January42023
                }
            }
        });
        $A.enqueueAction(action);
    },
    // Created [Namespace Issue Fixes] JaysonLabnao Aug152022
    cleanUpNamespace : function(jsonData){
        let responseStr = JSON.stringify(jsonData);
        
        if(responseStr.includes('beta_ccn__')){
            responseStr = responseStr.replaceAll('beta_ccn__', '');
        }
        if(responseStr.includes('compass_cn__') ){
            responseStr = responseStr.replaceAll('compass_cn__', '');
        }
        
        return JSON.parse(responseStr);
    },
    
    //Start [CCN-EVE-2173-DV] Set Eventy Type in Radio MelMallorca Nov252022
    setEventType : function(component, event, helper){
        
        let action = component.get('c.getEventTypes');
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                //let resultMap = helper.cleanUpNamespace(JSON.parse(response.getReturnValue()));
                let result = response.getReturnValue();
                var eventTypesMap = [];    
                var eventTypes = [];    
                for (var i = 0; i < result.length; i++) {    
                    eventTypesMap.push({    
                        label: result[i],    
                        value: result[i]    
                    });    
                    eventTypes.push(result[i]);
                }    
                component.set("v.filterByOptions", eventTypesMap);
                component.set("v.eventTypes", eventTypes);
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Error on Updating Parking Lots'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                
                this.showToast('Oops!', message, "error", "pester");
                component.set("v.showSpinner", false);
            }
                else {
                    console.error("Failed with state: " + state); // Updated by Jayson Labnao [CCN-2450] January42023
                    this.showToast('Oops!', "Something's not right. Please contact the administrator for help.", "error", "pester");
                    component.set("v.showSpinner", false);
                }
        });
        
        $A.enqueueAction(action);
        //End [CCN-EVE-2173-DV] MelMallorca Nov252022
    },
    
})