({
    doInit : function(component, event, helper) {
        
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
                component.set('v.backgroundImageURL', resultEvent.HeroUrl);
                component.set('v.title', resultEvent.title);
                component.set('v.subtitle', resultEvent.subtitle);
                component.set('v.surveyId', resultEvent.SurveyId);
            }
        });
        
        $A.enqueueAction(action);
        
    },
    onClick : function(component, event, helper) {
        console.log('------------  test');
        var navbar = component.find('myNavbar');
        $A.util.toggleClass(navbar, 'responsive');
    }
    
    
})