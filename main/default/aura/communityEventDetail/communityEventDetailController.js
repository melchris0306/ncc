({
    doInit : function(component, event, helper) {
        helper.isIE(component);
        
        component.set("v.detailPageTitle",$A.get("$Label.c.COMPASS_Event_CheckItOut"));

        var url_string = document.location.href;
        var eventId = (url_string.split('id=')[1]).slice(0,11);
        var action = component.get("c.getEventDetails");
        
        var orgTimezone = $A.get("$Locale.timezone");
        
        action.setParams({ 
            eventId : eventId
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                component.set('v.detailString', resultEvent.Description);
                component.set('v.StartDate', resultEvent.StartDate);
                component.set('v.EndDate', resultEvent.EndDate);
                component.set('v.StartTime', resultEvent.StartTime);
                component.set('v.EndTime', resultEvent.EndTime);
                component.set('v.Street', resultEvent.Street);
                component.set('v.City', resultEvent.City);  
                component.set('v.PostCode', resultEvent.PostalCode);
                component.set('v.State', resultEvent.State);
                component.set('v.Country', resultEvent.Country);
                component.set('v.ShowMap', true);
                component.set('v.OrgTimeZone', orgTimezone);
                component.set('v.StartDateTime', resultEvent.StartDateTime);
                component.set('v.EndDateTime', resultEvent.EndDateTime);
                component.set('v.LocationName', resultEvent.LocationName);
                
                var address = '';
                var street = '';
                var city = '';
                var postalcode = '';
                var state = '';
                var country = '';
                
                if(resultEvent.Street != '' && resultEvent.Street != null ){
                    address = address + resultEvent.Street + ', ';
                    street = resultEvent.Street;
                }
                /* Remove comma [CCN-2027] RexieDavid Aug112022  */
                if (resultEvent.City != '' && resultEvent.City != null) {
                    address = address + resultEvent.City + ', ';
                    city = resultEvent.City;
                }
                if(resultEvent.PostalCode != ''  && resultEvent.PostalCode != null){
                    address = address + resultEvent.PostalCode + ', ';
                    postalcode = resultEvent.PostalCode;
                }
                /* Remove comma [CCN-1231] RexieDavid Mar42022  */
                if(resultEvent.State != ''  && resultEvent.State != null){
                    address = address + resultEvent.State + ' ';
                    state = resultEvent.State + ' '; 
                }
                if(resultEvent.Country != ''  && resultEvent.Country != null){
                    address = address + resultEvent.Country;
                    country = resultEvent.Country;
                }
                
                if(address.trim().slice(-1) == ','){
                    address = address.trim().slice(0, -1); 
                }
                component.set('v.CompleteAddress', address);
                component.set('v.Street', street);
                component.set('v.City', city);  
                component.set('v.PostCode', postalcode);
                component.set('v.State', state);
                component.set('v.Country', country);
 
            }
        });
        
        $A.enqueueAction(action);
        
    }
})