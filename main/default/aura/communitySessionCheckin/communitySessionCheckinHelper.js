({
    ReInit : function(component, event, helper) {
        var url_string = document.location.href;
        var sessionId;
        try {
            sessionId = (url_string.split('sessionid=')[1]).slice(0,15);
        }
        catch(err) {
            console.error('ID Error');
        }
        //var sessionId = (url_string.split('sessionid=')[1]).slice(0,15);
        var action = component.get("c.getSessionParticipants");
 
        action.setParams({ 
            sessionId : sessionId
        });
		action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                // Updated [Namespace Issue Fixes] JaysonLabnao Aug092022
                var resultEvent = helper.cleanUpNamespace(response.getReturnValue());
				component.set('v.participantList', resultEvent);
             }
        });
        $A.enqueueAction(action);
	},
    getSession : function(component, event, helper) {
        var url_string = document.location.href;
        var sessionId;
        try {
            sessionId = (url_string.split('sessionid=')[1]).slice(0,15);
        }
        catch(err) {
            console.error('ID Error');
        }
        //var sessionId = (url_string.split('sessionid=')[1]).slice(0,15);
        var action = component.get("c.getSessionDetails");
 
        action.setParams({ 
            sessionId : sessionId
        });
		action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                // Updated [Namespace Issue Fixes] JaysonLabnao Aug092022
                var resultEvent = helper.cleanUpNamespace(response.getReturnValue());
				component.set('v.name', resultEvent.Name);
                component.set('v.startDate', resultEvent.Start_Date_Time2__c);
                component.set('v.endDate', resultEvent.End_Date_Time2__c);
                
                //CCN-EVE-3303-DV - Jonah - Sept 23, 2023 - Added timezone
                component.set('v.timeZone', resultEvent.Time_Zone__c);
                
                //CCN-EVE-3303-DV - Leif - Date format fix
                var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
                
                var dateObjStart = new Date(resultEvent.Start_Date_Time2__c.toString());
                var month = months[dateObjStart.getMonth()];
                var day = String(dateObjStart.getDate()).padStart(2, '0');
                var year = dateObjStart.getFullYear();
                
                var hours = dateObjStart.getHours();
                var minutes = dateObjStart.getMinutes();
                var ampm = hours >= 12 ? 'PM' : 'AM';
                hours = hours % 12;
                hours = hours ? hours : 12;
                minutes = minutes < 10 ? '0' + minutes : minutes;
                
                
                var dateObjEnd = new Date(resultEvent.End_Date_Time2__c);
                
                var hoursEnd = dateObjEnd.getHours();
                var minutesEnd = dateObjEnd.getMinutes();
                // [CCN-3558] - fixed attendance page issue on AM/PM display. Fix by JC Espino NOV032023
                var ampmEnd = hoursEnd >= 12 ? 'PM' : 'AM';
                
                hoursEnd = hoursEnd % 12;
                hoursEnd = hoursEnd ? hoursEnd : 12;  // 12-hour format
                minutesEnd = minutesEnd < 10 ? '0' + minutesEnd : minutesEnd;
                
                var timeStringEnd = hoursEnd + ':' + minutesEnd + ' ' + ampmEnd;
                
                var formattedDate = month + ' ' + day + ', ' + year + ' | ' + hours + ':' + minutes + ' ' + ampm + ' - ' + timeStringEnd;
                
                component.set('v.finalDate', formattedDate);
                
             }
        });
        $A.enqueueAction(action);
	},
    // function automatic called by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
        
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    },

    // Created [Namespace Issue Fixes] JaysonLabnao Aug092022
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
    
    //CCN-EVE-3303-DV - Jonah - Sept 26, 2023
    doGetFieldConfig: function(component, event, helper) {
        const queryString = decodeURIComponent(window.location.search);
        let seshId = (queryString.split('sessionid=')[1]).split('&')[0];
        
        let action = component.get('c.getFieldConfig');
        
        //console.log(seshId);
        //console.log(action);
        
        action.setParams({
            sessionId : seshId,
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            let result = helper.cleanUpNamespace(response.getReturnValue());
            
            if (state === "SUCCESS") {
                try {
                    const rankSubstringToCheck = "RegistrationField_TitleRank";
                    const titleSubstringToCheck = "RegistrationField_Title";
                    const siteSubstringToCheck = "RegistrationField_Site";
					let isTitleAlreadyActive = false;					
                    
                    for (let i = 0 ; i < result.registrationFieldList.length ; i++) {
                        
                        //console.log('--------------');
                        
                        let field = result.registrationFieldList[i];
                        //console.log(field);
                        
                        if (!isTitleAlreadyActive) {
                            if (field.key.toString().toLowerCase().includes(titleSubstringToCheck.toLowerCase())) {
                                if (field.active) {
                                    component.set('v.shouldShowTitle',field.active);
                                    component.set('v.isRequired',field.required);
                                    component.set('v.shouldShowRank',false);
                                    component.set('v.titleItem',field);
                                    isTitleAlreadyActive = true;
                                }
                            }
                            
                            if (field.key.toString().toLowerCase().includes(rankSubstringToCheck.toLowerCase())) {
                                if (field.active) {
                                    component.set('v.shouldShowRank',field.active);
                                    component.set('v.isRequired',field.required);
                                    component.set('v.shouldShowTitle',false);     
                                    isTitleAlreadyActive = true;
                                }
                            }
                        }
                        
                        if (field.key.toString().toLowerCase().includes(siteSubstringToCheck.toLowerCase())) {
                            if (field.active) {
                                component.set('v.shouldShowSite',field.active);
                                component.set('v.siteItem',field);
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
                        console.log(errors[0]);
                    }
                }
            }
        });
        
        //console.log(action);
    
        $A.enqueueAction(action);
        
    },


})