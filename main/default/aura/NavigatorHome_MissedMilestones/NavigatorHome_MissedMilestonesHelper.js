({
    initializeMilestones : function(component, event, helper) {
        const ITEMS_TO_DISPLAY_COUNT = component.get('v.itemsToDisplayCount');
        let url_string = document.location.href;
        const urlParams = new URLSearchParams(url_string);
        const contactId = urlParams.get('contactId');
        const action = component.get('c.getMissedMilestones');
        action.setParams({ contactId });
        action.setCallback(this, function(response){
            const state = response.getState();
            if(state === 'SUCCESS'){
                let milestones = response.getReturnValue();
                component.set('v.milestones', milestones);
                let milestonesToDisplay = [];
                if(milestones.length > ITEMS_TO_DISPLAY_COUNT){
                    milestonesToDisplay = milestones.splice(0, ITEMS_TO_DISPLAY_COUNT);
                }
                else{
                    milestonesToDisplay = milestones;
                }
                component.set('v.milestonesToDisplay', milestonesToDisplay);
            }
            else{
                // TODO: add error handling
                console.log('NavigatorHome_MissedMilestones', response.getError());
            }
        });
        $A.enqueueAction(action);
    }
})