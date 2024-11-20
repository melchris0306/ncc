/***********
 * 04/11/2021 MHM Created
 * Description: copying framework from SyncMilestoneProgress components
 */
({
    doInit: function(cmp) {
        cmp.set("v.showSpinner",true);
        console.log("------ Start");
        var action = cmp.get('c.updReportCategory');
        action.setParams({
            recordId : cmp.get("v.recordId")
        });

        action.setCallback(this, function(response) {
            var ret = response.getReturnValue();
            var state = response.getState();
            console.log("------ response value: " + ret);
            console.log("------ response state: " + state);

            var title, message, type;

            if (state === "SUCCESS") {
                if(!ret.includes('Syncing Report Categories')){
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