({
    getNavigatorDetails : function(component, helper){
        let url_string = document.location.href;
        const urlParams = new URLSearchParams(url_string);
        const contactId = urlParams.get('contactId');
        const token = Cookies.get('token');
        const action = component.get('c.getNavigationDetailsWithVerif');

        action.setParams({contactId, token});
        action.setCallback(this, function(response){
            const STATE = response.getState();
            if(STATE === 'SUCCESS'){
                let payload = JSON.parse(response.getReturnValue());
                console.log(payload);
                if(payload){
                    let eventParam = {};
                    const navRecord = payload.navigationRecord;
                    const contactRecord = payload.contact;
                    const navTabs = payload.navItemList;
                    if(navRecord){
                        component.set('v.navigatorRecord', navRecord);
                        eventParam.navigatorRecord = navRecord;
                        component.getElement().style.setProperty('--theme-color1', navRecord.themeColor1);
                    }
                    if(contactRecord){
                        helper.setContact(component, contactRecord);
                        eventParam.contact = contactRecord;
                        component.set('v.profilePicURL', contactRecord.profilePicture);
                    } 
                    if(navTabs) eventParam.navigatorTabs = navTabs;
                    // send Navigator Record and Contact to other components on the page.
                    const navigatorEvent = $A.get('e.c:NavigatorRecord');
                    navigatorEvent.setParams(eventParam);
                    navigatorEvent.fire();
                }
                else{
                    helper.showToastError(helper.logError('Error: No response received.'));
                }
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
            }
        });

        $A.enqueueAction(action);
    },
    
    setContact : function(component, contact){
        component.set('v.contact', contact);
        let contactName = contact.name;
        let matches = contactName.match(/\b(\w)/g); 
        let acronym = matches.join('');
        let initials = acronym.substring(0,2).toUpperCase();
        component.set('v.initials', initials);
    },

    showToastError : function(message) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "type" : "error",
            "message": message
        });
        toastEvent.fire();
    },

    logError : function(errors){
        if (errors) {
            if (errors[0] && errors[0].message) {
                // log the error passed in to AuraHandledException
                let errorMessage = "Error message: " + errors[0].message
                console.error(errorMessage);
                return errorMessage;
            }
            else{
                console.error("Unknown error", JSON.stringify(errors));
                return "Unknown error", JSON.stringify(errors);
            }
        } else {
        	console.error("Unknown error", JSON.stringify(errors));
            return "Unknown error", JSON.stringify(errors);
        }
	},
})