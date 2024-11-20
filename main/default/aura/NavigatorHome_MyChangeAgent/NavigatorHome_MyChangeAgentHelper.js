({
    getNavigatorDetails : function(component, event, helper) {
        let url_strings = document.location.href.split('?');
        const urlParams = new URLSearchParams(url_strings[1]);
        const navigatorId = urlParams.get('id');
        const contactId = urlParams.get('contactId');
        component.set("v.contactId", contactId);

        const action = component.get('c.getNavigatorDetails');
        action.setParams({ navigatorId });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                let navigator = response.getReturnValue();
                component.set('v.navigator', navigator);
                          console.log('CHANGE AGENT');
                          console.log(navigator);
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },
    
    showToastError : function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type" : "error",
            "message": message
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
})