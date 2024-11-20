({
    doInit : function(component, event, helper) {
        document.title = 'Loading....';
        var url_string = document.location.href;
        var eventId = (url_string.split('id=')[1]).slice(0,11);
        component.set('v.eventId',eventId);
        var action = component.get("c.getEventDetails");
        action.setParams({ 
            eventId : eventId
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();
                
                /* Updated [CCN1074,CCN863,CCN862] JaysonLabnao Dec192021 */
                if(resultEvent.materialsPageTitle){
                    document.title = resultEvent.materialsPageTitle;
                    component.set('v.materialsPageTitle', resultEvent.materialsPageTitle);
                }else{
                    component.set('v.materialsPageTitle', 'MATERIALS');
                }
                component.set('v.backgroundImageURL', resultEvent.HeroUrl);
                component.set('v.title', resultEvent.title);
                component.set('v.subtitle', resultEvent.subtitle);
            }else if (state === "ERROR") {
                component.set('v.materialsPageTitle', 'MATERIALS');

                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log('--ERRORS--');
                        console.log(errors[0].message);
                    }
                }
            }
        });
        
        $A.enqueueAction(action);
        
    },
    onClick : function(component, event, helper) {
        console.log('------------  test');
        var navbar = component.find('myNavbar');
        $A.util.toggleClass(navbar, 'responsive');
    }
    
})