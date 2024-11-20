({
    submitTask : function(component, event, helper) {

        var action = component.get("c.createTask");

        action.setParams({
            eventId : component.get("v.eventId"),
            firstname : component.get("v.firstname"),
            lastname : component.get("v.lastname"),
            email : component.get("v.email"),
            phone : component.get("v.phone"),
            subject : component.get("v.subject"),
            comments : component.get("v.comments")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                this.showToast('Success!', "Your response has been submitted.", "success", "pester");
                component.set("v.showSpinner", false);
                $A.get('e.force:refreshView').fire();
            }
            else {
                console.log("Failed with state: " + state);
                this.showToast('Oops!', "Something's not right. Please contact the administrator for help.", "error", "pester");
                component.set("v.showSpinner", false);
            }
        });

        $A.enqueueAction(action);
    },


    showToast : function(title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type,
            "mode" : mode
        });
        toastEvent.fire();
    }
})