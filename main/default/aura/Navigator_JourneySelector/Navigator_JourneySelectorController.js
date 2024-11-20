({
    doInit : function(component, event, helper) {

        let url = new URL(window.location.href);
        let sPageURL = decodeURIComponent(window.location.search.substring(1)); //You get the whole decoded URL of the page.
        let sURLVariables = sPageURL.split("&"); //Split by & so that you get the key value pairs separately in a list
        let sParameterName;
        let i;
		
        // START: CCN-NAV-427-DV
        let basecampId;
        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split("="); //to split the key from the value.

            if (sParameterName[0] === "contactId") {
                component.set("v.contactId", sParameterName[1]);
            }
            
            if (sParameterName[0] === "id") {
               basecampId = sParameterName[1];
            }
        }
        let contact_Id = component.get("v.contactId");
        console.log("!@# contact_Id: " + contact_Id);
        
        helper.retrieveContactsJourney(component, contact_Id, basecampId);
        // END: CCN-NAV-427-DV
    }
})