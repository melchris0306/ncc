({
	doInit : function(component, event, helper) {
		
        var street =  component.get("v.Street");
        var city =  component.get("v.City");
        var postcode =  component.get("v.PostCode");
        var state =  component.get("v.State");
        var country =  component.get("v.Country");
        
         component.set('v.mapMarkers', [
            {
                location: {
                    City: city,
                    Country: country,
                    PostalCode: postcode,
                    State: state,
                    Street: street
                },
            }
        ]);
        
	}
})