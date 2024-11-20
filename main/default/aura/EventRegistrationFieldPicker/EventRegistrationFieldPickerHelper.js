({
	getAvailableFields : function(component, event, helper) {
		var action = component.get("c.getAvailableRegistrationFields");
        action.setParams({ 
            eventRecordId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                
                var resultEvent = response.getReturnValue();
                component.set("v.registrationFields", resultEvent);
                component.set("v.registrationFieldsCopy", resultEvent);
                helper.checkSelectAllBoxes(component, resultEvent);
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                this.showToast("Error", errors[0].message, "error");
            }
        });
        
        $A.enqueueAction(action);
	},

    checkSelectAllBoxes : function(component, results){
        let isSelectAll = true;
        let isRequiredAll = true;

        for (let i = 0 ; i < results.length ; i++){
            if (!results[i].active){
                isSelectAll = false;
            }

            if (!results[i].required){
                isRequiredAll = false;
            }
        }

        component.set("v.selectAll", isSelectAll);
        component.set("v.requiredAll", isRequiredAll);
    },
    
    saveRegistrationForm : function(component, event, helper){
        component.set("v.isReadOnly", true);

        let updatedFields = component.get("v.registrationFields");
        let action = component.get("c.saveRegistrationFormFields");
        let fieldsForSaving = {};

        for (let i = 0 ; i < updatedFields.length ; i++){
            //Start [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
            //                                            - Add active parameter
            fieldsForSaving[updatedFields[i]["key"]] = {'required': updatedFields[i]["required"],
                                                        'active': updatedFields[i]["active"]}; 
            //End [CCN-2530] RIANNO RIZARRI Feb01.2023  - Add the activation of field on the event registration field picker component.
        }

        action.setParams({ 
            eventRecordId : component.get("v.recordId"),
            updatedRegistrationFieldJSON : JSON.stringify(fieldsForSaving)
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                this.showToast("Success", "Event Registration Fields have been saved successfully", "success");
                component.set("v.registrationFieldsCopy", component.get("v.registrationFields"));
            }
        });
        
        $A.enqueueAction(action);
    },

    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type,
            "mode" : "pester"
        });
        toastEvent.fire();
    }
})