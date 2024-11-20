({
    upsertEvent : function(component, evObj, callback) {
        var action = component.get("c.upsertEvents");
        component.set('v.proposeStartDateTimeField','Propose_Start_Date_Time__c');
        component.set('v.proposeEndDateTimeField','Propose_End_Date_Time__c');
        action.setParams({ 
            "sEventObj": JSON.stringify(evObj),
            "sObjectName" : component.get("v.sObjectName"),
            "titleField" : component.get("v.titleField"),
            "startDateTimeField" : component.get("v.proposeStartDateTimeField"),
            "endDateTimeField" : component.get("v.proposeEndDateTimeField"),
            //"startDateTimeField" : component.get("v.startDateTimeField"),
            //"endDateTimeField" : component.get("v.endDateTimeField"),
            "descriptionField" : component.get("v.descriptionField"),
            "userField" : component.get("v.userField")
        });
        
        if (callback) {
            action.setCallback(this, callback);
        }
        else{
            //Added error handling for [CCN-1148] Feb042022
            action.setCallback(this, function(res){
                console.log('Callback Response:');
                var state = res.getState();
                if(state == 'SUCCESS'){
                    console.log(res.getReturnValue());
                }
                else if(state == 'ERROR'){
                    console.error(res.getError()[0].message);
                }
                else{
                    console.warning(`State: ${state}`);
                }
            });
        }
        
        $A.enqueueAction(action);
    },
    deleteEvent : function(component, event, eventId, callback){
        var action = component.get("c.deleteEvent");
        
        action.setParams({ 
            "eventId": eventId,
            "sObjectName" : component.get("v.sObjectName"),
            "titleField" : component.get("v.titleField"),
            "startDateTimeField" : component.get("v.startDateTimeField"),
            "endDateTimeField" : component.get("v.endDateTimeField"),
            "descriptionField" : component.get("v.descriptionField"),
            "userField" : component.get("v.userField")
        });
        
        if (callback) {
            action.setCallback(this, callback);
        }
        
        $A.enqueueAction(action);
        component.set('v.loaded',true);
        var delay=1000; // 1 seconds delay
        setTimeout(function() {
            $A.get('e.force:refreshView').fire();
        }, delay);
        component.set('v.loaded',false);
    },
    pullRecId : function(component, event){
        const queryString = decodeURIComponent(window.location.search);  
        var urlEventId = (queryString.split('id=')[1]).split('&')[0];
        var action = component.get("c.getRecId");
        action.setParams({ "eventId": urlEventId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                component.set("v.eventRecId",response.getReturnValue());
            } else if (state === "INCOMPLETE") {
                // do something
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    insertEvent : function(component, evObj, callback)	{
        var action = component.get("c.insertSession");
        var timezoneAbbr = component.get("v.timezoneAbbr");
      
        evObj.timezoneAbbr = timezoneAbbr;
        
        action.setParams({ 
            "sEventObj": JSON.stringify(evObj),
            "sObjectName" : component.get("v.sObjectName"),
            "titleField" : component.get("v.titleField"),
            "startDateTimeField" : component.get("v.proposeStartDateTimeField"),
            "endDateTimeField" : component.get("v.proposeEndDateTimeField"),
            //"startDateTimeField" : component.get("v.startDateTimeField"),
            //"endDateTimeField" : component.get("v.endDateTimeField"),
            "descriptionField" : component.get("v.descriptionField"),
            "userField" : component.get("v.userField"),
            "eventRecId" : component.get("v.eventRecId")
        });
        
        if (callback) {
            action.setCallback(this, callback);
        }
        
        $A.enqueueAction(action);
    },
    openModal : function(component, event) {
        component.set("v.isOpen", true);
    },
    closeModal : function(component, event) {
        component.set("v.isOpen", false);
    },
    saveAndRefresh : function(component,event){
        component.set('v.loaded',true);
        var delay=1500; // 1 seconds delay
        setTimeout(function() {
            $A.get('e.force:refreshView').fire();
        }, delay);
        component.set('v.loaded',false);
    },
    openMassSessionPage : function(component,event){
        const queryString = decodeURIComponent(window.location.search);
        var urlEventId = (queryString.split('id=')[1]).split('&')[0];
        var eUrl= $A.get("e.force:navigateToURL");
        var url = location.href;  // window.location.href;
        var pathname = location.pathname;  // window.location.pathname;
        var index1 = url.indexOf(pathname);
        var index2 = url.indexOf("/", index1 + 1);
        var baseLocalUrl = url.substr(0, index2) + '/s/mass-session-sign-up?id=' + urlEventId + '&sessionid=' + component.get('v.idVal');
        eUrl.setParams({
            "url": baseLocalUrl
        });
        eUrl.fire();
    },
    getEventTimezone : function(component, event, helper) {
        // CCN-EVE-3113-DV - Gian: Created new function to get the event object's timezone to be set as default timezone per session created
        const urlParams = new URLSearchParams(window.location.search);
        var action = component.get("c.getEventTimeZone");
    	var eventIdQueryParam = urlParams.get('id');
        action.setParams({
            "eventId": eventIdQueryParam
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.timezoneAbbr", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})