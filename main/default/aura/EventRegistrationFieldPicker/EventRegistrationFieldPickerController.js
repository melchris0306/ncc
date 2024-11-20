({
	doInit : function(component, event, helper) {
		helper.getAvailableFields(component, event, helper);
	},
    
    handleRegistrationForm : function(component, event, helper){
        helper.saveRegistrationForm(component, event, helper);
    },
    
    handleEdit : function(component, event, helper){
        component.set("v.isReadOnly" , false);
    }, 

    handleCancel : function(component, event, helper){
        component.set("v.isReadOnly" , true);
        component.set("v.registrationFields", component.get("v.registrationFieldsCopy"));
    },

    checkAllFields : function(component, event, helper){
        let isChecked = event.getSource().get("v.checked");
        let checkBoxName = event.getSource().getLocalId();
        let resultList = component.get("v.registrationFields");
        //Start [CCN-EVE-2593-DV] RIANNO RIZARRI Mar14.2023 - Added a variable to check if there is an inactive field but the user
        //                                                    clicks the 'Is required?'. An error toast would show up.
        let hasRequiredInactive = false;
        //End [CCN-EVE-2593-DV]
        for (let i = 0 ; i < resultList.length ; i++){
            
            if (checkBoxName == "selectAllFieldCheckbox"){
                resultList[i].active = isChecked;
            } else {
                if(resultList[i].active){
                    resultList[i].required = isChecked;
                }else{
                    //Start [CCN-EVE-2593-DV]
                    hasRequiredInactive = true;
                    //End [CCN-EVE-2593-DV]
                }
            }
            
        }
        //Start [CCN-EVE-2593-DV]
        if(hasRequiredInactive){
            component.set("v.requiredAll", false);
            helper.showToast("Error", "All fields are not active.", "error");
        }
        //End [CCN-EVE-2593-DV]

        component.set("v.registrationFields", resultList);
    },

    checkSelectAllAndSetRequired : function(component, event, helper){
        let resultList = component.get("v.registrationFields");
        let isSelectAll = true;
        let isRequiredAll = true;
        let isTitleRank = false;
        let isTitle =false;
        /*Start [CCN-EVE-3297-DV] Gabriel Delavin Aug.13.2023 - Added validation to not allow Title/Rank and Title to be selected by user*/
        for (let i = 0 ; i < resultList.length ; i++){
            if(resultList[i].label == 'Title/Rank' && resultList[i].active){
                isTitleRank = true;
            }
            if(resultList[i].label == 'Title' && resultList[i].active){
                isTitle = true;
            }
            if(isTitleRank && isTitle && (resultList[i].label == 'Title' || resultList[i].label == 'Title/Rank')){
                resultList[i].active = false;
                helper.showToast("Error", "Please select either the Title field or the Title/Rank field.", "error");
            }
            //End [CCN-EVE-3297-DV] 
            if (!resultList[i].active){
                isSelectAll = false;
                resultList[i].required = false;
                isRequiredAll = false;
            }

            if(!resultList[i].required){
                isRequiredAll = false;
            }
        }
        component.set("v.selectAll", isSelectAll);
        component.set("v.requiredAll", isRequiredAll);
        component.set("v.registrationFields", resultList);
    }, 

    checkRequiredAll : function(component, event, helper){
        let resultList = component.get("v.registrationFields");
        let isRequiredAll = true;

        for (let i = 0 ; i < resultList.length ; i++){
            if(resultList[i].active){
                if(!resultList[i].required){
                    isRequiredAll = false;
                }
            //Start [CCN-EVE-2593-DV] RIANNO RIZARRI Feb23.2023 - Added another if statement for the scenario that the user clicks required but the field is not active. An error toast would show up.
            }else if(resultList[i].required && !resultList[i].active){
                helper.showToast("Error", "Field is not active.", "error");
                resultList[i].required = false;
                isRequiredAll = false;
                break;
            }
            //End [CCN-EVE-2593-DV] RIANNO RIZARRI Feb23.2023
            
        }
        component.set("v.registrationFields", resultList);
        component.set("v.requiredAll", isRequiredAll);
    }
})