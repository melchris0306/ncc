({
    doInit : function(component, event, helper) {
        helper.doInitHelper(component, event, helper);
    },
    
    handleComponentEvent : function(component, event, helper) {
        helper.handleComponentEventHelper(component, event, helper);
    },
    
    handleSaveSignUp : function(component, event, helper) {
        var intRes = component.get("v.data");
        var isValid = true;
        let inputField;

        for(let x = 0; x < intRes.length ; x++){
            var ir = intRes[x];
            if(ir.FirstName || ir.LastName || ir.Email){
                if(ir.FirstName == '' || ir.FirstName == null){
                    inputField = component.find('FirstName')[x];
                    inputField.setCustomValidity('Required Field'); 
                    inputField.reportValidity();
                    isValid = false;
                    //break;
                }
                if(ir.LastName == '' || ir.LastName == null){
                    inputField = component.find('LastName')[x];
                    inputField.setCustomValidity('Required Field'); 
                    inputField.reportValidity();
                    isValid = false;
                    //break;
                }
                if(ir.Email == '' || ir.Email == null){
                    inputField = component.find('Email')[x];
                    inputField.setCustomValidity('Required Field'); 
                    inputField.reportValidity();
                    isValid = false;
                    //break;
                } else if (ir.Email !== '' && ir.Email !== null) {
                    var emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
                    if (!emailRegex.test(ir.Email)) {
                        inputField = component.find('Email')[x];
                        inputField.setCustomValidity('Invalid Email Format');
                        inputField.reportValidity();
                        isValid = false;
                    }
                }
            }
        }        
        if (isValid) {
            helper.handleSaveSignUpHelper(component, event, helper);
        } 
    },
    
    handleEditSignUp : function(component, event, helper) {
        helper.handleEditSignUpHelper(component, event, helper);
    },    
    
    handleCancelSignUp : function(component, event, helper) {
        helper.handleCancelSignUpHelper(component, event, helper);
    }, 
    
    handleRemove : function(component, event, helper) {
        helper.handleRemoveHelper(component, event, helper);
    },
    removeCustomValidation : function(component, event, helper) {
        let cuRinputField = event.getSource();
        cuRinputField.setCustomValidity('');
        cuRinputField.reportValidity();
        let inputField;
        var intRes = component.get("v.data");

        for(let x = 0; x < intRes.length ; x++){
            var ir = intRes[x];
            if(ir.FirstName || ir.LastName || ir.Email){
                if(ir.FirstName == '' || ir.FirstName == null){
                    if(intRes.length == 1){
                        inputField = component.find('FirstName');
                    }
                    else{
                        inputField = component.find('FirstName')[x];
                    }
                }
                if(ir.LastName == '' || ir.LastName == null){
                    if(intRes.length == 1){
                        inputField = component.find('LastName');
                    }
                    else{
                        inputField = component.find('LastName')[x];
                    }
                }
                if(ir.Email == '' || ir.Email == null){
                    if(intRes.length == 1){
                        inputField = component.find('Email');
                    }
                    else{
                        inputField = component.find('Email')[x];
                    }
                }
            }
        }

        helper.setSubmitButtonIsDisabled(component, event, helper);
    },

    handleEmailOnChange : function(component, event, helper) {
        helper.setSubmitButtonIsDisabled(component, event, helper);
    }
})