({
	getEvents : function(component, event) {
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
            sessionId: component.get("v.selectedSessionIds"), /* Start/End CCN-EVE-3580-DV: Von Pernicia*/
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
          
                component.set("v.eventsMap",response.getReturnValue());
                var eventListMap = component.get("v.eventsMap");
                var defaultDte = eventListMap[0].startDateTime.substring(0,10);
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
    

})