({
    doInitHelper : function(component, event, helper) {
        //GET Roles/Table Values on Init        

        const queryString = decodeURIComponent(window.location.search);

       // var sessionId = (queryString.split('sessionid=')[1]).split('&')[0];
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
                    component.set('v.SignUpInstructions', 'No Sign-Up Instructions.');
                    if(result.signUpInstructions){
                        component.set('v.SignUpInstructions', result.signUpInstructions);
                    }
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
                    message:'Error retrieving session roles',
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

        //var sessionId = (queryString.split('sessionid=')[1]).split('&')[0];
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
                // Updated by Edison Crisostomo [CCN-EVE-14-DV] 07/07/2022
                component.set('v.eventName', resultEvent.Event__r.Name);
                component.set('v.location', resultEvent.Location__c);
                component.set('v.sessionMonth', months[Number(resultEvent.Start_Date_Time2__c.substring(0,2)) - 1]);
                component.set('v.sessionDay', resultEvent.Start_Date_Time2__c.substring(3,5));
                // UPDATED by JC ESPINO [CCN-EVE-2870-DV] 24/05/23 - added Timezone
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

        //var sessionId = (queryString.split('sessionid=')[1]).split('&')[0];
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
        console.log(event);
        this.setSubmitButtonIsDisabled(component, event, helper);
    },

    handleSaveSignUpHelper : function(component, event, helper) {
        var hasRequiredFields = this.hasRequiredFields(component, event, helper);

        // If it doesn't have a missing required field, continue to save
        if (!hasRequiredFields) {
            //Save Session Participants
            var sessionId = component.get("v.sessionId");
            var sessionPartList = component.get("v.data");
            component.set('v.isLoading', true);
            var action = component.get('c.saveSessionParticipants');
            action.setParams({
                sessionParticipants : JSON.stringify(sessionPartList),
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
                        toastEvent.setParams({
                            title : 'Success',
                            message: 'Success! Participant(s) have been registered for the session.',
                            duration:' 3000',
                            key: 'info_alt',
                            type: 'success',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                        //component.set('v.isLoading', false);
                        $A.get("e.force:refreshView").fire();
                    }
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Error',
                        message:'Error registering session participants',
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
        } 
    },

    returnToCalendarHelper : function(component, event, helper) {
        var url = location.href;  // window.location.href;
        var pathname = location.pathname;  // window.location.pathname;
        var index1 = url.indexOf(pathname);
        var index2 = url.indexOf("/", index1 + 1);
        var baseLocalUrl = url.substr(0, index2) + '/s/sessions-calendar?id=' + component.get('v.eventId');

        var eUrl= $A.get("e.force:navigateToURL");
        eUrl.setParams({
          "url": baseLocalUrl
        });
        eUrl.fire();
    },

    handleEditSignUpHelper : function(component, event, helper) {
        component.set('v.showSave', true);
        component.set('v.showEdit', false);
        component.set('v.showCancel', true);
        component.set('v.isDisabled', false);

        // Setup initial status per row
        let massSessionSignupRowList = component.find("mass-session-signup-row");
        let initialEmptyRows = component.get("v.emptyRows");
        let initialFilledUpRows = component.get("v.filledUpRows");

        massSessionSignupRowList.forEach(function(row, index) { 
            let rowFields = row.find("field");
            let rowObject = {
                firstName: rowFields[0].get("v.value"),
                lastName: rowFields[1].get("v.value"),
                email: rowFields[2].get("v.value"),
                id: index,
            }

            if (rowObject.firstName.trim() === '' && rowObject.lastName.trim() === '' && rowObject.email.trim() === '') {
                initialEmptyRows.push(rowObject);
            } else if (rowObject.firstName.trim() !== '' && rowObject.lastName.trim() !== '' && rowObject.email.trim() !== '') {
                initialFilledUpRows.push(rowObject);
            }
        });
    },

    handleCancelSignUpHelper : function(component, event, helper) {
		$A.get("e.force:refreshView").fire();
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
     * Gian Bata - CCN-EVE-2323-DV 
     * A function that checks if there exist a field that is required.
     */
    hasRequiredFields: function(component, event, helper) {
        var massSessionSignupRowList = component.find("mass-session-signup-row");
        var requiredFieldsCount = 0;
        var invalidEmailFormatCount = 0; // Tracker to check how many invalid email input there are

        // FOR EACH ROW
        massSessionSignupRowList.forEach(function(row) {
            var rowFields = row.find("field");
            var hasFieldWithInput = false; // Tracker to check if the row has at least one input field that has a value
           
            // First check if the row has at least one field with input.
            rowFields.forEach(function(field) {

                // Only loop through if we haven't found a field with input yet.
                if (!hasFieldWithInput) {
                    var fieldValue = field.get("v.value");

                    if (!$A.util.isEmpty(fieldValue)) {
                        hasFieldWithInput = true;
                    }
                }
            });

            // Check if row has invalid email format errors IF and only IF 
            // the row has a field with input
            if (hasFieldWithInput) {
                rowFields.forEach(function(field) {
                    var fieldName = field.get("v.name");
                    var fieldValue = field.get("v.value");

                    if (fieldName === 'Email' && !$A.util.isEmpty(fieldValue) && !field.checkValidity()) {
                        invalidEmailFormatCount++;
                        $A.util.removeClass(field, "required-error");
                    }
                });
            }

            // If there is at least one field with value, then we need to require the whole row
            rowFields.forEach(function(field, index) {
                var fieldValue = field.get("v.value");

                //Leif Erickson de Gracia - CCN-EVE-3304-DV
				var fieldName = field.get("v.name");
                
                if (fieldName === 'Rank' && hasFieldWithInput && $A.util.isEmpty(fieldValue) && component.get('v.isRequired') 
                    && (component.get('v.shouldShowTitle') ||component.get('v.shouldShowRank'))) {
                    $A.util.addClass(field, "required-error");
                    requiredFieldsCount++;
                    //Leif Erickson de Gracia - CCN-EVE-3304-DV END
                } else {
                     $A.util.removeClass(field, "required-error");
                }
                
                if ($A.util.isEmpty(fieldValue) && fieldName != 'Rank') {
                    // Only apply required errors to rows that has at least one field with input.
                    if (hasFieldWithInput) {
                        $A.util.addClass(field, "required-error");
                        requiredFieldsCount++;
                    } else {
                        $A.util.removeClass(field, "required-error");
                    }
                }
            });
        });

        return invalidEmailFormatCount > 0 || requiredFieldsCount > 0;
    },

    /**
     * Gian Bata - CCN-EVE-2323-DV 
     * A function that sets the submit button based on the field status.
     * The button will only be enabled when there exist at least 
     * one field that has value and no invalid emails.
     */
    setSubmitButtonIsDisabled: function(component, event, helper) {
        
        const emailRegex = /.+@.+(\.[a-zA-Z]{1,})+/;
        var massSessionSignupRowList = component.find("mass-session-signup-row");
        let isAllEmailValid = true;
        let emailFields = [];
        let hasFilledRow = false;
        let isEditMode = component.get('v.showCancel');
        let hasAtLeastOneFilledUpEmptyRowWithValidEmail = false;

        // During edit mode, we set the submit button to enable if and only if
        // 1.) user has changed any of the initial filled up rows
        // 2.) user has filled up a row that was initially empty
        // 3.) All emails are valid
        if (isEditMode) {
            var initialEmptyRows = component.get("v.emptyRows");
            var initialFilledUpRows = component.get("v.filledUpRows");
            let parsedInitialEmptyRows = JSON.parse(JSON.stringify(initialEmptyRows));
            let parsedInitialFilledUpRows = JSON.parse(JSON.stringify(initialFilledUpRows));
            let currentEmptyRows = [];
            let currentFilledUpRows = [];
            let hasAtLeastOneFilledUpEmptyRow = false;
            let hasChangedFilledUpRow = false;
            
            massSessionSignupRowList.forEach(function(row, index) {
                var rowFields = row.find("field");
                
                let rowObject = {
                    firstName: rowFields[0].get('v.value'),
                    lastName: rowFields[1].get('v.value'),
                    email: rowFields[2].get('v.value'),
                    id: index,
                    
                }

                if (rowObject.firstName.trim() === '' && rowObject.lastName.trim() === '' && rowObject.email.trim() === '') {
                    currentEmptyRows.push(rowObject);
                } else if(rowObject.firstName.trim() !== '' && rowObject.lastName.trim() !== '' && rowObject.email.trim() !== '') {
                    currentFilledUpRows.push(rowObject);
                } 

                rowFields.forEach(function(field) {
                    // Check if the field is of type "email"
                    var fieldType = field.get("v.type");
                    if (fieldType === "email") {
                        emailFields.push(field);
                    }
                });
            });

            // If user filled up at least one initial empty row
            if (currentEmptyRows.length < parsedInitialEmptyRows.length) {
                
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
            

            isAllEmailValid = this.isAllEmailValid(emailFields);
           

            if (hasAtLeastOneFilledUpEmptyRowWithValidEmail) {
                component.set('v.isSubmitDisabled', !(hasChangedFilledUpRow || hasAtLeastOneFilledUpEmptyRow));
            } else {
                component.set('v.isSubmitDisabled', !(hasChangedFilledUpRow || hasAtLeastOneFilledUpEmptyRow) || !isAllEmailValid);
            }
        } else {
            massSessionSignupRowList.forEach(function(row) {
                var rowFields = row.find("field");
                let firstNameValue = rowFields[0].get("v.value");
                let lastNameValue = rowFields[1].get("v.value");
                let emailValue = rowFields[2].get("v.value");
    
                if (firstNameValue && lastNameValue && emailValue) {
                    hasFilledRow = true;

                    // Check for email validity
                    if (emailRegex.test(emailValue)) {
                        hasAtLeastOneFilledUpEmptyRowWithValidEmail = true;
                    }
                }
                
                rowFields.forEach(function(field) {
                    // Check if the field is of type "email"
                    var fieldType = field.get("v.type");
                    if (fieldType === "email") {
                        emailFields.push(field);
                    }
                });
            });
    
            isAllEmailValid = this.isAllEmailValid(emailFields);

            if (hasAtLeastOneFilledUpEmptyRowWithValidEmail) {
                component.set('v.isSubmitDisabled', !hasFilledRow);
            } else {
                component.set('v.isSubmitDisabled', !hasFilledRow || !isAllEmailValid);
            }
        }
    },

    /**
     * Gian Bata - CCN-EVE-2323-DV 
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
    },
    
    //3304
    isTitleValid: function(){
       var massSessionSignupRowList = component.find("mass-session-signup-row");
        let hasDashTitle = false;
        let titleFields = [];
        
        var rowFields = row.find("field");
                
                let rowObject = {
                    title: rowFields[0].get('v.value'),
                    firstName: rowFields[1].get('v.value'),
                    lastName: rowFields[2].get('v.value'),
                    email: rowFields[3].get('v.value'),
                    id: index,
                    
                }

                rowFields.forEach(function(field) {
                    // Check if the field is of type "email"
                    var fieldType = field.get("v.type");
                    if (fieldType === "picklist") {
                        titleFields.push(field);
                    }
                });
        
        for (let i = 0; i < titleFields.length; i++) {
                
                if (titleFields.title === '----') {
                    hasDashTitle = true;
                    
                    break; // Exit loop since we found a change
                }
            }
        
        return hasDashTitle;
    },
    
    /*******************************************************************************************
        * @name: doGetFieldConfig
        * @author: Leif Erickson de Gracia
        * @created: Sept 7, 2023
        * @description: CCN-EVE-3304-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   07-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
    doGetFieldConfig: function(component, event, helper) {
        const queryString = decodeURIComponent(window.location.search);
        let eventId = (queryString.split('id=')[1]).split('&')[0];
        
        let action = component.get('c.getFieldConfig');
        
        console.log(eventId);
        console.log(action);
        
        action.setParams({
            campaignId : eventId,
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            let result = helper.cleanUpNamespace(response.getReturnValue());
            
            if (state === "SUCCESS") {
                try {
                    const rankSubstringToCheck = "RegistrationField_TitleRank";
                    const titleSubstringToCheck = "RegistrationField_Title";
                    
                    for (let i = 0 ; i < result.registrationFieldList.length ; i++) {
                        let field = result.registrationFieldList[i];
                        if (field.key.toString().toLowerCase().includes(rankSubstringToCheck.toLowerCase())) {
                            if (field.active) {
                                component.set('v.shouldShowRank',field.active);
                                component.set('v.isRequired',field.required);
                                component.set('v.shouldShowTitle',false);
                                break;
                            }
                        }
                        
                        if (field.key.toString().toLowerCase().includes(titleSubstringToCheck.toLowerCase())) {
                            if (field.active) {
                                component.set('v.shouldShowTitle',field.active);
                                component.set('v.isRequired',field.required);
                                component.set('v.shouldShowRank',false);
                                component.set('v.titleItem',field);
                                break;
                            }
                        }
                    }
                } catch(err) {
                    // Block of code to handle the error
                    console.error("An error occurred:", err.message);
                }              
                
            } else if (state === "ERROR") {
                let errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('--ERRORS--');
                        console.log(errors[0].message);
                    }
                }
            }
        });
        
        console.log(action);
        
        $A.enqueueAction(action);
        
    },
})