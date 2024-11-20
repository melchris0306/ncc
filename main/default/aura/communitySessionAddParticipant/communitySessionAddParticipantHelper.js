({
	showSuccess : function(component, event) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"title": "Success!",
			"type" : 'success',
			"mode" : 'dismissible',
			"duration" : 5000,
			"message": "Participant has been added."
		});
		toastEvent.fire();
	},
	showError : function(component, event) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"title": "Error!",
			"type" : 'error',
			"mode" : 'dismissible',
			"duration" : 5000,
			"message": "Sorry! something went wrong, please contact the administrator."
		});
		toastEvent.fire();
	},
	showErrorBlank : function(component, event) {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"title": "Error!",
			"type" : 'error',
			"mode" : 'dismissible',
			"duration" : 5000,
			"message": "Please complete all required fields."
		});
		toastEvent.fire();
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

    // Created [Namespace Issue Fixes] JaysonLabnao Aug102022
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

    // Added By JaysonLabnao [CCN-EVE-2160-DV] OCT092022
	getRankOptions : function(component, event, helper){
		const action = component.get('c.getRankAndRankGroupDependencies');
		action.setCallback(this, (response) =>{
			const STATE = response.getState();
			if(STATE === 'SUCCESS'){
				
				//let rankOptions = response.getReturnValue();
				//component.set('v.rankOptions', rankOptions);

				//XEN REYES March 5, 2023 CCN-EVE-2631-DV
				var result = response.getReturnValue();
                var arrayMapKeys = [];
                for(var key in result){
                    arrayMapKeys.push({
						key: key, 
						value: result[key]});
                }
                component.set("v.dataCollectionRecords", arrayMapKeys);

			}
			else{
				console.error({ error : response.getError() });
			}
			component.set('v.spinner', false);
		});

		$A.enqueueAction(action);
	},
        
    /*******************************************************************************************
        * @name: doGetFieldConfig
        * @author: Leif Erickson de Gracia
        * @created: Sept 8, 2023
        * @description: CCN-EVE-3303-DV
        *
        * -------------------------------------------------------------------------------------------
        *       	  No.   Date(dd-mm-yyy) 	Author         	   	  Description
        *       	  ----  ---------------     --------------------  -------------------------------
        * @version    1.0   08-09-2023        Leif Erickson de Gracia   Initial Version
        *********************************************************************************************/
    doGetFieldConfig: function(component, event, helper) {
        const queryString = decodeURIComponent(window.location.search);
        let seshId = (queryString.split('sessionid=')[1]).split('&')[0];
        
        let action = component.get('c.getFieldConfig');
        
        console.log(seshId);
        console.log(action);
        
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
                        
                        console.log('--------------');
                        
                        let field = result.registrationFieldList[i];
                        console.log(field);
                        
                        if (!isTitleAlreadyActive) {
                            if (field.key.toString().toLowerCase().includes(titleSubstringToCheck.toLowerCase())) {
                                console.log('mel>>>');
                                if (field.active) {
                                    console.log('mel>>>active'+field.required);
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
                    
                    console.log(component.get('v.shouldShowTitle'));
                    console.log(component.get('v.isRequired'));
                    console.log(component.get('v.shouldShowRank'));
                    console.log(component.get('v.titleItem'));
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
        
        console.log(action);
        
        $A.enqueueAction(action);
        
    },
})