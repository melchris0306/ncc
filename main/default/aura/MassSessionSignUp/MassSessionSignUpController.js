({
    doInit : function(component, event, helper) {
        helper.doInitHelper(component, event, helper);
        //Leif Erickson de Gracia - CCN-EVE-3304-DV
        helper.doGetFieldConfig(component, event, helper);
    },
    
    handleComponentEvent : function(component, event, helper) {
        helper.handleComponentEventHelper(component, event, helper);
    },
    
    handleSaveSignUp : function(component, event, helper) {
        helper.handleSaveSignUpHelper(component, event, helper);
    },
    
    handleEditSignUp : function(component, event, helper) {
        helper.handleEditSignUpHelper(component, event, helper);
    },    
    
    handleCancelSignUp : function(component, event, helper) {
        helper.handleCancelSignUpHelper(component, event, helper);
    },    
    
    returnToCalendar : function(component, event, helper) {
        helper.returnToCalendarHelper(component, event, helper);
    },
})