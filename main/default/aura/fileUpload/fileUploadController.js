({
    handleUploadFinished: function (cmp, event) {
        var uploadedFiles = event.getParam("files");
        var action = cmp.get("c.updateTargetRecord");
        action.setParams({ recordId : cmp.get("v.recordId"),
                            fileId : uploadedFiles[0].documentId,
                            fieldName : cmp.get("v.fileId") });

        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": cmp.get("v.successMessage"),
                    "type" : "success"
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
            else if (state === "INCOMPLETE") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "message": "Something has gone wrong. Try again",
                    "type" : "error"
                });
                toastEvent.fire();
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": errors[0].message,
                        "type" : "error"
                    });
                    toastEvent.fire();
                    }
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error",
                        "message": "An unknown error has occured. Try again.",
                        "type" : "error"
                    });
                    toastEvent.fire();
                    
                }
            }
        });

        $A.enqueueAction(action);
    }
})