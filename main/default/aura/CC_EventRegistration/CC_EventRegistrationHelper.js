({
    getContactInformation : function(component, event) {
        
        const queryString = decodeURIComponent(window.location.search);

        try {
            emailstr = (queryString.split('email=')[1]).split('&')[0];
        }
        catch(err) {
            emailstr = '';
        }
        
        var action2 = component.get("c.getContactInfo");
        
        action2.setParams({ 
            emailstr : emailstr
        });
        
        action2.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                
                component.set('v.FirstName', resultEvent.FirstName);
                component.set('v.LastName', resultEvent.LastName);
                component.set('v.Email', resultEvent.Email);
                component.set('v.Company', resultEvent.Department);
            }
        });
        
        $A.enqueueAction(action2);
        
    },

    checkFieldsValidityAndGetInputValues : function(component) {
        const INPUT_FIELDS = component.get("v.dynamicFields");

        let inputFieldValues = {};
        let formFieldsAllValid = true;
        let result = {};
        
        //get values and check for required fields if it has value
        for (let i = 0 ; i < INPUT_FIELDS.length ; i++){

            const INPUT_VALUE = INPUT_FIELDS[i];
            //console.log(INPUT_VALUE);

            //Skip inactive
            if(!INPUT_VALUE.Field.active) continue;
            
            //store field values
            if (INPUT_VALUE.Field.inputValue) {
                
                inputFieldValues[INPUT_VALUE.Field.key] = INPUT_VALUE.Field.inputValue;
                
                // Start 11/21/2023 CCN-EVE-3594-DV Von Pernicia - This will validate field even if field is not required
                let fieldValidity = false;
                fieldValidity = component.find('registrationFormFields').reduce(function (validSoFar, inputCmp) {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);

                if (!fieldValidity) {
                    formFieldsAllValid = false;
                }
                // End 11/21/2023 CCN-EVE-3594-DV Von Pernicia
            
            //check if the field with no value is required
            } else if (INPUT_VALUE.Field.required){
				
                let fieldValidity = false;
                if(!INPUT_VALUE.IsPicklist){
                    fieldValidity = component.find('registrationFormFields').reduce(function (validSoFar, inputCmp) {
                        inputCmp.reportValidity();
                        return validSoFar && inputCmp.checkValidity();
                    }, true);
                } else {
                    
                    /* CCN-EVE-2074-DV XEN REYES Oct2022 */
                    var regFormPLs = component.find('registrationFormFieldsPicklist');

                    if ($A.util.isArray(regFormPLs)) {
                        regFormPLs.every(rg => {
                            fieldValidity = rg.checkValidity();

                            /* CCN-2532 XEN REYES 29Jan2023 */
                            if(!fieldValidity) {
                                rg.showHelpMessageIfInvalid();
                                //return false;
                            }
                            return true;
                        })
                    } else {
                        fieldValidity = regFormPLs.checkValidity();
                        if(!fieldValidity) regFormPLs.showHelpMessageIfInvalid();
                    }
                }
                
                if (!fieldValidity) {
                    formFieldsAllValid = false;
                }
            }
        }
        
        result["inputs"] = inputFieldValues;
        result["validity"] = formFieldsAllValid;

        return result;
    },

    checkSelectedSessionsAndReturnSelectedSessions : function(component) {
        let sessionIdList = [];
        const BOX_PACK_FIELDS = component.find("boxPack");
		
        //check sessions selected
        if(BOX_PACK_FIELDS && ! Array.isArray(BOX_PACK_FIELDS)){
            if (BOX_PACK_FIELDS.get("v.value")) {
                sessionIdList.push(BOX_PACK_FIELDS.get("v.text"));
            }
        } else if(BOX_PACK_FIELDS) {
            for (let i = 0; i < BOX_PACK_FIELDS.length; i++) {
                if (BOX_PACK_FIELDS[i].get("v.value")) {
                    sessionIdList.push(BOX_PACK_FIELDS[i].get("v.text"));
                }
            }
        }
        
        return sessionIdList;
    },

    // Created [CCN859,CCN860,CCN861] JaysonLabnao Nov042021
    sortObjects : function(arr, column){

        arr.sort(function(a, b){
            let x;
            let y;
            if(column === 'EventDate' || column === 'StartTime'){
                x = new Date(a.EventDate + ' ' + a.StartTime);
                y = new Date(b.EventDate + ' ' + b.StartTime);
            }
            else if(column === 'EndTime'){
                x = new Date(a.EventDate + ' ' + a.EndTime);
                y = new Date(b.EventDate + ' ' + b.EndTime);
            }
            else{
                x = a[column];
                y = b[column];
            }
            if ( x < y ){
                return -1;
            }
            if ( x > y ){
                return 1;
            }
            return 0;
        });
        return arr;
    },

    // Created [Namespace Issue Fixes] JaysonLabnao Aug052022
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
                            
    //[CCN3301]                        
    getRankValues : function(component, event, helper) {
        const action = component.get('c.getRankAndRankGroupDependencies');
		action.setCallback(this, (response) =>{
			const STATE = response.getState();
			if(STATE === 'SUCCESS'){
				var result = response.getReturnValue();
            	//console.log(result);
                var arrayMapKeys = [];
            	//Leif Erickson de Gracia - CCN-EVE-3304-DV
                const defaultValue = ['-----'];
            		            	
            	//Leif Erickson de Gracia - CCN-EVE-3304-DV
                //arrayMapKeys.push({ key: '', value: ''});
        
				let dynamicFields = component.get("v.dynamicFields");
                let currentRankValue = component.get('v.sessionPart.Rank');
                component.set("v.selectedValueRank", currentRankValue);
        
                /* for(let i=0; i<dynamicFields.length; i++){
                    let field = dynamicFields[i].Field;
            		
            		if(field.label == 'Title/Rank'){             			
            			let defaultItem = {key: '', value: defaultValue }
                        if(field.picklistOptions[0].label == defaultValue){
                        	arrayMapKeys.push(defaultItem);
            				break;
                    	}
                    }
                }
                
                for(let i=0; i<dynamicFields.length; i++){
                    let field = dynamicFields[i].Field;
            		
            		if(field.label == 'Title/Rank'){             			
            			if(field.required && (currentRankValue == defaultValue || !currentRankValue) && !component.get("v.hasSelectedInvalidValue")){
                        	component.set("v.hasSelectedInvalidValue", true);
                    	}
                    }
                } */
                
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
		});
		$A.enqueueAction(action);
    },

})