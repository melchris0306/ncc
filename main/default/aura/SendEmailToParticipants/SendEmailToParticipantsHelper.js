({
	getEmailTemplate : function(component) {
        var action = component.get("c.getEmailTemplate");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                let resp =response.getReturnValue() ;
                let lables= [] ; 
                resp.forEach(function(key) {
                    lables.push({"label":key.Name ,"value":key.Name});
                });
                component.set("v.emailTemplates", lables);
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'Error fetching Compass Email Templates',
                    duration:' 3000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
                this.closeQuickAction();
            }
        })
        $A.enqueueAction(action);
	},
    
	getStatusValues : function(component) {
        var action = component.get("c.getStatusValues");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var fieldMap = [];
                
                fieldMap.push({"label":"--None--" ,"value":"None"});

                //CCN-1104 Xen Reyes Jan. 6, 2022
                fieldMap.push({"label":"All" ,"value":"All"});

                for(var key in result){
                    fieldMap.push({"label":result[key] ,"value":key});
                }
                component.set("v.statusOptions", fieldMap);
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'Error fetching Status Picklist Values',
                    duration:' 3000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
                this.closeQuickAction();
            }
        });
        $A.enqueueAction(action);
	},
    
    handleTemplateChangeHelper: function(component, event, helper){
        //alert('Template: ' + component.get("v.templateValue"));
    },
    
    handleStatusChangeHelper: function(component, event, helper){
        //alert('Status: ' + component.get("v.statusValue"));
    },
    
    handleSendEmailHelper: function(component, event, helper){
        var eventId = component.get("v.recordId ");
        var statusValue = component.get("v.statusValue");
        var templateValue = component.get("v.templateValue");
        
        try {
            var action = component.get("c.sendEmails");
            action.setParams({
                eventId : eventId,
                statusValue : statusValue,
                templateValue : templateValue
            });
            action.setCallback(this, function(response) {
                
            });
            
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Success',
                message: 'Successfully queued up mass email send',
                duration:' 3000',
                key: 'info_alt',
                type: 'success',
                mode: 'pester'
            });
            toastEvent.fire();
            
            $A.enqueueAction(action);
        }
        catch(err) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Error',
                message:'Error sending emails',
                duration:' 3000',
                key: 'info_alt',
                type: 'error',
                mode: 'pester'
            });
            toastEvent.fire();
        }
        this.closeQuickAction();
    },
    
    closeQuickAction: function(){
        // Close the action panel
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})