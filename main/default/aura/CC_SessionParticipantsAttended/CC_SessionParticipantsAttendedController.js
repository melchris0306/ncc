({
    doInit : function(component, event, helper) {
        component.set("v.No_participants_to_display", $A.get("$Label.c.No_participants_to_display"));
        component.set("v.Btn_MarkAsAttended", $A.get("$Label.c.Btn_MarkAsAttended"));

        /** Removed for CCN-975, replaced with custom table to accomodate picklist fied
        component.set("v.columns",[
            {label:"Session Participant Number", fieldName:"Name",type:"text"},
            {label:"Contact", fieldName:"Contact_Name__c",type:"text"},
            {label:"Session Start Date", fieldName:"Session_Start_Date__c",type:"date"},
            {label:"Status", fieldName:"Status__c",type:"text"},
            {label:"Readiness Self Ranking", fieldName:"Readiness_Self_Ranking__c", type:"picklist", editable: true},
            {label:"Session Participation", fieldName:"Session_Participation__c", type:"picklist", editable: true},
        ]);
		**/
        var action = component.get("c.getSessionParticipants");
        action.setParams({ recordId : component.get("v.recordId")});
        
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.participants",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        helper.getAttendedJSON(component);
        helper.getPicklistValues(component, 'Readiness_Self_Ranking__c');
        helper.getPicklistValues(component, 'Session_Participation__c');
        
        component.set("v.sortColumn", 'Contact');
        
    },
    handleMarkAsAttendedClick : function(component, event, helper) {
        var participants = component.get("v.participants");
        var selectedParticipants = participants.filter(p => p.isChecked == true);
        
        console.log('Selected Participants:');
        console.log(selectedParticipants);
        
        if(component.get("v.requireReadinessSelfRanking")){
            if(selectedParticipants.filter(p=>p.Readiness_Self_Ranking__c=="").length > 0){
            	helper.showToast(component, event, "Fill in required fields",'ERROR','error');
                return;
            }
        }        
        
        if(component.get("v.requireSessionParticipation")){
            if(selectedParticipants.filter(p=>p.Session_Participation__c=="").length > 0){
            	helper.showToast(component, event, "Fill in required fields",'ERROR','error');
        		return;
            }
        }
        
        
        if(selectedParticipants.length == 0) {
            helper.showToast(component, event, $A.get("$Label.c.AttendedWarningMessage") ,'ERROR','error');
        } else {
            var action = component.get("c.markSessionParticipantsToAttended");

            action.setParams({ recordId : component.get("v.recordId"), selectedParticipants : selectedParticipants});        
            action.setCallback(this,function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    helper.showToast(component, event, $A.get("$Label.c.AttendedSuccessMessage") ,'SUCCESS','success');
                    component.set("v.participants",response.getReturnValue());
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            helper.showToast(component, event, errors[0].message ,'ERROR','error');
                        }
                    } else {
                        helper.showToast(component, event, "Unknown error" ,'ERROR','error');
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },
    updateSelectedRecord : function(component,event,helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.selectedParticipants', selectedRows);
        component.set('v.selectedRowsCount', selectedRows.length);
    },
    
    selectAllCheckbox: function(component, event, helper) {
        console.log('selectAllCheckbox');
        var selectedHeaderCheck = event.getSource().get("v.value");
        var updatedAllRecords = [];
        var participants = component.get("v.participants");
        for (var i = 0; i < participants.length; i++) {
            // check if header checkbox is 'true' then update all checkbox with true and update selected records count
            // else update all records with false and set selectedCount with 0  
            if (selectedHeaderCheck == true) {
                participants[i].isChecked = true;
                component.set("v.selectedCount", participants.length);
            } else {
                participants[i].isChecked = false;
                component.set("v.selectedCount", 0);
            }
            updatedAllRecords.push(participants[i]);
        }
        component.set("v.participants", updatedAllRecords);
    },
 
    checkboxSelect: function(component, event, helper) {
        // on each checkbox selection update the selected record count
        console.log('checkboxSelect');
        var selectedRec = event.getSource().get("v.value");
        var getSelectedNumber = component.get("v.selectedCount");
        if (selectedRec == true) {
            getSelectedNumber++;
        } else {
            getSelectedNumber--;
            component.find("selectAllId").set("v.value", false);
        }
        component.set("v.selectedCount", getSelectedNumber);
        // if all checkboxes are checked then set header checkbox with true  
        if (getSelectedNumber == component.get("v.totalRecordsCount")) {
            component.find("selectAllId").set("v.value", true);
        }
    },
 
    getSelectedRecords: function(component, event, helper) {
        var allRecords = component.get("v.participants");
        var selectedRecords = [];
        for (var i = 0; i < allRecords.length; i++) {
            if (allRecords[i].isChecked) {
                selectedRecords.push(allRecords[i].objAccount);
            }
        }
    },
    //Added for CCN-EVE-11-DV Feb.15.2022
    sortByNumber: function(component, event, helper){
        helper.sortColumn(component, event, helper, "Number");
    },
    sortByContact: function(component, event, helper){
        helper.sortColumn(component, event, helper, "Contact");
    },
    sortByDate: function(component, event, helper){
        helper.sortColumn(component, event, helper, "Date");
    },
    sortByStatus: function(component, event, helper){
        helper.sortColumn(component, event, helper, "Status");
    },
    sortByRanking: function(component, event, helper){
        helper.sortColumn(component, event, helper, "Ranking");
    },
    sortByParticipation: function(component, event, helper){
        helper.sortColumn(component, event, helper, "Participation");
    }
})