public without sharing class AnyEventCalCtrl {
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  05-10-2022   RuthLugpatan         [CCN-2164] updated upsertEvents to fix the DST issue
    ******************************************************************************/
    
    @AuraEnabled
    public static String getRecId(String eventId){
    	Event__c evt = [Select Id, Event_Id__c FROM Event__c WHERE Event_Id__c =:eventId];
        String recordId = evt.Id;
        //added by DinoBrinas 12032021
        System.debug(' @@@@@ eventId >>> ' + eventId);
        System.debug(' @@@@@ evt >>> ' + evt);
        System.debug(' @@@@@ recordId >>> ' + recordId);

        return recordId;
    }

    @AuraEnabled
    public static List<EventObj> getEvents(String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField, Boolean filterByUserField, String eventId, List<String> sessionId){
        String q = 'SELECT Id, Propose_End_Date_Time__c, Propose_Start_Date_Time__c, Status__c, ' + 
            String.valueOf(titleField) + ',' + 
            String.valueOf(startDateTimeField) + ',' +
            String.valueOf(endDateTimeField) + ',' +
            String.valueOf(descriptionField) + ',' +
            String.valueOf(userField) +  ',' +
            'Event__c,Event__r.Name, Location__c, User_Time_Zone__c, Time_Zone__c, Event__r.Time_Zone__c' + ' FROM  Session__c WHERE ' + 
            'Event__r.Event_Id__c' + ' = \'' +String.valueOf(eventId)+ '\'' +
            (sessionId.size() > 0? ' AND Id in: sessionId': '') + /* Start CCN-EVE-3580-DV: Von Pernicia*/
            ' AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, Propose_Start_Date_Time__c ASC';
        

        /*
       String q = 'SELECT Id, Propose_End_Date_Time__c, Propose_Start_Date_Time__c, Status__c, ' + 
            String.valueOf(titleField) + ',' + 
            String.valueOf(startDateTimeField) + ',' +
            String.valueOf(endDateTimeField) + ',' +
            String.valueOf(descriptionField) + ',' +
            String.valueOf(userField) +  ',' +
            'Event__c, Location__c, User_Time_Zone__c' + ' FROM ' + 
            String.valueOf(sObjectName) + ' WHERE ' + 
            'Event__r.Event_Id__c' + ' = \'' +String.valueOf(eventId)+ '\'' +
            ' AND IsActive__c = true ORDER BY Start_Date_Time__c ASC, Propose_Start_Date_Time__c ASC';
        */


        System.Debug('query: '+q);
      
        List<Session__c> sObjectList = Database.query(q);
        List<EventObj> eventRecords = new List<EventObj>();
        
        //Added for Namespace Issue Fixes 08.Aug.2022
        String orgNamespace = String.isNotBlank(FlsUtils.prefix) ? FlsUtils.prefix : ''; // Added for Namespace Issue Fixes - Jayson Labnao September222022
        //CCN-2289 XenReyes Nov2022
        sObjectName =  orgNamespace == null ? sObjectName : orgNamespace + sObjectName;
        //End of changes for Namespace Issue Fixes 
        
        if(isAccessible(sObjectName)) {
            for (Session__c session : sObjectList) {
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
                if(session.Status__c == 'Proposed' || session.Status__c == 'Rejected'){
                    strtDteTime = session.Propose_Start_Date_Time__c;
                    endDteTime = session.Propose_End_Date_Time__c;

                }else{
                    strtDteTime = session.Start_Date_Time__c;
                    endDteTime = session.End_Date_Time__c;
                }
                
                System.Debug('!@#$% strtDteTime: '+strtDteTime);
                EventObj newEv = new EventObj(String.valueOF(session.Id),
                                              Session.Name,
                                              strtDteTime,
                                              endDteTime,
                                              session.Session_Details__c,
                                              String.valueOf(session.CreatedById),
                                              statusStr,
                                              session.Location__c,
                                              session.User_Time_Zone__c,
                                              session.Time_Zone__c,
                                              session.Event__r.Name, 
                                              session.Event__r.Time_Zone__c
                                             );
                eventRecords.add(newEv);
            }
        }
        
        System.Debug('eventRecords: '+eventRecords);
        return eventRecords;
    }
	
    @AuraEnabled
    public static Session__c insertSession(String sEventObj, String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField, String eventRecId){
        EventObj insertingEvent = (EventObj)JSON.deserialize(sEventObj, EventObj.class);
        sObject newRecord = Schema.getGlobalDescribe().get(sObjectName).newSObject();
        // Start CCN-3116 converting of timezone - GabDelavin - 06/28/2023
        Integer startDateOffset = getOffset(String.valueOf(insertingEvent.startDateTime).replace('T',' '));
        Integer endDateOffset = getOffset(String.valueOf(insertingEvent.endDateTime).replace('T',' '));
        // End CCN-3116 converting of timezone - GabDelavin - 06/28/2023
        
        Session__c sessionToInsert = new Session__c();
        System.debug('insertingEvent: ' + insertingEvent);
        
         // Start CCN-3116 converting of timezone - GabDelavin - 06/28/2023
        if (isAccessible(sObjectName,startDateTimeField)) {
            newRecord.put(startDateTimeField, insertingEvent.startDateTime.addHours(StartDateOffset));
        }
        if (isAccessible(sObjectName,endDateTimeField)) {
            newRecord.put(endDateTimeField, insertingEvent.endDateTime.addHours(StartDateOffset));
        }
        
        
        sessionToInsert.Propose_Start_Date_Time__c = DateTime.valueOf(newRecord.get(startDateTimeField));
        sessionToInsert.Start_Date_Time__c = DateTime.valueOf(newRecord.get(startDateTimeField));
        sessionToInsert.Propose_End_Date_Time__c = DateTime.valueOf(newRecord.get(endDateTimeField));
        sessionToInsert.End_Date_Time__c = DateTime.valueOf(newRecord.get(endDateTimeField));
        // End CCN-3116 converting of timezone - GabDelavin - 06/28/2023
        sessionToInsert.Status__c = 'Proposed';
        sessionToInsert.Session_Details__c = insertingEvent.description;
        sessionToInsert.IsActive__c = true;
        sessionToInsert.Name = insertingEvent.title;
        sessionToInsert.Event__c = eventRecId;
        sessionToInsert.Location__c = insertingEvent.location;
      
      	// CCN-EVE-3113-DV - Gian Bata: Added timezoneAbbr so that we're able to insert the event's timezone as the default value for newly created sessions  
        sessionToInsert.Time_Zone__c = insertingEvent.timezoneAbbr;
        
        try {
            System.debug('sessionToInsert ::'+sessionToInsert);
            insert sessionToInsert;
        } catch (Exception e) {
             System.debug(e.getMessage());
             return null;
        }
        
        return sessionToInsert;
    }
        
    //Added for [CCN-1148] Feb042022
    public class CustomException extends Exception{}
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  07-10-2022   Ruth Lugpatan        [CCN-2164] Added isDST parameter
    * @version   3.0  25-10-2022   Von Pernicia         [CNN-2192] comment out/ removed isDST
    * 													added addHours in upsertingEvent.startDateTime upsertingEvent.endDateTime
    ******************************************************************************/
    @AuraEnabled
    public static EventObj upsertEvents(String sEventObj, String sObjectName, String titleField, String startDateTimeField, String endDateTimeField, String descriptionField, String userField){
		
        EventObj upsertingEvent = (EventObj)JSON.deserialize(sEventObj, EventObj.class);
        sObject newRecord = Schema.getGlobalDescribe().get(sObjectName).newSObject(); 
        
        // Start CNN-2192
        Integer startDateOffset = getOffset(String.valueOf(upsertingEvent.startDateTime).replace('T',' '));
        Integer endDateOffset = getOffset(String.valueOf(upsertingEvent.endDateTime).replace('T',' '));
        // End CNN-2192
        
        if (upsertingEvent.Id != null && isAccessible(sObjectName,'Id')){
            newRecord.put('Id',upsertingEvent.Id);
        } 
        // Start CNN-2192
        if (isAccessible(sObjectName,startDateTimeField)) {
            newRecord.put(startDateTimeField, upsertingEvent.startDateTime.addHours(StartDateOffset));
        }
        if (isAccessible(sObjectName,endDateTimeField)) {
            newRecord.put(endDateTimeField, upsertingEvent.endDateTime.addHours(StartDateOffset));
        }
        // End CNN-2192
        //Start CCN-2620 - reverted back again
        if (isAccessible(sObjectName,'Status__c')){
            newRecord.put('Status__c', 'Proposed');
        }
        //End CCN-2620
        if (isAccessible(sObjectName,'Location__c')){
            newRecord.put('Location__c', upsertingEvent.location);
        }

        try {
            upsert newRecord;
            System.debug('newRecord :: ' +newRecord);
            EventObj newEv = new EventObj(newRecord.Id,
                                  String.valueOf(newRecord.get(titleField)),
                                  DateTime.valueOf(newRecord.get(startDateTimeField)),
                                  DateTime.valueOf(newRecord.get(endDateTimeField)),
                                  String.valueOf(newRecord.get(descriptionField)),
                                  String.valueOf(newRecord.get(userField)),
                                  String.valueOf(newRecord.get('Status__c')),
                                  String.valueOf(newRecord.get('Location__c')),
                                  null,null,null,null
                                 );
            System.debug('newEv' +newEv);
            return newEv;
        } catch (Exception e) {            
            System.debug(e.getMessage());
            throw new CustomException(e.getMessage() + '---' + UserInfo.getProfileId()); //Added for [CCN-1148] Feb042022
            //return null; //Commented for [CCN-1148] Feb042022
        }
        
    }
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  25-10-2022   Von Pernicia         [CNN-2192] to compute offset for DST specific for America/New_York
    ******************************************************************************/
    public static Integer getOffset(String dateString) {
        
        Timezone tz = Timezone.getTimeZone(System.Label.Reference_Timezone);
        DateTime dateTimeValue = DateTime.valueOf(dateString);
        Integer timeZoneOffSet = tz.getOffset(dateTimeValue);
        Integer offset = 0;
        if (timeZoneOffSet == -18000000) {
            offset = 5;
        } else {
            offset = 4;
        }
        
        return offset;
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
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  22-06-2023   Gian Bata         [CCN-EVE-3113-DV] get the event object's timezone
    *******************************************************************************/
    @AuraEnabled
    public static String getEventTimeZone(String eventId) {
        Event__c eventRecord = [SELECT Time_Zone__c FROM Event__c WHERE Event_Id__c = :eventId];
        
        return eventRecord.Time_Zone__c;
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
        public String timezoneAbbr {get;set;}
        @AuraEnabled
        public String eventName {get;set;}
        @AuraEnabled
        public String commonTimezone {get;set;} // Start/End CNN-2192 25-10-2022 Xen
        @AuraEnabled
        public String eventTimeZone {get;set;}

        
        public EventObj(String i,String t, DateTime s, DateTime e, String d, String o, String st, String l, String tz, String tzAbbr, String en, String etz){
            this.Id = i;
            this.title = t;
            this.startDateTime = s;
            this.endDateTime = e;
            this.description = d;
            this.owner = o;
            this.status = st;
            this.location = l;
            this.timezone = tz;
            this.timezoneAbbr = tzAbbr;
            this.eventName = en;
            this.commonTimezone = System.Label.Reference_Timezone; // Start/End CNN-2192 25-10-2022 Xen
        }
        
    }
    public static Boolean isAccessible(String sObjectType, String fieldName){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        Map<String, SObjectField> fields = schemaType.getDescribe().fields.getMap();
        DescribeFieldResult fieldDescribe = fields.get(fieldName).getDescribe();
        return fieldDescribe.isAccessible();
    }
    public static Boolean isAccessible(String sObjectType){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        return schemaType.getDescribe().isAccessible();
    }
    public static Boolean isCreateable(String sObjectType){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        return schemaType.getDescribe().isCreateable();
    }
    public static Boolean isDeletable(String sObjectType){
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        return schemaType.getDescribe().isDeletable();
    }
    
    
   
}