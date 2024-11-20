({
    doInitHelper : function(component, event, helper) {
        const queryString = decodeURIComponent(window.location.search);
        var sessionId = (queryString.split('sessionid=')[1]).split('&')[0];
        component.set('v.sessionId', sessionId);

        var action = component.get('c.getRoles');
        
        action.setParams({
            sessId : sessionId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
            
            if(state === "SUCCESS"){
                if(result.tableValues){
                    console.log('T: ' + result.tableValues);
                    component.set('v.data', result.tableValues);
                    //component.set('v.SignUpInstructions', 'No Sign-Up Instructions.');
                    /*if(result.signUpInstructions){
                        component.set('v.SignUpInstructions', result.signUpInstructions);
                    }*/
                    if(result.hasData == 'Yes'){
                        component.set('v.showEdit', true);
                        component.set('v.isDisabled', true);
                    }else{
                        component.set('v.showSave', true);
                        component.set('v.isDisabled', false);
                    }
                    component.set('v.hasData', true);
                    component.set('v.isLoading', false);
                }else{
                    component.set('v.hasData', false);
                    component.set('v.isLoading', false);
                }
            }else{
                component.set('v.isLoading', false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'Error retrieving Internal Resource Roles',
                    duration:' 3000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);

        this.getEventDetailsHelper(component, event, helper);
        this.getEventDetailsIdHelper(component, event, helper);
    },

    getEventDetailsHelper : function(component, event, helper) {
        const queryString = decodeURIComponent(window.location.search);
        var sessionId = (queryString.split('sessionid=')[1]).split('&')[0];
        component.set('v.sessionId', sessionId);
        
        var action = component.get("c.getSessionDetails");
        action.setParams({
            sessId : sessionId
        });

        action.setCallback(this, function(response){
            var  months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
            var state = response.getState();

            if (state === "SUCCESS") {
                var resultEvent = this.cleanUpNamespace(response.getReturnValue());
                component.set('v.title', resultEvent.Name);
                component.set('v.startDate', (resultEvent.Start_Date_Time2__c).slice(-8));
                component.set('v.endDate', (resultEvent.End_Date_Time2__c).slice(-8));
                
                component.set('v.eventName', resultEvent.Event__r.Name);
                component.set('v.location', resultEvent.Location__c);
                component.set('v.sessionMonth', months[Number(resultEvent.Start_Date_Time2__c.substring(0,2)) - 1]);
                component.set('v.sessionDay', resultEvent.Start_Date_Time2__c.substring(3,5));
                
                component.set('v.sessionTimeZone', resultEvent.Time_Zone__c);

            }
            else{
                console.log(response.getError());
            }
        });

        $A.enqueueAction(action);
    },

    getEventDetailsIdHelper : function(component, event, helper) {
        const queryString = decodeURIComponent(window.location.search);

        var sessionId = (queryString.split('sessionid=')[1]).split('&')[0];
        component.set('v.sessionId', sessionId);

        var action = component.get("c.getEventDetailsId");
        action.setParams({
            sessId : sessionId
        });

        action.setCallback(this, function(response){

            var state = response.getState();

            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                component.set('v.eventId', resultEvent);
            }
            else{
                console.log(response.getError());
            }
        });

        $A.enqueueAction(action);
    },

    handleComponentEventHelper : function(component, event, helper) {

    },

    handleSaveSignUpHelper : function(component, event, helper) {
        //Save Internal Resource Session
        var sessionId = component.get("v.sessionId");
        var sessionResList = component.get("v.data");
        component.set('v.isLoading', true);
        
        var action = component.get('c.saveSessionInternalResource');
        action.setParams({
            sessionInternalResources : JSON.stringify(sessionResList),
            sessId : sessionId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
            if(state === "SUCCESS"){
                var toastEvent = $A.get("e.force:showToast");
                if(result.includes('Error')){
                    toastEvent.setParams({
                        title : 'Error',
                        message:result,
                        duration:' 3000',
                        key: 'info_alt',
                        type: 'error',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    component.set('v.isLoading', false);
                }else{
                console.log('melsuccess error');
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'Success! Internal resource(s) have been allocated for session delivery.',
                        duration:' 3000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'pester'
                    });
                   	toastEvent.fire();
                    component.set('v.is', false);
                    location.reload();
                    $A.get("e.force:refreshView").fire();
                }
            }else{
                console.log('result error'+JSON.stringify(result));
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'Error registering Internal resource(s)',
                    duration:' 3000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
                component.set('v.isLoading', false);
            }
        });
        $A.enqueueAction(action);
    },

    handleEditSignUpHelper : function(component, event, helper) {
        component.set('v.showSave', true);
        component.set('v.showEdit', false);
        component.set('v.showCancel', true);
        component.set('v.isDisabled', false);

        let firstNameInputs = component.find('FirstName');
        let lastNameInputs = component.find('LastName');
        let emailInputs = component.find('Email');
        var initialEmptyRows = component.get("v.emptyRows");
        var initialFilledUpRows = component.get("v.filledUpRows");

        // Convert to arrays if only single input found
        if (!Array.isArray(firstNameInputs)) {
            firstNameInputs = [firstNameInputs];
        }
        if (!Array.isArray(lastNameInputs)) {
            lastNameInputs = [lastNameInputs];
        }
        if (!Array.isArray(emailInputs)) {
            emailInputs = [emailInputs];
        }

        for (let i = 0; i < firstNameInputs.length ; i++) {
            let rowObject = {
                firstName: firstNameInputs[i].get('v.value'),
                lastName: lastNameInputs[i].get('v.value'),
                email: emailInputs[i].get('v.value'),
                id: i,
            }

            if (rowObject.firstName.trim() === '' && rowObject.lastName.trim() === '' && rowObject.email.trim() === '') {
                initialEmptyRows.push(rowObject);
            } else if (rowObject.firstName.trim() !== '' && rowObject.lastName.trim() !== '' && rowObject.email.trim() !== '') {
                initialFilledUpRows.push(rowObject);
            }
        }
    },

    handleCancelSignUpHelper : function(component, event, helper) {
        location.reload();
        $A.get('e.force:refreshView').fire();
    },
    
    handleRemoveHelper: function(component, event, helper) {
        component.set('v.isLoading', true);
        var intResId = event.getSource().get("v.value");
        
        component.set('v.isLoading', true);
        var action = component.get('c.removeRole');
        action.setParams({
            intResId : intResId
        });
        action.setCallback(this, function(response) {
            component.set('v.isLoading', false);
            var state = response.getState();
            var result = response.getReturnValue();
            //alert(state);
            if(state === "SUCCESS"){
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'Success! Internal resource has been canceled from session delivery.',
                        duration:' 3000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'pester'
                    });
                   	toastEvent.fire();
                location.reload();
                    $A.get("e.force:refreshView").fire();
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'You cannot remove Internal resource that is not yet registered.',
                    duration:' 3000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    cleanUpNamespace : function(jsonData){
        let responseStr = JSON.stringify(jsonData);
        
        if(responseStr.includes('beta_ccn__')){
            responseStr = responseStr.replaceAll('beta_ccn__', '');
        }
        if(responseStr.includes('compass_cn__') ){
            responseStr = responseStr.replaceAll('compass_cn__', '');
        }
        
        return JSON.parse(responseStr);
    },

    /**
     * Gian Bata - CCN-EVE-3398-DV
     * A function that sets the submit button based on the field status.
     * The button will only be enabled when there exist at least 
     * one row that has all field values entered and no invalid emails.
     */
    setSubmitButtonIsDisabled: function(component, event, helper) {
        // Arrays to store the inputs
        const emailRegex = /.+@.+(\.[a-zA-Z]{1,})+/;
        let firstNameInputs = component.find('FirstName');
        let lastNameInputs = component.find('LastName');
        let emailInputs = component.find('Email');
        let isAllEmailValid = true;
        let isEditMode = component.get('v.showCancel');
        let hasAtLeastOneFilledUpEmptyRowWithValidEmail = false;

        // Convert to arrays if only single input found
        if (!Array.isArray(firstNameInputs)) {
            firstNameInputs = [firstNameInputs];
        }
        if (!Array.isArray(lastNameInputs)) {
            lastNameInputs = [lastNameInputs];
        }
        if (!Array.isArray(emailInputs)) {
            emailInputs = [emailInputs];
        }

        // During edit mode, we set the submit button to enable if and only if
        // 1.) user has changed any of the initial filled up rows
        // 2.) user has filled up a row that was initially empty
        // 3.) All emails are valid
        if (isEditMode) {
            let initialEmptyRows = component.get("v.emptyRows");
            let initialFilledUpRows = component.get("v.filledUpRows");
            // Grab previousEmptyRows so that we can compare if there was a change that happened
            let parsedInitialEmptyRows = JSON.parse(JSON.stringify(initialEmptyRows));
            let parsedInitialFilledUpRows = JSON.parse(JSON.stringify(initialFilledUpRows));
            let currentEmptyRows = [];
            let currentRowGettingFilled = [];
            let currentFilledUpRows = []; // Row that has all 3 fields filled up
            let hasAtLeastOneFilledUpEmptyRow = false;
            let hasChangedFilledUpRow = false;
            

            for (let i = 0; i < firstNameInputs.length ; i++) {
                let rowObject = {
                    firstName: firstNameInputs[i].get('v.value'),
                    lastName: lastNameInputs[i].get('v.value'),
                    email: emailInputs[i].get('v.value'),
                    id: i,
                }

                if (rowObject.firstName.trim() === '' && rowObject.lastName.trim() === '' && rowObject.email.trim() === '') {
                    currentEmptyRows.push(rowObject);
                } else if(rowObject.firstName.trim() !== '' && rowObject.lastName.trim() !== '' && rowObject.email.trim() !== '') {
                    currentFilledUpRows.push(rowObject);
                } else {
                    currentRowGettingFilled.push(rowObject);
                }
            }

            if (currentEmptyRows.length < parsedInitialEmptyRows.length) {
                // If user filled up at least one initial empty row

                for (let i = 0; i < currentFilledUpRows.length; i++) {
                    let currentRow = currentFilledUpRows[i];
                    
                    // Check if current row existed in initialEmptyRows
                    let foundInInitialEmpty = parsedInitialEmptyRows.some(initialEmptyRow => 
                        initialEmptyRow.id === currentRow.id
                    );
                
                    if (foundInInitialEmpty) {
                        hasAtLeastOneFilledUpEmptyRow = true
                       
                        // Check for email validity
                        if (emailRegex.test(currentRow.email)) {
                            hasAtLeastOneFilledUpEmptyRowWithValidEmail = true;
                        }
                    }
                }
            } 

            for (let i = 0; i < parsedInitialFilledUpRows.length; i++) {
                let initialRow = parsedInitialFilledUpRows[i];
                let currentRow = currentFilledUpRows[i];
                
                if (initialRow.firstName !== currentRow.firstName ||
                    initialRow.lastName !== currentRow.lastName ||
                    initialRow.email !== currentRow.email) {
                    hasChangedFilledUpRow = true;
                    break; // Exit loop since we found a change
                }
            }

            isAllEmailValid = this.isAllEmailValid(emailInputs);
            
            if (hasAtLeastOneFilledUpEmptyRowWithValidEmail) {
                component.set('v.isSubmitDisabled', !(hasChangedFilledUpRow || hasAtLeastOneFilledUpEmptyRow));
            } else {
                component.set('v.isSubmitDisabled', !(hasChangedFilledUpRow || hasAtLeastOneFilledUpEmptyRow) || !isAllEmailValid);
            }
        } else {
            // Check if any row has all inputs filled out
            let hasFilledRow = firstNameInputs.some((_, index) => {
                let firstNameVal = firstNameInputs[index].get('v.value');
                let lastNameVal = lastNameInputs[index].get('v.value');
                let emailVal = emailInputs[index].get('v.value');

                // Check for email validity
                if (emailRegex.test(emailVal)) {
                    hasAtLeastOneFilledUpEmptyRowWithValidEmail = true;
                }
                
                return firstNameVal && firstNameVal.trim() !== '' &&
                    lastNameVal && lastNameVal.trim() !== '' &&
                    emailVal && emailVal.trim() !== '';
            });

            isAllEmailValid = this.isAllEmailValid(emailInputs);

            if (hasAtLeastOneFilledUpEmptyRowWithValidEmail) {
                component.set('v.isSubmitDisabled', !hasFilledRow);
            } else {
                component.set('v.isSubmitDisabled', !hasFilledRow || !isAllEmailValid);
            }
        }
    },

    /**
     * Gian Bata - CCN-EVE-3398-DV
     * Check if all email inputs are valid.
     */
    isAllEmailValid: function(emailInputs) {
        let isAllEmailValid = true;

        for (let input of emailInputs) {
            let emailValue = input.get("v.value");
            
            if (emailValue && emailValue.trim() !== '') {
                if (!input.checkValidity()) {
                    // This email input is invalid
                    isAllEmailValid = false;
                    break;  // Exit the loop if you find an invalid email
                }
            }
        }
    
        return isAllEmailValid;
    }
})