({          
    getCampaigns : function(component, recordId){
        
        //Check RecordId Type
        var objectType;
        var objectTypeAction = component.get("c.objectType");
        objectTypeAction.setParams({
            "recordIdVal": recordId
        });
        objectTypeAction.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                objectType = rows;
            }
            var expandedRows = [];
            var base_url = window.location.origin;
            
            //Campaign Record Map
            var camps = [];
            var campMap = new Map();
            
            if(objectType === 'Campaign__c'){
                //Get Campaign
                var campaignAction = component.get("c.searchForCampaign");
                campaignAction.setParams({
                    "recordIdVal": recordId
                });
                campaignAction.setCallback(this, function(response){
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var rows = response.getReturnValue();
                        for (var i = 0; i < rows.length; i++) {	
                            rows[i].CampaignName = base_url+'/'+rows[i].Id;
                            rows[i].RecordType = 'Campaign';
                            campMap.set(rows[i].Id, rows[i]);
                            expandedRows.push(rows[i].Name);
                        }
                        
                        //Event Record Map
                        var events = new Map();
                        var eventMap = new Map();
                        var eventList = [];
                        
                        //Get Event
                        var eventAction = component.get("c.searchForEvent");
                        eventAction.setParams({
                            "recordIdVal": recordId
                        });
                        eventAction.setCallback(this, function(response){
                            var state = response.getState();
                            if (state === "SUCCESS") {
                                var rows = response.getReturnValue();
                                for (var i = 0; i < rows.length; i++) {		
                                    if(rows[i].Campaign__c != null){ 
                                        if(campMap.has(rows[i].Campaign__c)){
                                            rows[i].CampaignName = base_url + '/' + rows[i].Id;
                                            rows[i].RecordType = 'Event';

                                            if(!events.has(rows[i].Campaign__c)){
                                                events.set(rows[i].Campaign__c, campMap.get(rows[i].Campaign__c));
                                                events.get(rows[i].Campaign__c)._children = [];
                                                events.get(rows[i].Campaign__c)._children.push(rows[i]);		
                                            }
                                            else{  
                                                events.get(rows[i].Campaign__c)._children.push(rows[i]);                                        
                                            }
                                            
                                            //Set Event Id and Record
                                            eventMap.set(rows[i].Id, rows[i]);	
                                            eventList.push(rows[i].Id);
                                        }
                                    }
                                }
                                
                                //Session Record Map
                                var sessions = new Map();
                                
                                //Get Session
                                var sessionAction = component.get("c.searchForSession");
                                sessionAction.setParams({
                                    "eventList": eventList,
                                    "recordIdVal": null
                                });
                                sessionAction.setCallback(this, function(response){
                                    var state = response.getState();
                                    if (state === "SUCCESS") {
                                        var rows = response.getReturnValue();
                                        for (var i = 0; i < rows.length; i++) {	
                                            if(rows[i].Event__c != null){ 
                                                if(eventMap.has(rows[i].Event__c)){
                                                    rows[i].CampaignName = base_url + '/' + rows[i].Id;
                                                    rows[i].RecordType = 'Session';
                                                    if(!sessions.has(rows[i].Event__c)){
                                                        sessions.set(rows[i].Event__c, eventMap.get(rows[i].Event__c));
                                                        sessions.get(rows[i].Event__c)._children = [];
                                                        sessions.get(rows[i].Event__c)._children.push(rows[i]);		
                                                    }
                                                    else{  
                                                        sessions.get(rows[i].Event__c)._children.push(rows[i]);                                        
                                                    }
                                                }
                                            }
                                        }
                                        
                                        //Setting Structure
                                        var eventMapEntries = events.entries();
                                        for (var [key, value] of eventMapEntries) {
                                            camps.push(value);
                                        }
                                        component.set('v.gridData', camps);
                                        component.set('v.gridExpandedRows', expandedRows);
                                    }
                                });//sessionAction
                                $A.enqueueAction(sessionAction);
                            }
                        });//eventAction
                        $A.enqueueAction(eventAction);
                    }
                });//campaignAction
                $A.enqueueAction(campaignAction);
            }//End of ObjectType Campaign
            
            else if(objectType == 'Event__c'){
                
                //Campaign Record Map
                var camps = [];
                var campMap = new Map();
                
                //Get Current Event
                var currentEventCampaign = '';
                var currentEventAction = component.get("c.searchForEvent");
                currentEventAction.setParams({
                    "recordIdVal": recordId
                });
                currentEventAction.setCallback(this, function(response){
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var rows = response.getReturnValue();
                        for (var i = 0; i < rows.length; i++) {
                            if(rows[i].Campaign__c != null){
                                currentEventCampaign = rows[i].Campaign__c;
                            }
                        }
                        
                        var hasCampaign = (currentEventCampaign != '');

                        if(hasCampaign){
                            //Get Campaign
                            var campaignAction = component.get("c.searchForCampaign");
                            campaignAction.setParams({
                                "recordIdVal": currentEventCampaign
                            });
                            campaignAction.setCallback(this, function(response){
                                var state = response.getState();
                                if (state === "SUCCESS") {
                                    var rows = response.getReturnValue();
                                    
                                    for (var i = 0; i < rows.length; i++) {		
                                        rows[i].CampaignName = base_url + '/' + rows[i].Id;
                                        rows[i].RecordType = 'Campaign';
                                        campMap.set(rows[i].Id, rows[i]);
                                        expandedRows.push(rows[i].Name);
                                    }
                                    
                                    //Event Record Map
                                    var events = new Map();
                                    var eventMap = new Map();
                                    var eventList = [];
                                    
                                    //Get Event
                                    var eventAction = component.get("c.searchForEvent");
                                    eventAction.setParams({
                                        "recordIdVal": recordId
                                    });
                                    eventAction.setCallback(this, function(response){
                                        var state = response.getState();
                                        if (state === "SUCCESS") {
                                            var rows = response.getReturnValue();
                                            for (var i = 0; i < rows.length; i++) {		
                                                if(rows[i].Campaign__c != null){ 
                                                    if(campMap.has(rows[i].Campaign__c)){
                                                        rows[i].CampaignName = base_url + '/' + rows[i].Id;
                                                        rows[i].RecordType = 'Event';
                                                        if(!events.has(rows[i].Campaign__c)){
                                                            events.set(rows[i].Campaign__c, campMap.get(rows[i].Campaign__c));
                                                            events.get(rows[i].Campaign__c)._children = [];
                                                            events.get(rows[i].Campaign__c)._children.push(rows[i]);	
                                                            expandedRows.push(rows[i].Name);		
                                                        }
                                                        else{  
                                                            events.get(rows[i].Campaign__c)._children.push(rows[i]);                                        
                                                        }
                                                        //Set Event Id and Record
                                                        eventMap.set(rows[i].Id, rows[i]);	
                                                        eventList.push(rows[i].Id);
                                                    }
                                                }
                                            }
                                            
                                            //Session Record Map
                                            var sessions = new Map();
                                            
                                            //Get Session
                                            var sessionAction = component.get("c.searchForSession");
                                            sessionAction.setParams({
                                                "eventList": eventList,
                                                "recordIdVal": null
                                            });
                                            sessionAction.setCallback(this, function(response){
                                                var state = response.getState();
                                                if (state === "SUCCESS") {
                                                    var rows = response.getReturnValue();
                                                    for (var i = 0; i < rows.length; i++) {	
                                                        rows[i].CampaignName = base_url+'/'+rows[i].Id;
                                                        rows[i].RecordType = 'Session';
                                                        if(rows[i].Event__c != null){ 
                                                            if(eventMap.has(rows[i].Event__c)){
                                                                if(!sessions.has(rows[i].Event__c)){
                                                                    sessions.set(rows[i].Event__c, eventMap.get(rows[i].Event__c));
                                                                    sessions.get(rows[i].Event__c)._children = [];
                                                                    sessions.get(rows[i].Event__c)._children.push(rows[i]);	
                                                                }
                                                                else{  
                                                                    sessions.get(rows[i].Event__c)._children.push(rows[i]);                                        
                                                                }
                                                            }
                                                        }
                                                    }
                                                    //Setting Structure
                                                    var eventMapEntries = events.entries();
                                                    for (var [key, value] of eventMapEntries) {
                                                        camps.push(value);
                                                    }
                                                    component.set('v.gridData', camps);
                                                    component.set('v.gridExpandedRows', expandedRows);
                                                }
                                            });//sessionAction
                                            $A.enqueueAction(sessionAction);
                                        }
                                    });//eventAction
                                    $A.enqueueAction(eventAction);
                                }
                            });//campaignAction
                            $A.enqueueAction(campaignAction);
                        }//has campaign
                        
                        else{		
                            //Event Record Map
                            var events = [];
                            var eventMap = new Map();
                            var eventList = [];
                            
                            //Get Event
                            var eventAction = component.get("c.searchForEvent");
                            eventAction.setParams({
                                "recordIdVal": recordId
                            });
                            eventAction.setCallback(this, function(response){
                                var state = response.getState();

                                if (state === "SUCCESS") {
                                    var rows = response.getReturnValue();
                                    for (var i = 0; i < rows.length; i++) {	
                                        rows[i].CampaignName = base_url + '/' + rows[i].Id;	
                                        rows[i].RecordType = 'Event';
                                        eventMap.set(rows[i].Id, rows[i]);
                                        eventList.push(rows[i].Id);
                                        expandedRows.push(rows[i].Name);
                                    }
                                    
                                    //Session Record Map
                                    var sessions = new Map();
                                    
                                    //Get Session
                                    var sessionAction = component.get("c.searchForSession");
                                    sessionAction.setParams({
                                        "eventList": eventList,
                                        "recordIdVal": null
                                    });
                                    sessionAction.setCallback(this, function(response){
                                        var state = response.getState();
                                        if (state === "SUCCESS") {
                                            var rows = response.getReturnValue();

                                            for (var i = 0; i < rows.length; i++) {	
                                                if(rows[i].Event__c != null){ 
                                                    if(eventMap.has(rows[i].Event__c)){
                                                        rows[i].CampaignName = base_url + '/' + rows[i].Id;
                                                        rows[i].RecordType = 'Session';
                                                        if(!sessions.has(rows[i].Event__c)){
                                                            sessions.set(rows[i].Event__c, eventMap.get(rows[i].Event__c));
                                                            sessions.get(rows[i].Event__c)._children = [];
                                                            sessions.get(rows[i].Event__c)._children.push(rows[i]);		
                                                        }
                                                        else{  
                                                            sessions.get(rows[i].Event__c)._children.push(rows[i]);                                        
                                                        }
                                                    }
                                                }
                                            }
                                            //Setting Structure
                                            var eventMapEntries = sessions.entries();
                                            for (var [key, value] of eventMapEntries) {
                                                events.push(value);
                                            }
                                            component.set('v.gridData', events);
                                            component.set('v.gridExpandedRows', expandedRows);
                                        }
                                    });//sessionAction
                                    $A.enqueueAction(sessionAction);
                                }
                            });//eventAction
                            $A.enqueueAction(eventAction);
                        }//no campaign
                    }
                });//currentEventAction
                $A.enqueueAction(currentEventAction);
            }
            
            else if(objectType == 'Session__c'){
                
                //Campaign Record Map
                var camps = [];
                var campMap = new Map();
                
                //Get Current Session
                var currentSessionEvent = '';
                var currentSessionAction = component.get("c.searchForSession");
                currentSessionAction.setParams({
                    "recordIdVal": recordId
                });
                currentSessionAction.setCallback(this, function(response){
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var rows = response.getReturnValue();
                        for (var i = 0; i < rows.length; i++) {
                            if(rows[i].Event__c != null){
                                currentSessionEvent = rows[i].Event__c;
                            }
                        }
                        
                        //Get Current Event
                        var currentEventCampaign = '';
                        var currentEventAction = component.get("c.searchForEvent");
                        currentEventAction.setParams({
                            "recordIdVal": currentSessionEvent
                        });
                        currentEventAction.setCallback(this, function(response){
                            var state = response.getState();
                            if (state === "SUCCESS") {
                                var rows = response.getReturnValue();
                                for (var i = 0; i < rows.length; i++) {
                                    if(rows[i].Campaign__c != null){
                                        currentEventCampaign = rows[i].Campaign__c;
                                    }
                                }
                                
                                var hasCampaign = (currentEventCampaign != '' ?  true : false);
                                if(hasCampaign){
                                    //Get Campaign
                                    var campaignAction = component.get("c.searchForCampaign");
                                    campaignAction.setParams({
                                        "recordIdVal": currentEventCampaign
                                    });
                                    campaignAction.setCallback(this, function(response){
                                        var state = response.getState();
                                        if (state === "SUCCESS") {
                                            var rows = response.getReturnValue();
                                            
                                            for (var i = 0; i < rows.length; i++) {		
                                                rows[i].CampaignName = base_url+'/'+rows[i].Id;
                                                rows[i].RecordType = 'Campaign';
                                                campMap.set(rows[i].Id, rows[i]);
                                                expandedRows.push(rows[i].Name);
                                            }
                                            
                                            //Event Record Map
                                            var events = new Map();
                                            var eventMap = new Map();
                                            var eventList = [];
                                            
                                            //Get Event
                                            var eventAction = component.get("c.searchForEvent");
                                            eventAction.setParams({
                                                "recordIdVal": currentSessionEvent
                                            });
                                            eventAction.setCallback(this, function(response){
                                                var state = response.getState();
                                                if (state === "SUCCESS") {
                                                    var rows = response.getReturnValue();
                                                    for (var i = 0; i < rows.length; i++) {		
                                                        if(rows[i].Campaign__c != null){ 
                                                            if(campMap.has(rows[i].Campaign__c)){
                                                                rows[i].CampaignName = base_url+'/'+rows[i].Id;
                                                                rows[i].RecordType = 'Event';
                                                                if(!events.has(rows[i].Campaign__c)){
                                                                    events.set(rows[i].Campaign__c, campMap.get(rows[i].Campaign__c));
                                                                    events.get(rows[i].Campaign__c)._children = [];
                                                                    events.get(rows[i].Campaign__c)._children.push(rows[i]);	
                                                                    expandedRows.push(rows[i].Name);		
                                                                }
                                                                else{  
                                                                    events.get(rows[i].Campaign__c)._children.push(rows[i]);                                        
                                                                }
                                                                //Set Event Id and Record
                                                                eventMap.set(rows[i].Id, rows[i]);	
                                                                eventList.push(rows[i].Id);
                                                            }
                                                        }
                                                    }
                                                    
                                                    //Session Record Map
                                                    var sessions = new Map();
                                                    
                                                    //Get Session
                                                    var sessionAction = component.get("c.searchForSession");
                                                    sessionAction.setParams({
                                                        "recordIdVal": recordId
                                                    });
                                                    sessionAction.setCallback(this, function(response){
                                                        var state = response.getState();
                                                        if (state === "SUCCESS") {
                                                            var rows = response.getReturnValue();
                                                            for (var i = 0; i < rows.length; i++) {	
                                                                rows[i].CampaignName = base_url+'/'+rows[i].Id;
                                                                rows[i].RecordType = 'Session';
                                                                if(rows[i].Event__c != null){ 
                                                                    if(eventMap.has(rows[i].Event__c)){
                                                                        if(!sessions.has(rows[i].Event__c)){
                                                                            sessions.set(rows[i].Event__c, eventMap.get(rows[i].Event__c));
                                                                            sessions.get(rows[i].Event__c)._children = [];
                                                                            sessions.get(rows[i].Event__c)._children.push(rows[i]);	
                                                                        }
                                                                        else{  
                                                                            sessions.get(rows[i].Event__c)._children.push(rows[i]);                                        
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            //Setting Structure
                                                            var eventMapEntries = events.entries();
                                                            for (var [key, value] of eventMapEntries) {
                                                                camps.push(value);
                                                            }
                                                            component.set('v.gridData', camps);
                                                            component.set('v.gridExpandedRows', expandedRows);
                                                        }
                                                    });//sessionAction
                                                    $A.enqueueAction(sessionAction);
                                                }
                                            });//eventAction
                                            $A.enqueueAction(eventAction);
                                        }
                                    });//campaignAction
                                    $A.enqueueAction(campaignAction);
                                }//has campaign
                                
                                else{		
                                    //Event Record Map
                                    var events = [];
                                    var eventMap = new Map();
                                    var eventList = [];
                                    
                                    //Get Event
                                    var eventAction = component.get("c.searchForEvent");
                                    eventAction.setParams({
                                        "recordIdVal": currentSessionEvent
                                    });
                                    eventAction.setCallback(this, function(response){
                                        var state = response.getState();

                                        if (state === "SUCCESS") {
                                            var rows = response.getReturnValue();
                                            for (var i = 0; i < rows.length; i++) {	
                                                rows[i].CampaignName = base_url+'/'+rows[i].Id;	
                                                rows[i].RecordType = 'Event';
                                                eventMap.set(rows[i].Id, rows[i]);
                                                eventList.push(rows[i].Id);
                                                expandedRows.push(rows[i].Name);
                                            }
                                            
                                            //Session Record Map
                                            var sessions = new Map();
                                            
                                            //Get Session
                                            var sessionAction = component.get("c.searchForSession");
                                            sessionAction.setParams({
                                                "recordIdVal": null
                                            });
                                            sessionAction.setCallback(this, function(response){
                                                var state = response.getState();
                                                if (state === "SUCCESS") {
                                                    var rows = response.getReturnValue();

                                                    for (var i = 0; i < rows.length; i++) {	
                                                        if(rows[i].Event__c != null){ 
                                                            if(eventMap.has(rows[i].Event__c)){
                                                                rows[i].CampaignName = base_url+'/'+rows[i].Id;
                                                                rows[i].RecordType = 'Session';
                                                                if(!sessions.has(rows[i].Event__c)){
                                                                    sessions.set(rows[i].Event__c, eventMap.get(rows[i].Event__c));
                                                                    sessions.get(rows[i].Event__c)._children = [];
                                                                    sessions.get(rows[i].Event__c)._children.push(rows[i]);		
                                                                }
                                                                else{  
                                                                    sessions.get(rows[i].Event__c)._children.push(rows[i]);                                        
                                                                }
                                                            }
                                                        }
                                                    }
                                                    //Setting Structure
                                                    var eventMapEntries = sessions.entries();
                                                    for (var [key, value] of eventMapEntries) {
                                                        events.push(value);
                                                    }
                                                    component.set('v.gridData', events);
                                                    component.set('v.gridExpandedRows', expandedRows);
                                                }
                                            });//sessionAction
                                            $A.enqueueAction(sessionAction);
                                        }
                                    });//eventAction
                                    $A.enqueueAction(eventAction);
                                }//no campaign
                            }
                        });//currentEventAction
                        $A.enqueueAction(currentEventAction);
                    }
                });//currentSessionAction
                $A.enqueueAction(currentSessionAction);
            }            
        });//objectTypeAction
        $A.enqueueAction(objectTypeAction);
    }
})