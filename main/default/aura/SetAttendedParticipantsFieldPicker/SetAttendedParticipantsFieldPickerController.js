({
	doInit : function(component, event, helper) {
		helper.getAvailableFields(component, event, helper);
	},
    
    handleAttendedParticipantFields : function(component, event, helper){
        helper.saveAttendedParticipantFields(component, event, helper);
    },
    
    handleEdit : function(component, event, helper){
        component.set("v.isReadOnly" , false);
    }, 

    handleCancel : function(component, event, helper){
        component.set("v.isReadOnly" , true);
        component.set("v.attendedParticipantsFields", component.get("v.attendedParticipantsFieldsCopy"));
    },

    checkAllFields : function(component, event, helper){
        let isChecked = event.getSource().get("v.checked");
        let checkBoxName = event.getSource().getLocalId();
        let resultList = component.get("v.attendedParticipantsFields");
      
        for (let i = 0 ; i < resultList.length ; i++){
            if (checkBoxName == "selectAllFieldCheckbox"){
                resultList[i].active = isChecked;
            } else {
                resultList[i].required = isChecked;
            }
        }

        component.set("v.attendedParticipantsFields", resultList);
    },

    checkSelectAllAndSetRequired : function(component, event, helper){
        let resultList = component.get("v.attendedParticipantsFields");
        let isSelectAll = true;
        let isRequiredAll = true;

        for (let i = 0 ; i < resultList.length ; i++){
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
        component.set("v.attendedParticipantsFields", resultList);
    }, 

    checkRequiredAll : function(component, event, helper){
        let resultList = component.get("v.attendedParticipantsFields");
        let isRequiredAll = true;

        for (let i = 0 ; i < resultList.length ; i++){
            if(!resultList[i].required){
                isRequiredAll = false;
            }
        }

        component.set("v.requiredAll", isRequiredAll);
    }
})