({
	init: function(component, event, helper) {
        if(document.referrer){
            let previousUrl = document.referrer;
            if(previousUrl.includes('navigator')) component.set('v.isSumerianModalOpen', false);
        }
    },

    handleNavigatorRecord : function(component, event, helper){
        helper.initNavigatorAttributes(component, event, helper);
    },
    
    openPopup : function(component, event, helper){
        // if there's no AWS the mascot image shouldn't open the iframe.
        const navRecord = component.get('v.navigatorRecord');
        if(!navRecord.awsLink){
            return;
        }
        component.set('v.isSumerianModalOpen', true);
        const speechBubble = component.find('chat-background');
        $A.util.removeClass(speechBubble, 'chat-background-pop');
    },
    closePopup : function(component, event, helper){
        component.set('v.isSumerianModalOpen', false);
        const speechBubble = component.find('chat-background');
        $A.util.addClass(speechBubble, 'chat-background-pop');
    }
})