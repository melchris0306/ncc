({
	handleSubmit : function(component, event, helper) {

		helper.showSpinner(component, event, helper);

		// Updated by JaysonLabnao [CCN-EVE-2160-DV] OCT092022
		let rank = component.find("rankPicklist");
		let fname = component.find("firstName");
		let lname = component.find("lastName");
		let email = component.find("email");
		let sessionRolePicklist = component.find("sessionRolePicklist");
        console.log(component.find("site"));
        let site = component.find("site"); //CCN-EVE-3303-DV - Jonah Baldero - Sept 26, 2023
		var allValid = true;
        
        if (fname) {
            if(!fname.checkValidity()) {
                fname.showHelpMessageIfInvalid(); 
                allValid = false;
            }
        }
        
        if (lname) {
            if(!lname.checkValidity()) {
                lname.showHelpMessageIfInvalid(); 
                allValid = false;
            }
        }
        
        if (sessionRolePicklist) {
            if(!email.checkValidity()) {
                email.showHelpMessageIfInvalid();
                allValid = false;
            }
        }
        
        if (sessionRolePicklist) {
            if(!sessionRolePicklist.checkValidity()) {
                sessionRolePicklist.showHelpMessageIfInvalid();
                allValid = false;
            }
        }
        
        if (rank) {
            if(!rank.checkValidity()) {
                rank.showHelpMessageIfInvalid();
                allValid = false;
            }
        }
        
        //CCN-EVE-3303-DV - Jonah Baldero - Sept 26, 2023
        if (site) {
            if(!site.checkValidity()){
                site.showHelpMessageIfInvalid();
                allValid = false;
            }
        }


		// Updated by JaysonLabnao [CCN-EVE-2160-DV] OCT092022
		if(allValid){
			const url_string = decodeURIComponent(window.location.search);
			let sessionId;
			let eventId;
			let firstName = component.get("v.firstName");
			let lastName = component.get("v.lastName");
			let email = component.get("v.email");
			let role = component.get("v.role");
			let rank = component.get("v.rankHolder"); // Updated by JaysonLabnao [CCN-EVE-2160-DV] OCT092022
			let site = component.get("v.siteItem.inputValue"); //Added by Gabriel Delavin CCN-EVE-3426-DV
			//XEN REYES March 5, 2023 CCN-EVE-2631-DV
			let rankGroup = component.get("v.rankGroup");

			try {
				sessionId = (url_string.split('sessionid=')[1]).slice(0,15);
				eventId = (url_string.split('id=')[1]).split('&')[0];
			} catch(err) {
				console.error('ID Error');
			}
	
			const action = component.get("c.addSessionParticipants");
			action.setParams({ eventId, sessionId, firstName, lastName, role, email, rank, rankGroup, site}); 
			action.setCallback(this, function(response){
				var state = response.getState();
				if (state === "SUCCESS") {
					var resultEvent = response.getReturnValue();
					if(resultEvent === 'Success'){
						helper.showSuccess(component, event);
						//Updated by JaysonLabnao [CCN-EVE-2160-DV] OCT092022
						window.location.reload()
						//$A.get('e.force:refreshView').fire();
					}else {
						helper.showError(component, event);
					}
				} else {
					helper.showError(component, event);
				}

				helper.hideSpinner(component, event, helper);
			});
			$A.enqueueAction(action);
		} else {
            helper.showErrorBlank(component, event);
			helper.hideSpinner(component, event, helper);                  
        }
	},

	doInit : function(component, event, helper) {
        var url_string = document.location.href;
        var sessionId;
        try {
            sessionId = (url_string.split('sessionid=')[1]).slice(0,15);
        }
        catch(err) {
            console.error('ID Error');
        }

		// Start of update from JaysonLabnao [CCN-EVE-2160-DV] OCT092022
		component.set('v.spinner', true);
		helper.getRankOptions(component, event, helper);
		// End of update from JaysonLabnao [CCN-EVE-2160-DV] OCT092022

        //var sessionId = (url_string.split('sessionid=')[1]).slice(0,15);
        var action = component.get("c.getSessionRoles");
 
        action.setParams({ 
            sessionId : sessionId
        });
		action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
				// Updated [Namespace Issue Fixes] JaysonLabnao Aug102022
                var resultEvent = helper.cleanUpNamespace(response.getReturnValue());
				component.set('v.sessionRole', resultEvent);
             }
        });
        $A.enqueueAction(action);
        
        helper.doGetFieldConfig(component, event, helper);
	},

	handleRolePick : function(component, event, helper) {
		// no logic here
		
	},

	handleRankChange : function(component, event, helper) {
		let rank = component.get('v.rank');
		const rankArray = rank.split("|");
        // Start CCN-EVE-3303-DV 10/3/2023: Von Pernicia
        if (rankArray.length > 1) {
            component.set('v.rankHolder', rankArray[0]);
            component.set('v.rankGroup', rankArray[1]);
        } else {
            component.set('v.rankHolder', rankArray[0]);
            component.set('v.rankGroup', "Other");
        }
        // End CCN-EVE-3303-DV 10/3/2023: Von Pernicia
		
	}

})