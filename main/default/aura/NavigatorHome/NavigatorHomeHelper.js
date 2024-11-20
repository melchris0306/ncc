({
    initNavigatorAttributes : function(component, event, helper){
        const contact =  event.getParam('contact');
        const navRecord = event.getParam('navigatorRecord');
        console.log('@@@@@@ CONTACT @@@@');
        
        try {
          console.log(contact);
          console.log(navRecord);
          console.log(navRecord.id);
          component.set("v.contactRecord", contact);
          console.log(component.get("v.contactRecord"));
          component.set('v.navigatorRecord', navRecord);
          component.set('v.greeting', navRecord.headerText.replace('{name}', '<b>' + contact.name + '</b>'));
          console.log('navRecord : ', navRecord);
          console.log('contact: ', contact);
        } catch (err) {
          console.error(err);
        }
        
        
        // the function that reads the url parameters
        var getUrlParameter = function getUrlParameter(sParam) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;
            
            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        
        //set the token param value to my token attribute
        component.set("v.token", getUrlParameter('token'));
        
        helper.getNavigatorWidgets(component, navRecord, contact);
    },
    
    getNavigatorWidgets : function(component, navRecord, contact){
        console.log(navRecord.id);
        
        const action = component.get('c.getNavigatorWidgets');
        action.setParams({ navigatorId : navRecord.id, contactId : contact.Id});
        action.setCallback(this, function(response){
        	const navWidgetList = JSON.parse(response.getReturnValue())
            const componentByStyleClass = {
                "box1":"activityCalendarType",
                "box3":"boxType",
                "box4":"boxType",
                "box5":"boxType",
                "box7":"boxType"
            }
            const sizeToStyleClass = {
                "Classic Top Center S1":"box1", 
                "Classic Upper Middle Left S2":"box3", 
                "Classic Upper Middle Right S2":"box4",
                "Classic Lower Middle Left S2":"box5",
                "Classic Bottom Left S2":"box7"
            }
            navWidgetList.forEach(function(item){
                // TO-DO: Needs to be updated once the Widget Size values are confirmed
                // 
                item.componentClass = sizeToStyleClass[item.Widget_Size__c];
                
                if(componentByStyleClass[item.componentClass]){
                    item.componentType = componentByStyleClass[item.componentClass];
                }
            });
            
            component.set('v.navigatorWidgetsList', navWidgetList);
            console.log('navWidgetList : ', navWidgetList);
        });
        $A.enqueueAction(action);
    }
})