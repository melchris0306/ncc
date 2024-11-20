({
    doInit : function(component, event, helper) {

        helper.getSession(component, event, helper);
        helper.ReInit(component, event, helper);
        
        //CCN-EVE-3303-DV - Jonah - Sept 26, 2023
        helper.doGetFieldConfig(component, event, helper);
        

	},
    handleCheckin : function(component, event, helper) {

        helper.showSpinner(component, event, helper);
        var className = event.target.getAttribute("class");
        var participantId = className.substring(className.indexOf('id') + 2, 20);
        var action = component.get("c.setSessionParticipantsStatus");
        action.setParams({ 
            participantId : participantId
        });
		action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                helper.ReInit(component, event, helper);
                console.log('------------- resultEvent' + resultEvent);
             }
             helper.hideSpinner(component, event, helper);
        });
        $A.enqueueAction(action);
    }

})