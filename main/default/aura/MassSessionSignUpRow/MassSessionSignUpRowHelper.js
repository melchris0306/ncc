({
    doInitHelper : function(component, event, helper) {
        //Making a call to the Apex method to fetch the values of Rating field
        var action = component.get("c.fetchRankValues");
        
        //Getting the value of Rating field for a particular record from Component
        var rankValue = component.get('v.sessionPart.Rank');
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var rankValues = response.getReturnValue();
                
                var rankId;
                var rankOptions = [];
                
                for(var i=0; i< rankValues.length; i++){
                    if(i == 0){
                        /** We need to make sure the first value of the Picklist is always None */
                        // Start CCN-EVE-2327-DV: Gabriel Delavin updated the 1st item of picklist from "--None--" to "----"
                        if(rankValue != undefined){
                            rankOptions.push({
                                id: 0, 
                                label: '----'
                            });
                        }else{
                            rankOptions.push({
                                id: 0, 
                                label: '----',
                                selected: true
                            });
                       	// End CCN-EVE-2327-DV: Gabriel Delavin updated the 1st item of picklist from "--None--" to "----"
                            rankId = 0;
                        }
                    }
                    
                    /** Am trying to compare the Rating field value with the list
                    that we get back from the Apex method and when there is a match
                    am adding selected: true to the JSON Object. */
                    
                    if(rankValues[i] == rankValue){
                        rankOptions.push({
                            id: i+1, 
                            label: rankValues[i],
                            selected: true 
                        });
                        rankId = i+1;
                    }else{
                        rankOptions.push({
                            id: i+1, 
                            label: rankValues[i]
                        });
                    }
                }
                var serverResponse = {
                    selectedRankId: rankId,
                    rank: rankOptions
                };
                
                component.set("v.optionsRank", serverResponse.rank);
                component.set("v.selectedValueRank", serverResponse.selectedRankId);
            }            
            else if(state === "INCOMPLETE"){
                
            }
                else if(state === "ERROR"){
                    var errors = response.getError();
                    if(errors){
                        if(errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    }else{
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    },
    
    handleFireEvent : function(component, event, helper) {
        var sessionPart = component.get("v.sessionPart");
        console.log('ChildValue: ' + JSON.stringify(sessionPart));
        var compEvent = component.getEvent("massSessionEventReg");
        compEvent.setParams({"childSessionPart" : sessionPart });
        compEvent.fire();
    },

    handleRemoveHelper: function(component, event, helper) {
        component.set('v.loading', true);
        var partSessionId = component.get('v.sessionPart.Id');
        component.set('v.isLoading', true);
        var action = component.get('c.removeRole');
        action.setParams({
            partSessionId : partSessionId
        });
        action.setCallback(this, function(response) {
            component.set('v.loading', false);
            var state = response.getState();
            var result = response.getReturnValue();
            //alert(state);
            if(state === "SUCCESS"){
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'Success! Participant has been canceled from the session.',
                        duration:' 3000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'pester'
                    });
                   	toastEvent.fire();
                    $A.get("e.force:refreshView").fire();
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'You cannot remove Session Participant that is not yet registered.',
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

    //XEN REYES March 5, 2023 CCN-EVE-2631-DV
    getRankOptions : function(component, event, helper){
		const action = component.get('c.getRankAndRankGroupDependencies');
		action.setCallback(this, (response) =>{
			const STATE = response.getState();
			if(STATE === 'SUCCESS'){
				var result = response.getReturnValue();
                var arrayMapKeys = [];
            
            	//Leif Erickson de Gracia - CCN-EVE-3304-DV
                const defaultValue = ['----'];
            		
            	
                let currentRankValue = component.get('v.sessionPart.Rank');
                component.set("v.selectedValueRank", currentRankValue);
            	
            	//Leif Erickson de Gracia - CCN-EVE-3304-DV
                arrayMapKeys.push({
                                    key: '', 
                                    value: defaultValue 
                                });
            
                for(var key in result){
                    
                    arrayMapKeys.push({
						key: key, 
						value: result[key]});
                }
                
                console.log(arrayMapKeys);
                component.set("v.dataCollectionRecords", arrayMapKeys);
            
                component.set("v.isDoneLoadingItem", true);
            

			}
			else{
				console.error({ error : response.getError() });
			}
		});
		$A.enqueueAction(action);
	},
})