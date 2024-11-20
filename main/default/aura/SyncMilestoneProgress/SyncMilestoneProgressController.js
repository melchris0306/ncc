/**
 * Created by angelorivera on 29/9/20.
 */

({
    doInit: function(cmp) {
        cmp.set("v.showSpinner",true);
        console.log("------ Start");
        var action = cmp.get('c.generateJourneyParticipants');
        action.setParams({
            journeyId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var ret = response.getReturnValue();
            var state = response.getState();
            console.log("------ response value: " + ret);
            console.log("------ response state: " + state);

            var title, message, type;

            if (state === "SUCCESS") {
                if(!ret.includes('added as journey participants')){
                    title = 'Error!';
                    type = 'error';
                }else{
                    title = 'Success!';
                    type = 'success';
                }
                message = ret;

                cmp.set("v.showSpinner",false);
                $A.get('e.force:closeQuickAction').fire();
                $A.get('e.force:refreshView').fire();

                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": title,
                    "message": message,
                    "type" : type
                });
                toastEvent.fire();

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

});