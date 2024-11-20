({
    doInit : function(component, event, helper) {
        
        helper.isIphone(component, event);
        var parameterURL = '';
        const queryString = decodeURIComponent(window.location.search);
        
        var eventId = (queryString.split('id=')[1]).split('&')[0];
        component.set('v.eventId', eventId);
        parameterURL = 'id=' + eventId;
        
        
        var emailstr = '';
        try {
            emailstr = (queryString.split('email=')[1]).split('&')[0];
            parameterURL = parameterURL + '&email=' + emailstr;
        }
        catch(err) {
            emailstr = '';
        }
        
        var PM = '';
        try {
            PM = (queryString.split('pm=')[1]).split('&')[0];
            parameterURL = parameterURL + '&pm=' + PM;
        }
        catch(err) {
            PM = '';
        } 
        
        component.set('v.parameterURL', parameterURL);
		
        var action = component.get("c.getEventDetails");
        
        action.setParams({ 
            eventId : eventId
        });
        
        action.setCallback(this, function(response){
            
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                component.set('v.backgroundImageURL', resultEvent.HeroUrl);
                component.set('v.campaignLogoURL', resultEvent.CampaignLogoUrl);
                component.set('v.title', resultEvent.title);
                component.set('v.subtitle', resultEvent.subtitle);
                component.set('v.status', resultEvent.CampaignStatus);
            }
            else{
                console.log(response.getError());
            }
        });
        
        $A.enqueueAction(action);
        
    },
    
    refreshPage : function(component, event, helper){
        component.set('v.loaded',true);
        var delay=1500; // 1.5 seconds delay
        setTimeout(function() {
			$A.get('e.force:refreshView').fire();
    	}, delay);
        component.set('v.loaded',false);
		
    },

    
})