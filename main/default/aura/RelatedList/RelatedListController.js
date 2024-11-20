({
    doInit: function(component, event, helper) {
        helper.fixNameSpace(component);
        helper.getData(component);
    },
    
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        
        switch (action.name) {
            case 'edit':
                var editRecordEvent = $A.get("e.force:editRecord");
                editRecordEvent.fire({
                    "recordId":  row.Id
                });
                break;
            case 'delete':
                var page = component.get("v.page") || 1;
                helper.delete(component, row.Id);
                break;
        }
    },
    
    createRecord : function (component) {
        var createRecordEvent = $A.get("e.force:createRecord");
        var objectType = component.get("v.objectType");
        
        createRecordEvent.fire({
            "entityApiName": objectType
        });
    },
    
    handleApplicationEvent: function (component, event, helper) {
        helper.getData(component);
    },
    
    
    navigateToRelatedList: function(component,event,helper){
        var rlEvent = $A.get("e.force:navigateToRelatedList");
        rlEvent.setParams({
            "relatedListId": "CC_Sessions__r",
            "parentRecordId": component.get("v.recordId")
        });
        rlEvent.fire();
    },
    gotoURL : function (component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": $A.get("$Label.c.View_Calendar_URL") +component.get("v.eventId")
        });
        urlEvent.fire();
    }
})