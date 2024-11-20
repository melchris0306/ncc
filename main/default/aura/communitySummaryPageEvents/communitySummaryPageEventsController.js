({
    //Start [CCN-EVE-2173-DV] Add Event Type and Event Name param MelMallorca Nov262022
    doInit : function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.isIE(component);
        var url_string = document.location.href;
        var campaignId = (url_string.split('id=')[1]).slice(0,15);
        var action = component.get("c.getEventsList");
        action.setParams({ 
            campaignId : campaignId,
            eventTypes : component.get("v.eventTypes"),
            eventNames : component.get("v.eventNames")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('mel success');
                // Updated [Namespace Issue Fixes] JaysonLabnao Aug152022
                var resultEvent = helper.cleanUpNamespace(response.getReturnValue());
                component.set('v.EventList', resultEvent);
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);
        
    },
    //End [CCN-EVE-2173-DV] MelMallorca Nov262022
    toggleSort : function(component, event, helper) {  
        component.set("v.isFilter", !component.get("v.isFilter"));
    },
    handleSort : function(component, event, helper) {  
        
        let sortByValue = component.get("v.sortByValue");
        
        console.log('----- ' +sortByValue );
        helper.doSort(component, sortByValue, helper);
    }
})