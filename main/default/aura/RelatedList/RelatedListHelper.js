({
        fixNameSpace: function(component) {
        this.showSpinner(component);
        var action = component.get("c.handleNameSpace");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //var result = response.getReturnValue();
                var records =response.getReturnValue();
                var actions = [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ];
                
        //Updated by MMallorca 08022023 [CCN-3360] - Remove Target
        component.set('v.columns', [
            {label: 'Session Name', fieldName: 'linkName', type: 'url', typeAttributes: {label: { fieldName: 'Name' }}},
            {label: 'Status', fieldName: records.recStatus, type: 'text'},
            {label: 'Start Date Time', fieldName: records.startDateTime, type: 'text'},
            {label: 'Time Zone', fieldName: records.timeZone, type: 'text'},
            { type: 'action', typeAttributes: { rowActions: actions }}
        ]);
                this.hideSpinner(component);
            } else if (state === "ERROR") {
                this.handleResponseError(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    getData: function(component) {
        this.showSpinner(component);
        var action = component.get("c.getData");
        action.setParams({
            "parentRecordId": component.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //var result = response.getReturnValue();
                var records =response.getReturnValue();
                
                records.sessionList.forEach(function(record){
                    record.linkName = '/'+record.Id;
                });
                component.set("v.data", records.sessionList);
                component.set("v.eventId", records.eventId);
                this.hideSpinner(component);
            } else if (state === "ERROR") {
                this.handleResponseError(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    
    delete: function (component, recordId) {
    this.showSpinner(component);
    var action = component.get("c.deleteRec");
    action.setParams({
    "parentRecordId": component.get("v.recordId"),
    "recordId": recordId
    
});
action.setCallback(this, function(response) {
    var state = response.getState();
    if (state === "SUCCESS") {
        var result = response.getReturnValue();
        component.set("v.data", result);
        
        this.hideSpinner(component);
        this.showToast(component, 'success', 'Record was successfully deleted.');
    } else if (state === "ERROR") {
        this.handleResponseError(response.getError());
    }
});
$A.enqueueAction(action);
},
    
    showSpinner: function (component) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
        
        hideSpinner: function (component) {
            var spinner = component.find("spinner");
            $A.util.addClass(spinner, "slds-hide");
        },
            
            showToast : function(component, type, message) {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Session',
                    message: message,
                    duration:' 3000',
                    key: 'info_alt',
                    type: type,
                    mode: 'pester'
                });
                toastEvent.fire();
            },
                
                handleResponseError: function (helper, errors) {
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            this.showToast(component, 'error', "Error message: " +
                                           errors[0].message);
                        }
                    } else {
                        this.showToast(component, 'error', 'Unknown error.');
                    }
                    this.hideSpinner(component);
                }
})