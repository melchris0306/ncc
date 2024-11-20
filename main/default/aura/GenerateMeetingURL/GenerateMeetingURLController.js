/**
 * Created by angelorivera on 29/9/20.
 */
({
    doInit: function(cmp) {
        //cmp.set("v.showSpinner",true);
        console.log("------ Start");
        var action = cmp.get('c.retrieveApplications');
        action.setParams({
            eventId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var ret = response.getReturnValue();
            var state = response.getState();
            console.log("------ response value: " + ret);
            console.log("------ response state: " + state);
            console.log("------ strReturn: " + ret.strReturn);
            if (state === "SUCCESS") {
                if(ret.strReturn.includes('Error')){
                    $A.get('e.force:closeQuickAction').fire();
                    $A.get('e.force:refreshView').fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": 'Error!',
                        "message": ret.strReturn,
                        "type" : 'error'
                    });
                    toastEvent.fire();
                }else{
                    cmp.set("v.setMeetingType", ret.setMeetingType);
                    cmp.set("v.setMeetingName", ret.setMeetingName);
                }
            }
        });
        $A.enqueueAction(action);
    },

    onControllerFieldChange: function(component, event, helper) {
        var controllerValue = event.getSource().get("v.value"); // get selected controller field value
        component.set("v.strMeetingType", controllerValue);
        console.log("------ controllerValueKey: " + component.get("v.strMeetingType"));
        if(controllerValue !== '--- None ---'){
            component.set("v.disableButton", false);
        }else{
            component.set("v.disableButton", true);
        }
    },

    handleSubmit: function(cmp, event, helper) {
        console.log('!@# meeting type: ' + cmp.get("v.strMeetingType"));
        var action = cmp.get('c.generateMeetingURL');
        action.setParams({
            eventId : cmp.get("v.recordId"),
            strMeetingType: cmp.get("v.strMeetingType")
        });

        action.setCallback(this, function(response) {
            var ret = response.getReturnValue();
            var state = response.getState();
            console.log("------ response value: " + ret);
            console.log("------ response state: " + state);

            var title, message, type;
            if (state === "SUCCESS") {

                if(ret.includes('error')){
                    title = 'Error!';
                    type = 'error';
                }else{
                    title = 'Success!';
                    type = 'success';
                }
                message = ret;

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

    }

});