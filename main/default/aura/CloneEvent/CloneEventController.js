({
    doInit : function(component, event, helper) {
        var a = component.get('c.cloneEvent');
        $A.enqueueAction(a);
	},
    
    cloneEvent : function(component, event, helper) {
        component.set("v.cloning" , true);
        console.log('Event Id:'+ component.get("v.recordId"));
		var action = component.get("c.cloneEventRecord");
        action.setParams({ 
            eventId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                if (!resultEvent.includes("Error>>>")) {
                    console.log('resultEvent:'+resultEvent);
                    
                    component.set("v.cloning" , false);
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": resultEvent,
                        "slideDevName": "related"
                    });
                    navEvt.fire();
                }
                else {
                    // Close the action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: "Clone Event Record - Retrieve Data",
                        message: resultEvent,
                        type: "error"
                    });
                    toastEvent.fire();
                }
            }
            else{
                console.log('ERROR:');
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
	},
    
})