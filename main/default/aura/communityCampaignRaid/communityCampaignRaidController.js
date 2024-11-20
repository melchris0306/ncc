({
    doInit : function(component, event, helper) {    
    
        helper.initializePrefix(component, event, helper);

    },
    
    toggleFilter : function(component, event, helper) {  
        component.set("v.isFilter", !component.get("v.isFilter"));
    },

    handleSort : function(component, event, helper) {  
        console.log('handleSort');
        var sortByValue = component.get("v.sortByValue");
    
        helper.doInitHelper(component, event, helper, sortByValue);  
    },

    handleSubmit : function(component, event, helper) {  

        // validate eventInput
        let eventInput = component.find('eventInput');
        let fieldValidityEvent = eventInput.checkValidity();
        if(!fieldValidityEvent) eventInput.showHelpMessageIfInvalid();

        // validatetypeInput
        let typeInput = component.find('typeInput');
        let fieldValidityType = typeInput.checkValidity();
        if(!fieldValidityType) typeInput.showHelpMessageIfInvalid();

        let allValidContactUsForm = component.find('contactUsForm').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValidContactUsForm && fieldValidityEvent && fieldValidityType){
            component.set("v.showSpinner", true);
            helper.submitRaid(component, event, helper);
        }   

    },
    
})