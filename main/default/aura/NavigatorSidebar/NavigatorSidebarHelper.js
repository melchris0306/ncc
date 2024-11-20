({
    //Leif CCN-NAV-3557-DV
    // the function that reads the url parameters
    getUrlParameter : function(sParam) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;
        
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');
            if (sParam == 'id') {
                if (sParameterName[0] === sParam && sParameterName[1].length >= 15) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                } else if (sParameterName[1] === sParam && sParameterName[2].length >= 15) {
                    return sParameterName[2] === undefined ? true : sParameterName[2];
                }
            } else {
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                } 
            }
        }
    },


    getAvailableFields : function(component, event, helper) {
        //set the token param value to my token attribute
        let navigatorId = helper.getUrlParameter('id');
        console.log(navigatorId);
		var action = component.get("c.getMenuConfigurationFields");
        action.setParams({ 
            IdParams : navigatorId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                
                var resultEvent = response.getReturnValue();
                //component.set("v.menuConfigurationList", resultEvent);

                try {
                    // Sort based on sortOrder
                    resultEvent.sort(function(a, b) {
                        return parseInt(a.sortOrder) - parseInt(b.sortOrder);
                    });
    
                    console.log(resultEvent);
    
                    component.set("v.menuConfigurationList", resultEvent);
                } catch (e) {
                    console.error(e);
                }
                


            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                this.showToast("Error", errors[0].message, "error");
            }
            
            component.set("v.isEditDisabled", false);
        });
        
        $A.enqueueAction(action);
	},
    
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type,
            "mode" : "pester"
        });
        toastEvent.fire();
    },
    //Leif CCN-NAV-3557-DV END

    navigationClick : function(component, event, helper){
        let navigationName  = event.getParam('navigationName');
        let navigationLink  = event.getParam('navigationLink');
        let navigatorId     = helper.getUrlParameter('id');
        let contactId       = helper.getUrlParameter('contactId');
        let token           = helper.getUrlParameter('token');

        navigationLink += '/?id='+navigatorId+'&contactId='+contactId;

        console.log(navigationLink);
        let navigationData = component.get('v.navigationData');
        navigationData = _.map(navigationData, function(item){
            if(item.name !== navigationName){
                item.isSelected = false;
                return item;
            }
            item.isSelected = true;
            return item;
        })
        component.set('v.navigationData', navigationData);
        // if navigation item has a link redirect to the link
        if(navigationLink){
            location.href = navigationLink;
        }
    },

    initNavigatorAttributes : function(component, event, helper){
        const url_string = document.location.href;
        const navTabs = event.getParam('navigatorTabs');
        const contact = event.getParam('contact');
        const navigatorRecord = event.getParam('navigatorRecord');
        if(navTabs){
            let items = [];
            for (let i = 0; i < navTabs.length; i++) {
                let tab = navTabs[i];
                tab.label = tab.name;
                tab.name = tab.name.toLowerCase().replace(' ','_');
                if(tab.pageUrl){
                    let contactId = contact.contactId;
                    tab.href = tab.pageUrl+'?id='+navigatorRecord.id+'&contactId='+contactId;
                    
                    let baseUrl = url_string.substring(0,url_string.indexOf('?'));
                    if(baseUrl === tab.pageUrl){
                        tab.isSelected = true;
                    }
                }
                if(tab.expandedItems){
                    tab.expandedItems = tab.expandedItems.split('\n');
                }
                items.push(tab);
            }
            //populate sidebar
            component.set('v.navigationData', items);
        }
        if(navigatorRecord){
            component.getElement().style.setProperty('--theme-color1', navigatorRecord.themeColor1);
            component.getElement().style.setProperty('--theme-color2', navigatorRecord.themeColor2);
            component.getElement().style.setProperty('--theme-color3', navigatorRecord.themeColor3);
            component.getElement().style.setProperty('--theme-color3-intense', helper.increaseBrightness(navigatorRecord.themeColor3, -100));
        }

    },
    
    increaseBrightness : function(hex, percent){
        // strip the leading # if it's there
        hex = hex.replace(/^\s*#|\s*$/g, '');
    
        // convert 3 char codes --> 6, e.g. `E0F` --> `EE00FF`
        if(hex.length == 3){
            hex = hex.replace(/(.)/g, '$1$1');
        }
    
        var r = parseInt(hex.substr(0, 2), 16),
            g = parseInt(hex.substr(2, 2), 16),
            b = parseInt(hex.substr(4, 2), 16);
    
        return '#' +
           ((0|(1<<8) + r + (256 - r) * percent / 100).toString(16)).substr(1) +
           ((0|(1<<8) + g + (256 - g) * percent / 100).toString(16)).substr(1) +
           ((0|(1<<8) + b + (256 - b) * percent / 100).toString(16)).substr(1);
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
                console.log(errorMessage);
                return errorMessage;
            }
            else{
                console.log("Unknown error", JSON.stringify(errors));
                return "Unknown error", JSON.stringify(errors);
            }
        } else {
        	console.log("Unknown error", JSON.stringify(errors));
            return "Unknown error", JSON.stringify(errors);
        }
	},

})