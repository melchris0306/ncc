({
    doInit : function(component, event, helper) {
    	helper.getEmailTemplate(component);
        helper.getStatusValues(component);
    },
    
    handleTemplateChange: function(component, event, helper){
        helper.handleTemplateChangeHelper(component, event, helper);
    },
    
    handleStatusChange: function(component, event, helper){
        helper.handleStatusChangeHelper(component, event, helper);
    },
    
    handleSendEmail: function(component, event, helper){
        helper.handleSendEmailHelper(component, event, helper);
    }
})