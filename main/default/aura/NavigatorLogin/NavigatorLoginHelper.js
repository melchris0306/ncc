({
	initializeLoginPage : function(component, event, helper){
        
        // START - Jonah - CCN-NAV-3417-DV - Oct 3, 2023
        	//let url = $A.get('$Resource.NavigatorLoginLogo');
        	//component.set('v.backgroundImageURL', url);
        // END - Jonah - CCN-NAV-3417-DV - Oct 3, 2023

        let url_strings = document.location.href.split('?');
        const urlParams = new URLSearchParams(url_strings[1]);
        const navigatorId = urlParams.get('id');
        component.set('v.navigatorId', navigatorId); //Jonah Baldero -  CCN-NAV-3417-DV - Nov 16, 2023
        helper.getNavigatorDetails(component, navigatorId);
    },
    
    setSubmitButtonIsDisabled: function(component, event, helper) {
        const emailRegex = /.+@.+(\.[a-zA-Z]{1,})+/;
        const inputBox = event.currentTarget;

        
        //Get email fied Value
        let emailValue = component.find("email").get("v.value")
        console.log('emailValue: ', emailValue);
        //Check if email is valid
        if (emailRegex.test(emailValue)) {
           //If email is valid set disable to false
           component.set('v.isSubmitDisabled', false);
           inputBox.reportValidity(); 
        }
    },


    /* START - Jonah Baldero -  CCN-NAV-3417-DV - Sept 18, 2023 - removed since no longer needed
        doSendToken : function(component, event, helper) {
            let action = component.get("c.sendTokenCode");
            
            action.setParams({ 
                email : component.find("email").get("v.value")
            });
            action.setCallback(this, function(response){
                let state = response.getState();
                if (state === "SUCCESS") {
                      let  message = 'Token sent. Please check your email';
                    this.showToast('Success!', message, "success", "pester");
                }
                else{
                    helper.showToastError(helper.logError(response.getError()));
                }
            });
            $A.enqueueAction(action);
        },
    END - Jonah Baldero -  CCN-NAV-3417-DV */

    doSubmit: function(component, event, helper) {
		let action = component.get("c.doLogin");
        let email = component.find("email").get("v.value");
        let isLoginTokenEnabled = component.get('v.isLoginTokenEnabled');
        //let token = null; Jonah Baldero -  CCN-NAV-3417-DV - Nov 16, 2023
        let navigatorId = component.get('v.navigatorId');
        /* START - Jonah Baldero -  CCN-NAV-3417-DV - Sept 18, 2023
         * removed since no longer needed
            if(isLoginTokenEnabled){
                token = component.find("token").get("v.value");
                Cookies.set('token', token);
            }
        END - Jonah Baldero -  CCN-NAV-3417-DV */
        
        action.setParams({ email, navigatorId });
        action.setCallback(this, function(response){
            let state = response.getState();

            if (state === "SUCCESS") {
                let resultMap = JSON.parse(response.getReturnValue());
                let baseUrl = resultMap.baseUrl;
                let navigatorId = resultMap.navigatorId;
                let contactId = resultMap.contact.contactId;
                          console.log('resultMap: '+resultMap.navigatorId);
                let redirectUrl = baseUrl+'?id='+navigatorId+'&contactId='+contactId;
                location.replace(redirectUrl);

            }
            else if (state === "ERROR") {
                let errors = response.getError();
                let message = 'Error on Logging in'; // Default error message
                // Retrieve the error message sent by the server
                if (errors && Array.isArray(errors) && errors.length > 0) {
                   message = errors[0].message;
                }
                this.showToast('', message, "error", "pester");
                // remove token if there's an error logging in
                Cookies.remove('token');
            }
        });
        $A.enqueueAction(action);
    },

    getNavigatorDetails : function(component, navigatorId){
        const action = component.get('c.getLoginPageInfo');
        action.setParams({ navigatorId });
        action.setCallback(this, function(response){
            let state = response.getState();
                          
            
            if(state === 'SUCCESS'){
                let navigatorRecord = response.getReturnValue();
	        // START - Jonah - CCN-NAV-3417-DV - Oct 3, 2023
                //if(navigatorRecord) component.set('v.isLoginTokenEnabled', navigatorRecord.enableTokenLogin); CCN-NAV-3417-DV - Jonah Belle Baldero - Oct 3, 2023
                
                if (navigatorRecord) {
                //Login Form Logo
                component.set('v.loginFormLogo', navigatorRecord.brandingLogo);
                
                //Header Logo
                component.set('v.headerLogo', navigatorRecord.appLogo);
                          
                //Navigator Login Background
                component.set('v.backgroundImageURL', navigatorRecord.landingPageHeroImageLinkField);
             // END - Jonah - CCN-NAV-3417-DV - Oct 3, 2023
                         }
            }
            else{
                helper.showToastError(helper.logError(response.getError()));
            }
                          
                          
           if(state != 'SUCCESS'){
           	helper.showToastError(helper.logError(response.getError()));
           }
        });

        $A.enqueueAction(action);
    },
    
    showToast : function(title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type" : type,
            "mode" : mode
        });
        toastEvent.fire();
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