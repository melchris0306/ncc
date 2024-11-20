({
    showToast : function(component, event, message, title,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }, 
    
    getPicklistValues : function (component, fieldName){
            
        var action = component.get("c.getPickListValues");
        action.setParams({ fieldName : fieldName});
        
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                if (fieldName == 'Readiness_Self_Ranking__c'){
                    component.set("v.readinessPicklistValues",response.getReturnValue());
                }
                if (fieldName == 'Session_Participation__c'){
                    component.set("v.sessionPicklistValues",response.getReturnValue());
                }
            }
            console.log(response.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    
    getAttendedJSON : function(component){
        var recId = component.get("v.recordId");
        var action = component.get("c.getEventAttendedParticipantFieldsJSON");
        action.setParams({sessionId : recId});
        action.setCallback(this,function(response){
            try{
                var state = response.getState();
                if(state === "SUCCESS"){
                    var jsonResponse = JSON.parse(response.getReturnValue());
                    component.set("v.showReadinessSelfRanking", 	jsonResponse["Readiness_Self_Ranking-Session_Participant__c|Readiness_Self_Ranking__c"]!=undefined);
                    component.set("v.showSessionParticipation", 	jsonResponse["Session_Participation-Session_Participant__c|Session_Participation__c"]!=undefined);
                    component.set("v.requireReadinessSelfRanking", 	jsonResponse["Readiness_Self_Ranking-Session_Participant__c|Readiness_Self_Ranking__c"]==true);
                    component.set("v.requireSessionParticipation", 	jsonResponse["Session_Participation-Session_Participant__c|Session_Participation__c"]==true);
                    console.log("show RSR: "+component.get("v.showReadinessSelfRanking"));
                    console.log("require RSR: "+component.get("v.requireReadinessSelfRanking"));
                    console.log("show SP: "+component.get("v.showSessionParticipation"));
                    console.log("require SP: "+component.get("v.requireSessionParticipation"));
                }
                else{
                	console.log('getAttendedJSON failed');
                }
            }
            catch(e){
                console.log(e);
            }            
        });
        $A.enqueueAction(action);
    },
    
    //Added for CCN-EVE-11-DV Feb.15.2022-->
    sortColumn : function(component, event, helper, columnName){
        var currentColumnSorted = component.get("v.sortColumn");
        var currentSortAsc = component.get("v.sortAsc");
        if(columnName === currentColumnSorted) currentSortAsc = !currentSortAsc;
        else{
            currentColumnSorted = columnName;
            currentSortAsc = true;
        }
        
        component.set("v.sortColumn", currentColumnSorted);
        component.set("v.sortAsc", currentSortAsc);
        
        //do the thing here
        var fieldName = undefined;
        if(currentColumnSorted == 'Number') fieldName = 'Name';
        else if(currentColumnSorted == 'Contact') fieldName = 'Contact_Name__c';
        else if(currentColumnSorted == 'Date') fieldName = 'Session_Start_Date__c';
        else if(currentColumnSorted == 'Status') fieldName = 'Status__c';
        else if(currentColumnSorted == 'Ranking') fieldName = 'Readiness_Self_Ranking__c';
        else if(currentColumnSorted == 'Participation') fieldName = 'Session_Participation__c';
        
        var recordList = component.get("v.participants");
        
        if(fieldName){
            recordList.sort(function(a,b){
                var ax = a[fieldName].toLowerCase();
                var bx = b[fieldName].toLowerCase();
                var t1 = ax == bx,                    
                    t2 = (!ax && bx) || (ax < bx);                
                return t1? 0: (currentSortAsc?-1:1)*(t2?1:-1);                
            });
            component.set("v.participants", recordList);
        }
	}
    
    /**
    getAttendedFields : function (component){
        var action = component.get("c.getAttendedFields");
        action.setParams({ recordId : component.get("v.recordId")});
        
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                //
                
            }
        });
        $A.enqueueAction(action);
    }
    **/
})