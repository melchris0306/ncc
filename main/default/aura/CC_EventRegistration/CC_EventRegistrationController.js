({
    
    doInit: function(component, event, helper) {
        component.set("v.showSpinner", true);
        const queryString = decodeURIComponent(window.location.search);
        let eventId = (queryString.split('id=')[1]).split('&')[0];
        
        let PM = '';
        try {
            PM = (queryString.split('pm=')[1]).split('&')[0];
        } catch(err) {
            PM = '';
        }         
        
        //console.log('---- PM ' + PM);

        component.set("v.EventId", eventId);
        
        //Added [CCN1052] RLugpatan Dec302021
        component.set("v.ParticipantId", PM);
        
        let action = component.get('c.DoInit');
        action.setParams({
            campaignId : eventId ,
            pm : PM
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            let result = helper.cleanUpNamespace(response.getReturnValue());
            
            if (state === "SUCCESS") {
                // Updated [CCN861] JaysonLabnao Oct192021
                let sessionList = [];
                /*-- CCN-EVE-2482-DV Gabriel Delavin Jan182023 !--*/
                    component.set("v.RegistrationMessage", result.RegistrationMessage);
                    component.set("v.RegistrationTagline", result.RegistrationTagline);
                    result.SessionList.forEach(function(session){
                    
                    if(session.EventDate){
                        if(session.StartTime && session.EndTime){
                            let eventDate = $A.localizationService.formatDate(session.EventDate, 'MM/dd/yyyy');
                            let startTime = session.StartTime.split(' ');
                            let mobileDate = '';
                            if((screen.width > 768 && screen.width < 1024) || $A.get('$Browser').isTablet ){
                                mobileDate = eventDate + '\r\n' + startTime[0] + ' ' + startTime[1] + ' - ' + session.EndTime;
                            }
                            else{
                                mobileDate = eventDate + '\r\n' + startTime[0] + ' ' + startTime[1] + ' -\r\n' + session.EndTime;
                            }
                            session.MobileDate = mobileDate;
                        }
                        else{
                            session.MobileDate = session.EventDate;
                        }
                        session.FormattedDate = $A.localizationService.formatDate(session.EventDate, 'dd-MMM-yy');
                    }
                    sessionList.push(session);
                });

                if(sessionList.length) component.set('v.sessionList', sessionList);

                let participantRecord = result.participantRecordList;
                let regFieldList = [];

                for (let i = 0 ; i < result.registrationFieldList.length ; i++){
                    let field = result.registrationFieldList[i];
                    //console.log('### FIELD: ' + JSON.stringify(field));

                    /* CCN-EVE-2074-DV XEN REYES Oct2022 */
                    if(field.required && component.get("v.hasRequiredField") == false){
                        component.set("v.hasRequiredField", true);
                    }

                    if(!$A.util.isUndefined(participantRecord)){
                        field["inputValue"] = participantRecord[0]["Member_Contact__r"][field["fieldName"]];
                    }
                    
                    regFieldList.push({Field : field, IsPicklist : field.fieldType === "Picklist"});
                }
                component.set('v.dynamicFields', regFieldList);
                
            } else if (state === "ERROR") {
                let errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('--ERRORS--');
                        console.log(errors[0].message);
                    }
                }
            }
            component.set("v.showSpinner", false);
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(action);
        
        //[CCN3301]
        helper.getRankValues(component, event, helper);
    },
    
    onInputBlur : function(component, event, helper) {

        //Start  11/21/2023 CCN-EVE-3594-DV Von Pernicia - comment out regex and set error message if email format is invalid
        /*const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        let type = event.getSource().get("v.type");
        let value =  event.getSource().get("v.value");
        
        const pattern = /^.*@[^.]+$/;

        if(value && type == "Email" && !emailRegex.test(value) && pattern.test(value)){
            component.set("v.patternMismatchMessage", "Invalid Email Format.");
            component.set("v.showEmailFormatValidation", true);
            $A.util.addClass(event.getSource(), "slds-has-error");
        }else if(value && type == "Email" && emailRegex.test(value) && !pattern.test(value)){
            component.set("v.patternMismatchMessage", "");
            component.set("v.showEmailFormatValidation", false);
            $A.util.removeClass(event.getSource(), "slds-has-error");
        }*/
        let type = event.getSource().get("v.type");

       
        let FIELD_RESULTS = helper.checkFieldsValidityAndGetInputValues(component);
        let sessionIdList = helper.checkSelectedSessionsAndReturnSelectedSessions(component);

        if (FIELD_RESULTS["validity"] && sessionIdList.length !== 0) {
            if (type == "Email") {
                component.set("v.patternMismatchMessage", ""); 
            }
            component.set("v.isSubmitActive", true); 
        } else {
            if (type == "Email") {
                component.set("v.patternMismatchMessage", "Invalid Email Format");
            }
            let fieldValidity = false;
            fieldValidity = component.find('registrationFormFields').reduce(function (validSoFar, inputCmp) {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

            component.set("v.isSubmitActive", false);  
        }
        
        //End  11/21/2023 CCN-EVE-3594-DV Von Pernicia - comment out regex and set error message if email format is invalid
    },
    
    handleTitleChange : function(component, event, helper) {
        let title =  event.getSource().get("v.value");
        let fieldName =  event.getSource().get("v.name");        
        if(fieldName.includes('Title')) component.set('v.selectedValueRank', title);

        /* let isRequired = event.target.dataset.isRequired;
        const titleArray = title.split("|");
        if(titleArray[0] == "-----" && isRequired == "true"){
            component.set("v.hasSelectedInvalidValue", true);
            component.set("v.showTitleRankValidation", true);
            $A.util.addClass(component.find("colorId"), "slds-has-error");
        }else{
            $A.util.removeClass(component.find("colorId"), "slds-has-error");
            component.set("v.hasSelectedInvalidValue", false);
            component.set("v.showTitleRankValidation", false);
        } */
    },

    handleSubmit : function(component, event, helper) {    
        
        let url_string = document.location.href;
        let eventId = (url_string.split('id=')[1]).slice(0,11);


        let FIELD_RESULTS = helper.checkFieldsValidityAndGetInputValues(component);
        let sessionIdList = helper.checkSelectedSessionsAndReturnSelectedSessions(component);
        let toastEvent = $A.get("e.force:showToast");
        let hasInvalidTitleRank = component.get("v.hasSelectedInvalidValue");
        var currentRankValue = component.get("v.selectedValueRank");

        console.log(FIELD_RESULTS);

        /* if(hasInvalidTitleRank){
            component.set("v.showTitleRankValidation", true);
            $A.util.addClass(component.find("colorId"), "slds-has-error");
            toastEvent.setParams({
                title : 'Error!',
                message: 'Please complete all required fields.',
                duration:' 7000',
                type: 'error',
            });

            toastEvent.fire();
            return;
        } */
        
		if(sessionIdList.length === 0){
            toastEvent.setParams({
                title : 'Error!',
                message: 'Please select a session.',
                duration:' 7000',
                type: 'error',
            });

            toastEvent.fire();
            
        } else if (FIELD_RESULTS["validity"]){
            component.set("v.showTitleRankValidation", false);
            $A.util.removeClass(component.find("colorId"), "slds-has-error");
            component.set("v.showSpinner", true);
            let action = component.get('c.submitBooking');
            action.setParams({
                campaignId : eventId,
                fieldInputs : JSON.stringify(FIELD_RESULTS["inputs"]),
                sessionIds : sessionIdList,
                currentRankValue : currentRankValue
            });
            action.setCallback(this, function(response) {
                let state = response.getState();
                let resp = helper.cleanUpNamespace(response.getReturnValue());

                /* console.log('resp'+response.getReturnValue());
				console.log('resp'+resp);
                console.log('state'+state); */

                if (state === "SUCCESS") {
                    component.set("v.showSpinner", false);
                    toastEvent.setParams({
                        title : 'Success!',
                        message: 'You are now registered to the event.',
                        duration:' 7000',
                        type: 'success',
                    });
                    toastEvent.fire();
                    
                    let urlEvent = $A.get("e.force:navigateToURL");
                    //Updated [CCN1052] RLugpatan Dec302021
                    urlEvent.setParams({
                        "url":  'https://' + window.location.hostname + '/Compass/s/events?id=' + component.get("v.EventId") + '&pm=' +component.get("v.ParticipantId")
                    });
                    urlEvent.fire();
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
            $A.enqueueAction(action);
        }
    },

    // Created [CCN859,CCN860,CCN861] JaysonLabnao Nov042021
    handleOpenSortModal : function(component, event, helper){
        let isSortOpen = component.get('v.isSortOpen');
        component.set('v.isSortOpen', !isSortOpen);
    },

    // Created [CCN859,CCN860,CCN861] JaysonLabnao Nov042021
    handleSort : function(component, event, helper){
        let sessionList = component.get('v.sessionList');
        const sortField = event.getParam('value');
        sessionList = helper.sortObjects(sessionList, sortField);
        // console.log(sessionList);
        component.set('v.sessionList', sessionList);
    }

})