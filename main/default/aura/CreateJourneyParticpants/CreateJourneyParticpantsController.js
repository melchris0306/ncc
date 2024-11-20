/**
 * Created by angelorivera on 29/9/20.
 * Revision:  angelorivera on 13/07/20 - Updated logic on adding participants
 */

({
    doInit : function(cmp) {
        var action = cmp.get('c.retrieveJourneyEvents');
        action.setParams({
            journeyId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log("------ response state: " + state);

            if (state === "SUCCESS") {
                var journey = response.getReturnValue();

                var msg = journey.strMessage;
                var lstEvents = [];

                if(msg !== ''){
                    cmp.set("v.strMessage", msg);
                } else{
                    lstEvents = journey.listJourneyEvents;
                    console.log('----- lstEvents:' + lstEvents.length);
                    if(lstEvents !== 'undefined' && lstEvents.length > 0){
                        cmp.set("v.ListJourneyEvents", lstEvents);

                        cmp.set('v.columns', [
                            {label: 'Event Name', fieldName: 'eventName', type: 'text'}
                        ]);
                    }
                    else{
                        msg = 'Journey has no event assignment.';
                        cmp.set("v.strMessage", msg);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    updateSelectedText: function (cmp, event) {
        var selRows = event.getParam('selectedRows');
        console.log('selRows -> ' + JSON.stringify(selRows));

        cmp.set("v.selectedRowCount", selRows.length);

        var selectedRowsIds = [];
        for(var i=0;i<selRows.length;i++){
            selectedRowsIds.push(selRows[i].eventId);
        }
        cmp.set("v.selectedEventIds", selectedRowsIds);
        console.log('selectedRowsIds -> ' + cmp.get("v.selectedEventIds"));
    },

    handleSubmit : function(cmp) {
        cmp.set("v.showBody", false);
        cmp.set("v.showSpinner", true);
        console.log("------ Start");
        var action = cmp.get('c.createJourneyParticipants');
        action.setParams({
            journeyId : cmp.get("v.recordId"),
            ListEventIds : cmp.get("v.selectedEventIds")
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

    handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        $A.get('e.force:closeQuickAction').fire();
    }

});