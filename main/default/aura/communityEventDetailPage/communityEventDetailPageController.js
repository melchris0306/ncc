({
    doInit : function(component, event, helper) {
        
        var url_string = document.location.href;
        var eventId = (url_string.split('id=')[1]).slice(0,11);
        var action = component.get("c.getEventDetails");
        component.set("v.learnMorePageTitle",'LEARN MORE');
        
        action.setParams({ 
            eventId : eventId
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                component.set('v.detailString', resultEvent.Description);
                if(resultEvent.learnMorePageTitle != null){
                    component.set("v.learnMorePageTitle",resultEvent.learnMorePageTitle);
                }
            } else if(state === "ERROR"){
                let errors = response.getError();
                let message = "Error on loading event details page"; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": 'Error',
                    "message": message,
                    "type" : 'error'
                });
                toastEvent.fire();
            }
        });
        
        $A.enqueueAction(action);
       
    }
    
    
})