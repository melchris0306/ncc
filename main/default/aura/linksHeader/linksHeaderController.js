({
    doInit : function(component, event, helper) {
        
        const queryString = decodeURIComponent(window.location.search);
        var campaignId = (queryString.split('id=')[1]).split('&')[0];

        component.set('v.campaignId', campaignId);
        console.log('campaignId: ' + campaignId);

        var action = component.get("c.getcampaignDetail");
        
        action.setParams({ 
            campaignId : campaignId
        });

        action.setCallback(this, function(response){
            console.log('callbek');
            var state = response.getState();
            console.log('response: ' + response.getReturnValue());

            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.campaignLogoURL', result.Logo_URL__c);
                component.set('v.campaignName', result.Name);
            }
        });

        $A.enqueueAction(action);

    }
})