public class calendarController {
    private static WithoutSharingClass withoutShare = new WithoutSharingClass(); 
    
    //Start Added [CCN-EVE-2173-DV] Method to Get Event Types MelMallorca Nov262022
    @AuraEnabled
    public static List<String> getEventTypes(){
        List<String> typeList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Event__c.Event_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            typeList.add(pickListVal.getLabel());
        }
        return typeList;
    }
    //End Added [CCN-EVE-2173-DV] MelMallorca Nov262022
    @AuraEnabled
    public static Campaign__c getCampaign(String campaignId){
        return withoutShare.getCampaignDetails(campaignId);
    }
    
    @AuraEnabled
    public static String getRecId(String eventId){
        Event__c evt = [Select Id, Event_Id__c FROM Event__c WHERE Event_Id__c =:eventId];
        String recordId = evt.Id;
        return recordId;
    }
    //CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
    //CCN-EVE-2108-DV Modified by Mel Mallorca Oct 3, 2022
    //CCN-EVE-2173-DV Modified MelMallorca Nov262022
    @AuraEnabled
    public static List<EventObj> getEventsExceptShowToLinks(String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField, Boolean filterByUserField, String eventId, List<String> eventType, List<String> eventName){
        System.debug('------------ ola dora 2');
        //Start CCN-EVE-2173-DV Added EventType and EventName filter MelMallorca Nov292022
        List<Event__c> sObjectList;
        if(!eventType.isEmpty() && !eventName.isEmpty()){
            sObjectList = [SELECT Id, Status__c,Location__c,Time_Zone__c,Event_Details__c, Name, Start_Date_Time__c,End_Date_Time__c,Description__c,CreatedById, Event_Type__c 
                           FROM  Event__c
                           WHERE Campaign__c =: eventId
                           AND Event_Type__c IN: eventType
                           AND Name IN: eventName
                           AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
        }
        else if( !eventType.isEmpty()){
            sObjectList = [SELECT Id, Status__c,Location__c,Time_Zone__c,Event_Details__c, Name, Start_Date_Time__c,End_Date_Time__c,Description__c,CreatedById, Event_Type__c 
                           FROM  Event__c
                           WHERE Campaign__c =: eventId
                           AND Event_Type__c IN: eventType
                           AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
        }
        else if( !eventName.isEmpty()){
            sObjectList = [SELECT Id, Status__c,Location__c,Time_Zone__c,Event_Details__c, Name, Start_Date_Time__c,End_Date_Time__c,Description__c,CreatedById, Event_Type__c 
                           FROM  Event__c
                           WHERE Campaign__c =: eventId
                           AND Name IN: eventName
                           AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
        }
        else{
            sObjectList = [SELECT Id, Status__c,Location__c,Time_Zone__c,Event_Details__c, Name, Start_Date_Time__c,End_Date_Time__c,Description__c,CreatedById, Event_Type__c 
                           FROM  Event__c
                           WHERE Campaign__c =: eventId
                           AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC];
        }
        
        List<EventObj> eventRecords = new List<EventObj>();
        //End CCN-EVE-2173-DV MelMallorca Nov292022
        
        if(isAccessible(sObjectName)) {
            for (Event__c session : sObjectList) {
                String statusStr = '';
                String strStart = '';
                String strEnd = '';
                
                if(Session.Status__c != null){
                    statusStr = session.Status__c;
                }
                
                DateTime strtDteTime = DateTime.Now();
                DateTime strtDteTimeFormatted = DateTime.Now();
                DateTime endDteTime = DateTime.Now();    
                DateTime endDteTimeFormatted = DateTime.Now();       
                
                strtDteTime = session.Start_Date_Time__c;
                endDteTime = session.End_Date_Time__c;
                
                //Start CCN-EVE-2173-DV Added EventType and EventName param MelMallorca Nov262022
                EventObj newEv = new EventObj(String.valueOF(session.Id),
                                              Session.Name,
                                              strtDteTime,
                                              endDteTime,
                                              session.Event_Details__c,
                                              String.valueOf(session.CreatedById),
                                              statusStr,
                                              session.Location__c,
                                              session.Time_Zone__c,
                                              session.Name,
                                              session.Event_Type__c
                                             );
                //End CCN-EVE-2173-DV MelMallorca Nov262022
                eventRecords.add(newEv);
            }
        }
        
        System.Debug('eventRecords: '+eventRecords);
        return eventRecords;
    }
    //CCN-1000 Modified by Rianno Rizarri Apr 15, 2022
    //CCN-EVE-2173-DV Modified MelMallorca Nov262022
    //Start CCN-EVE-2173-DV Added EventType and EventName param MelMallorca Nov292022
    @AuraEnabled
    public static List<EventObj> getEvents(String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField, Boolean filterByUserField, String eventId, List<String> eventType){
        System.debug('------------ ola dora 2');
        String q = 'SELECT Id, Status__c,Location__c,Event_Type__c,Time_Zone__c,Event_Details__c, Name, Start_Date_Time__c,End_Date_Time__c,Description__c,CreatedById ' + 
            ' FROM  Event__c WHERE ' + 
            'Campaign__c' + ' = \'' +String.valueOf(eventId)+ '\'' +
            ' AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, End_Date_Time__c ASC, Name ASC';
        //End CCN-EVE-2173-DV MelMallorca Nov292022
        System.debug('------------ ola dora 2' + q);
        List<Event__c> sObjectList = Database.query(q);
        List<EventObj> eventRecords = new List<EventObj>();
        
        if(isAccessible(sObjectName)) {
            for (Event__c session : sObjectList) {
                String statusStr = '';
                String strStart = '';
                String strEnd = '';
                
                if(Session.Status__c != null){
                    statusStr = session.Status__c;
                }
                
                DateTime strtDteTime = DateTime.Now();
                DateTime strtDteTimeFormatted = DateTime.Now();
                DateTime endDteTime = DateTime.Now();    
                DateTime endDteTimeFormatted = DateTime.Now();       
                
                strtDteTime = session.Start_Date_Time__c;
                endDteTime = session.End_Date_Time__c;
                
                //Start CCN-EVE-2173-DV Added EventType and EventName param MelMallorca Nov292022
                EventObj newEv = new EventObj(String.valueOF(session.Id),
                                              Session.Name,
                                              strtDteTime,
                                              endDteTime,
                                              session.Event_Details__c,
                                              String.valueOf(session.CreatedById),
                                              statusStr,
                                              session.Location__c,
                                              session.Time_Zone__c,
                                              session.Name,
                                              session.Event_Type__c
                                             );
                //End CCN-EVE-2173-DV MelMallorca Nov292022
                eventRecords.add(newEv);
            }
        }
        
        System.Debug('eventRecords: '+eventRecords);
        return eventRecords;
    }
    
    @AuraEnabled
    public static Session__c insertSession(String sEventObj, String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField, String eventRecId){
        EventObj insertingEvent = (EventObj)JSON.deserialize(sEventObj, EventObj.class);
        Session__c sessionToInsert = new Session__c();
        System.Debug('upsertingEvent: '+insertingEvent);
        
        sessionToInsert.Propose_Start_Date_Time__c = DateTime.valueOf(insertingEvent.startDateTime);
        sessionToInsert.Start_Date_Time__c = DateTime.valueOf(insertingEvent.startDateTime);
        
        sessionToInsert.Propose_End_Date_Time__c = DateTime.valueOf(insertingEvent.endDateTime);
        sessionToInsert.End_Date_Time__c = DateTime.valueOf(insertingEvent.endDateTime);
        
        sessionToInsert.Status__c = 'Proposed';
        
        sessionToInsert.Session_Details__c = insertingEvent.description;
        
        sessionToInsert.IsActive__c = true;
        
        sessionToInsert.Name = insertingEvent.title;
        
        sessionToInsert.Event__c = eventRecId;
        
        sessionToInsert.Location__c = insertingEvent.location;
        
        try{
            insert sessionToInsert;
        }catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }
        
        return sessionToInsert;
    }
    
    
    @AuraEnabled
    public static EventObj upsertEvents(String sEventObj, String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField){
        EventObj upsertingEvent = (EventObj)JSON.deserialize(sEventObj, EventObj.class);
        sObject newRecord = Schema.getGlobalDescribe().get(sObjectName).newSObject(); 
        if (upsertingEvent.Id != null && isAccessible(sObjectName,'Id')){
            newRecord.put('Id',upsertingEvent.Id);
        } 
        if (isAccessible(sObjectName,startDateTimeField)) {
            newRecord.put(startDateTimeField, upsertingEvent.startDateTime);
        }
        if (isAccessible(sObjectName,endDateTimeField)) {
            newRecord.put(endDateTimeField, upsertingEvent.endDateTime);
        }
        if (isAccessible(sObjectName,'Status__c')){
            newRecord.put('Status__c', 'Proposed');
        }
        if (isAccessible(sObjectName,'Location__c')){
            newRecord.put('Location__c', upsertingEvent.location);
        }
        //Start CCN-EVE-2173-DV Added EventType MelMallorca Nov292022
        //Added filter to check if Object is not Session as the field is not present in that Object - Gab - Dec192022
        if (sObjectName != 'Session__c'){
            if (isAccessible(sObjectName,'Event_Type__c')){
                newRecord.put('Event_Type__c', upsertingEvent.eventType);
            } 
        }
        
        //End CCN-EVE-2173-DV MelMallorca Nov292022
        
        try {
            upsert newRecord;
            //Start CCN-EVE-2173-DV Added EventType MelMallorca Nov292022
            EventObj newEv = new EventObj(newRecord.Id,
                                          String.valueOf(newRecord.get(titleField)),
                                          DateTime.valueOf(newRecord.get(startDateTimeField)),
                                          DateTime.valueOf(newRecord.get(endDateTimeField)),
                                          String.valueOf(newRecord.get(descriptionField)),
                                          String.valueOf(newRecord.get(userField)),
                                          String.valueOf(newRecord.get('Status__c')),
                                          String.valueOf(newRecord.get('Location__c')),
                                          null,null,
                                          String.valueOf(newRecord.get('Event_Type__c'))
                                         );
            //End CCN-EVE-2173-DV MelMallorca Nov292022
            return newEv;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }
        
    }
    @AuraEnabled
    public static String deleteEvent(String eventId, String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField){
        String q = 'SELECT Id,' + 
            titleField + ',' + 
            startDateTimeField + ',' +
            endDateTimeField + ',' +
            descriptionField + ',' +
            userField + ' FROM ' + 
            sObjectName + ' WHERE Event__c = \'' + eventId  + '\'';
        List<sObject> sObjectList = Database.query(q);
        try {
            if(isDeletable(sObjectName)) {
                delete sObjectList;
            }
            return eventId;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return null;
        }
        
    }
    public class EventObj {
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public DateTime startDateTime {get;set;}
        @AuraEnabled
        public DateTime endDateTime {get;set;}
        @AuraEnabled
        public String description {get;set;}
        @AuraEnabled
        public String owner {get;set;}
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public String location {get;set;}
        @AuraEnabled
        public String timezone {get;set;}
        @AuraEnabled
        public String eventName {get;set;}
        //Start CCN-EVE-2173-DV Added EventType MelMallorca Nov292022
        @AuraEnabled
        public String eventType {get;set;}
        //End CCN-EVE-2173-DV MelMallorca Nov292022
        
        
        //Start CCN-EVE-2173-DV Added EventType MelMallorca Nov292022
        public EventObj(String i,String t, DateTime s, DateTime e, String d, String o, String st, String l, String tz, String en, String et){
            this.Id = i;
            this.title = t;
            this.startDateTime = s;
            this.endDateTime = e;
            this.description = d;
            this.owner = o;
            this.status = st;
            this.location = l;
            this.timezone = tz;
            this.eventName = en;
            this.eventType = et;
            
        }
        //End CCN-EVE-2173-DV MelMallorca Nov292022
        
    }
    
    
    // Updated [Namespace Issue Fixes] JaysonLabnao Aug152022
    public static Boolean isAccessible(String sObjectNameStr, String fieldNameStr){
        String sObjectName = FlsUtils.applyPrefixToObject(sObjectNameStr);
        String fieldName = FlsUtils.applyPrefixToObject(fieldNameStr);
        
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String, SObjectField> fields = schemaType.getDescribe().fields.getMap();
        DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
        return fieldDescribe.isAccessible();
    }
    // Updated [Namespace Issue Fixes] JaysonLabnao Aug152022
    public static Boolean isAccessible(String sObjectNameStr){
        String sObjectName = FlsUtils.applyPrefixToObject(sObjectNameStr);
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectName);
        return schemaType.getDescribe().isAccessible();
    }
    // Updated [Namespace Issue Fixes] JaysonLabnao Aug152022
    public static Boolean isCreateable(String sObjectNameStr){
        String sObjectName = FlsUtils.applyPrefixToObject(sObjectNameStr);
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectName);
        return schemaType.getDescribe().isCreateable();
    }
    // Updated [Namespace Issue Fixes] JaysonLabnao Aug152022
    public static Boolean isDeletable(String sObjectNameStr){
        String sObjectName = FlsUtils.applyPrefixToObject(sObjectNameStr);
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectName);
        return schemaType.getDescribe().isDeletable();
    }
    
    //Needs inner class declared without sharing for guest users to retrieve relevant records
    private without sharing class WithoutSharingClass {
        public Campaign__c getCampaignDetails(String campaignId){
            return [Select Id, Name, Description__c FROM Campaign__c WHERE Id =:campaignId];
        }
    }
}