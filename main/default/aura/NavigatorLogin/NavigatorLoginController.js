({
    init : function(component, event, helper){
        helper.initializeLoginPage(component, event, helper);
        
    },

    /* START - Jonah Baldero -  CCN-NAV-3417-DV - Sept 18, 2023
    sendToken : function(component, event, helper){
        helper.doSendToken(component, event, helper);	
    },
    
       END - Jonah Baldero -  CCN-NAV-3417-DV */
    
    submit : function(component, event, helper){
        helper.doSubmit(component, event, helper);	
    },
    
    inputEmail : function(component, event, helper){
        helper.setSubmitButtonIsDisabled(component, event, helper);
    },

    jsCookieLoaded : function(component, event, helper){
        component.set('v.isFormLoading', false);
    },

    // keyPress : function(component, event, helper){
        
    // }
        
})