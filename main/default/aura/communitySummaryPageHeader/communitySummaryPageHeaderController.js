({
    scriptsLoaded : function(component, event, helper) {
        // Updated [Namespace Issue Fixes] JaysonLabnao Aug152022
        // Updated [CCN-EVE-2173-DV] MelMallorca Nov262022
        helper.getCampaign(component, event, helper);
        helper.getEvents(component, event, helper, true, true);
        helper.setEventType(component, event, helper);
    },
    //Start Added [CCN-EVE-2173-DV] MelMallorca Nov262022
    handleEvents : function(component, event, helper) {
        component.set("v.eventNameValue", []);
        helper.getEvents(component, event, helper, true, false);
    },
    toggleFilter : function(component, event, helper) {  
        component.set("v.isFilter", !component.get("v.isFilter"));
    },
    //Start Added [CCN-EVE-3026-DV] MelMallorca May292023
    /*
    selectAll : function(component, event, helper) { 
        component.set("v.eventNameValue", component.get("v.eventNames"));
    },*/
    deselectAll : function(component, event, helper) { 
        component.set("v.eventNameValue", []);
        component.set("v.filterByValue", []);
        helper.getEvents(component, event, helper, true, false);
    },
    applyFilter : function(component, event, helper) { 
        component.set("v.eventNamesApply", component.get("v.eventNameValue"));
        component.set("v.eventsMapApply", component.get("v.eventsMap"));
        helper.getEvents(component, event, helper, false, true); // Updated by Jayson Labnao [CCN-2450] January42023
    },
    //End Added [CCN-EVE-2173-DV] MelMallorca Nov262022
})