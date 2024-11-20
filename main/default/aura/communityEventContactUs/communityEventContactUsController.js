({
    doInit : function(component, event, helper) {
		document.title = 'Loading....';
              
        var url_string = document.location.href;
        var eventId = (url_string.split('id=')[1]).slice(0,11);
        component.set('v.eventId',eventId);
        var action = component.get("c.getEventDetails");
        
        action.setParams({ 
            eventId : eventId
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                component.set('v.commentTag', resultEvent.contactTag);
                component.set('v.commentMessage', resultEvent.contactMessage);
                
                if(resultEvent.contactUsPageTitle != null || resultEvent.contactUsPageTitle !=  undefined){
                    component.set('v.contactUsPageTitle', resultEvent.contactUsPageTitle);
                    document.title = resultEvent.contactUsPageTitle;
                }else{
                    component.set('v.contactUsPageTitle', 'CONTACT US');  
                }
                
            }
        });
        
        $A.enqueueAction(action);
        
    },

    onClick : function(component, event, helper) {
        var navbar = component.find('myNavbar');
        $A.util.toggleClass(navbar, 'responsive');
    },
    
    handleSubmit : function(component, event, helper){
        const firstname = component.get("v.firstname");

        let allValid = component.find('contactUsForm').reduce(function (validSoFar, inputCmp) {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (allValid){
            component.set("v.showSpinner", true);
            helper.submitTask(component, event, helper);
        } 
    }
    
})