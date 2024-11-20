({
	getEvents : function(component, event,helper, onInit) {
		var action = component.get("c.getEvents");
        const queryString = decodeURIComponent(window.location.search);
        var eventId = (queryString.split('id=')[1]).split('&')[0];
        component.set('v.eventId', eventId);
        
        action.setParams({ 
            sObjectName : component.get("v.sObjectName"),
            titleField : component.get("v.titleField"),
            startDateTimeField : component.get("v.startDateTimeField"),
            endDateTimeField : component.get("v.endDateTimeField"),
            descriptionField : component.get("v.descriptionField"),
            userField : component.get("v.userField"),
            filterByUserField : component.get("v.filterByUserField"),
            eventId : component.get("v.eventId"), 
            sessionId: component.get("v.selectedSessionIds"),
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                
                /* Start CCN-EVE-3580-DV: Von Pernicia*/
                if (onInit) {
                    component.set("v.eventsSearchOrigMap",response.getReturnValue());
                    component.set("v.eventsSearchMap",response.getReturnValue());
                }
                /* End CCN-EVE-3580-DV: Von Pernicia*/
                component.set("v.eventsMap",response.getReturnValue());
                console.log(response.getReturnValue());
                var eventListMap = component.get("v.eventsMap");
                var defaultDte = eventListMap[0].startDateTime.substring(0,10);
                component.set("v.eventName", eventListMap[0].eventName);
                if(defaultDte != null && defaultDte != undefined){
                    component.set("v.defaultDate", defaultDte);
                }
                else{
                    //component.set("v.defaultDate", moment().format("YYYY-MM-DD"));
                }
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

    /* Start CCN-EVE-3580-DV: Von Pernicia*/
    search: function(component, event,helper) {

        let eventsSearchOrigMap = component.get("v.eventsSearchOrigMap");
        let selectedSessionIds = component.get("v.selectedSessionIds");
        let searchValue =  event.getSource().get("v.value");
        let eventsSearchMap = [];

        for (let i = 0; i < eventsSearchOrigMap.length; i++) {

            if (selectedSessionIds.includes(eventsSearchOrigMap[i].Id)) {
                eventsSearchOrigMap[i]["checked"] = true;
            } else {
                eventsSearchOrigMap[i]["checked"] = false;
            }

            let title = eventsSearchOrigMap[i].title;

            if (title.toUpperCase().includes(searchValue.toUpperCase())) {
                eventsSearchMap.push(eventsSearchOrigMap[i]);
            }
        }

        component.set("v.eventsSearchOrigMap", eventsSearchOrigMap);
        component.set("v.eventsSearchMap", eventsSearchMap);
    },

    applyFilter: function(component, event, helper) {

        this.getEvents(component, event, helper, false);
    },

    selectedSession: function(component, event, helper) {

        let selectedSession = component.find("selectedSession");
        let selectedSessionIds = [];

        for (let i = 0; i < selectedSession.length; i++) {

            let selectedChecbox = selectedSession[i];

            if (selectedChecbox.get("v.checked")) {
                selectedSessionIds.push(selectedChecbox.get("v.name"));
            }
        }

        component.set("v.selectedSessionIds", selectedSessionIds);
    },

    clearSelectedSession: function(component, event, helper) {

        let eventsSearchOrigMap = component.get("v.eventsSearchOrigMap");
       
        for (let i = 0; i < eventsSearchOrigMap.length; i++) {
           
            eventsSearchOrigMap[i]["checked"] = false;
        }

        component.find("sessionSearch").set("v.value", "");
        component.set("v.eventsSearchOrigMap", eventsSearchOrigMap);
        component.set("v.eventsSearchMap", eventsSearchOrigMap);
        component.set("v.selectedSessionIds", []);
        this.getEvents(component, event, helper, false);

    }
    /* End CCN-EVE-3580-DV: Von Pernicia*/
})