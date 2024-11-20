({
    isIphone : function(component, event) {
        var isPhone = $A.get("$Browser.isPhone");
        var onPhone = false;
        component.set('v.isPhone', isPhone);
        
        if(isPhone){
            onPhone = true;
            component.set('v.isPhoneVal', 'background');
        }
        else{
            component.set('v.isPhoneVal', 'background-image');
        }
        return onPhone;
    },

    getUserDetail : function(component, event, PM, helper) { // Modified by JaysonLabnao CCN-App Exchange-2311-QA-TE-SMOKE-22 Nov302022

        var cmpTarget = component.find('compass-topnav-login');
        var cmpTarget2 = component.find('compass-topnav-profile');
        var cmpTarget4 = component.find('compass-topnav-mobile-menu-login');
        var cmpTarget5 = component.find('compass-topnav-mobile-menu-logout');
        var cmpTarget6 = component.find('compass-topnav-mobile-menu-name');
 
        //var cmpTarget3 = component.find('compass-topnav-mobile-menu-avatar');
        //var cmpTarget7 = component.find('compass-topnav-mobile-menu-avatar2');
        
        var action = component.get("c.getParticipantDetailByNumber");

        action.setParams({ 
            participantNumber : PM,
        });

        action.setCallback(this, function(response){
            console.log('callback');
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var resultEvent = helper.cleanUpNamespace(response.getReturnValue()); // Modified by JaysonLabnao CCN-App Exchange-2311-QA-TE-SMOKE-22 Nov302022

                console.log('----resultEvent' +resultEvent);

                component.set('v.FirstName',resultEvent.Member_Contact__r.FirstName);
                component.set('v.LastName',resultEvent.Member_Contact__r.LastName);


                console.log('---------- Profile_Picture_URL__c' + resultEvent.Member_Contact__r.Profile_Picture_URL__c);

                if(resultEvent.Member_Contact__r.Profile_Picture_URL__c != '' && resultEvent.Member_Contact__r.Profile_Picture_URL__c != null){
                    component.set('v.ProfilePicURL',resultEvent.Member_Contact__r.Profile_Picture_URL__c);
                }else{
                    console.log('---------- no picture');
                    //component.set('v.ProfilePicURL','');
                }

                component.set('v.ContactId',resultEvent.Member_Contact__c);
                console.log('----------resultEvent.Member_Contact__c ' + resultEvent.Member_Contact__c);
                $A.util.toggleClass(cmpTarget, 'compass-topnav-login-dropdown-inactive');
                $A.util.toggleClass(cmpTarget2, 'compass-topnav-login-dropdown-inactive');
                $A.util.toggleClass(cmpTarget4, 'compass-topnav-login-dropdown-inactive');
                $A.util.toggleClass(cmpTarget5, 'compass-topnav-login-dropdown-inactive');
                $A.util.toggleClass(cmpTarget6, 'compass-topnav-login-dropdown-inactive');

                //$A.util.toggleClass(cmpTarget3, 'compass-topnav-login-dropdown-inactive');
                //$A.util.toggleClass(cmpTarget7, 'compass-topnav-login-dropdown-inactive');
            }else{
                console.log('----no user found');
            }
        });

        $A.enqueueAction(action);
    },

    // Start of addition by JaysonLabnao CCN-App Exchange-2311-QA-TE-SMOKE-22 Nov302022
    cleanUpNamespace : function(jsonData){
        let responseStr = JSON.stringify(jsonData);
        
        if(responseStr.includes('beta_ccn__')){
            responseStr = responseStr.replaceAll('beta_ccn__', '');
        }
        if(responseStr.includes('compass_cn__') ){
            responseStr = responseStr.replaceAll('compass_cn__', '');
        }
        
        return JSON.parse(responseStr);
    }
    // End of addition by JaysonLabnao CCN-App Exchange-2311-QA-TE-SMOKE-22 Nov302022
    
})