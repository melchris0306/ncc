/**
* Description: This is the controller class for communityEventParkingLot, which creates a parking lot record and display exisiting records
* Author: Jester Cabantog
* Version: 1.0
* Last modified date: 12/16/2020
* Modified by: 7/18/2023 Rex David - CCN-EVE-3029-DV: Events - Parking Lot view only option
**/
public with sharing class CustomParkingLotFormController {
    
    private static WithoutSharingClass withoutShare = new WithoutSharingClass(); 
    private final static String STARTDATE_SAME_WITH_ENDDATE_FORMAT = '{0} - {1}, {2} to {3} {4}';
    private final static String STARTDATE_NOT_SAME_WITH_ENDDATE_FORMAT = '{0} - {1}, {2} to {3}, {4} {5}';
    
    
    // Added by JaysonLabnao [NamespaceIssueFixes] August172022
    @AuraEnabled
    public static string getNamespacePrefix(){
        String prefix = String.isNotBlank(FlsUtils.prefix) ? FlsUtils.prefix : '';
        return prefix;
    }

    //PT-00333 Event Parking Lot
    //Updated by MMallorca [CCN790,791,792] Oct212021 
    @AuraEnabled 
    public static string getParkingLotDetails(String eventId, String contactId, String sortByValue){
        Map<String,Object> returnMap = new Map <String,Object>();
        Event__c campaignRecord = new Event__c();
        String eventRecordId;
        try{
            //CCN-EVE-3029-DV Rex David - Added fields
            if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Subtitle__c','Event_Id__c','Hero_Image_URL__c','Campaign_Logo_URL__c',
                'Description__c','Contact_Us_Tag_Line__c','Contact_Us_Message__c', 'OwnerId', 'Start_Date_Time__c','Contact_Us_User__c',
                'Time_Zone__c','Status__c','End_Date_Time__c','Parking_Lot_Tag_Line__c','Parking_Lot_Message__c','Parking_Lot_Close_Date__c','Parking_Lot_Close_Message__c'}) 
               && FlsUtils.isAccessible('Account', new List<String>{'BillingStreet','BillingCity',
                   'BillingPostalCode','BillingState','BillingCountry','Name'})){
                       campaignRecord = withoutShare.getEvent(eventId); 
                   }
            eventRecordId = campaignRecord.Id;
            returnMap.put('campaignRecord', campaignRecord);
            
        } catch (QueryException e){
            if(String.isBlank(eventRecordId)){
                throw new AuraHandledException('Invalid Event Id');     
            }
        }
        
        if(FlsUtils.isAccessible('Contact', new List<String>{'FirstName','LastName','Email'})){
            List<Contact> contactDetails = withoutShare.getContacts(contactId);
            if(!contactDetails.isEmpty()){
                returnMap.put('contact',contactDetails[0]);
            }
        }
        
        List<Session__c> sessionList;
        List<Parking_Lot__c> parkingLotList;
        if(FlsUtils.isAccessible('Session__c', new List<String>{'Name','Subtitle__c','Start_Date_Time__c','End_Date_Time__c','Description__c','Time_Zone__c'})){
            sessionList = withoutShare.getSessions(eventRecordId);
        }       
        if(!sessionList.isEmpty()){
            returnMap.put('session', sessionList.get(0));
        } else {
            throw new AuraHandledException('The event has no active session');
        }
        
        if(String.isBlank(contactId)){
            if(FlsUtils.isAccessible('Parking_Lot__c', new List<String>{'Name','Description__c','Escalated_To__c','Event__c','Raised_By__c',
                'Addressed_By__c','Resolution_Answer__c','Session__c','Site__c','Status__c','Type__c','Category__c'})
               && FlsUtils.isAccessible('Event__c', new List<String>{'Name'})
               && FlsUtils.isAccessible('Contact', new List<String>{'FirstName','LastName','Email','Name'})
               && FlsUtils.isAccessible('Session__c', new List<String>{'Name'})){
                   // Updated by MMallorca [CCN790,791,792] Oct212021 
                   parkingLotList = withoutShare.getParkingLots(eventRecordId, sortByValue);
               }
        } else {
            if(FlsUtils.isAccessible('Session__c', new List<String>{'Name','Subtitle__c','Start_Date_Time__c','End_Date_Time__c','Description__c','Time_Zone__c'})){
                sessionList = withoutShare.getSessionsWithParticipants(eventRecordId, contactId);
            }
            
            if(sessionList.isEmpty()){
                throw new AuraHandledException('Participant is not registered on any session');
            }
            
            if(FlsUtils.isAccessible('Parking_Lot__c', new List<String>{'Name','Description__c','Escalated_To__c','Event__c','Raised_By__c',
                'Addressed_By__c','Resolution_Answer__c','Session__c','Site__c','Status__c','Type__c','Category__c'})
               && FlsUtils.isAccessible('Event__c', new List<String>{'Name'})
               && FlsUtils.isAccessible('Contact', new List<String>{'FirstName','LastName','Email','Name'})
               && FlsUtils.isAccessible('Session__c', new List<String>{'Name'})){
                   // Updated by MMallorca [CCN790,791,792] Oct212021 
                   parkingLotList = withoutShare.getParkingLots(eventRecordId, sortByValue);
               }
        }
        
        //20201230 JL bug fix#00601:Session Picklist(https://ulapp-developers.force.com/projects/s/detail/a0x3k00001UqIwYAAV)
        String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;
        //wrap sessionList
        List<CustomParkingLotFormController.SessionWrapper> sessionWrapper = new List<CustomParkingLotFormController.SessionWrapper>();
        
        for(Session__c session: sessionList){
            CustomParkingLotFormController.SessionWrapper wrapper = new CustomParkingLotFormController.SessionWrapper();
            String sessionName = '';
            DateTime startDT = session.Start_Date_Time__c;
            DateTime endDT = session.End_Date_Time__c;
            if(startDT != null || endDT != null){
                if(startDT.date() == endDT.date()){
                    sessionName = String.format(STARTDATE_SAME_WITH_ENDDATE_FORMAT, 
                                                new List<Object>{session.Name, startDT.format('MMMMM dd, yyyy', strTZone),
                                                    startDT.format('hh:mm aaa', strTZone), endDT.format('hh:mm aaa', strTZone),
                                                    session.Time_Zone__c});
                    
                } else {
                    sessionName = String.format(STARTDATE_NOT_SAME_WITH_ENDDATE_FORMAT, 
                                                new List<Object>{session.Name, startDT.format('MMMMM dd, yyyy', strTZone),
                                                    startDT.format('hh:mm aaa', strTZone), endDT.format('hh:mm aaa', strTZone),
                                                    endDT.format('hh:mm aaa', strTZone), session.Time_Zone__c});
                } 
            }
            wrapper.recordId = session.Id;
            wrapper.sessionName = session.Name;
            wrapper.sessionFullName = sessionName;
            wrapper.startdatetime = startDT;
            wrapper.enddatetime = endDT;
            wrapper.description = session.Description__c;
            wrapper.timezone = session.Time_Zone__c;
            sessionWrapper.add(wrapper);
        }
        
        returnMap.put('sessionWrapper',sessionWrapper);
        returnMap.put('sessionList',sessionList);
        returnMap.put('parkingLotList',parkingLotList);
        
        List<String> typeList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Parking_Lot__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            typeList.add(pickListVal.getLabel());
        }
        
        returnMap.put('typeList',typeList);
        
        //Categories picklist values
        List<String> categoryList= new List<String>();
        Schema.DescribeFieldResult categoryFieldResult = Parking_Lot__c.Category__c.getDescribe();
        List<Schema.PicklistEntry> categoryPle = categoryFieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : categoryPle){
            categoryList.add(pickListVal.getLabel());
        }
        
        returnMap.put('categoryList',categoryList);
        
        return JSON.serialize(returnMap);                                    
    }
    
    //PT-00333 Event Parking Lot
    @AuraEnabled
    // Create parkinglot for each request sent from the custom parking lot form
    // Updated by MMallorca [CCN790,791,792] Oct212021 
    public static void createParkingLot(String eventId, String session, String email, String phone, String description, String type, String category){
        
        if (String.isBlank(eventId) || String.isBlank(session) || String.isBlank(email) || String.isBlank(description) || String.isBlank(type)){
            throw new AuraHandledException('Error on creating parking lot: Required fields missing');
        } 
        
        CustomParkingLotFormHelper.createParkingLotHelper(eventId, session,  email, phone, description, type, category);
    }
    
    //PT-00333 Event Parking Lot
    @AuraEnabled
    // Update parking lot from parking lot data table below parking lot form
    public static void updateParkingLots(String parkingLots){
        
        List<Parking_Lot__c> editedParkingLots = (List<Parking_lot__c>)JSON.deserialize(parkingLots,List<Parking_lot__c>.Class);
        try{
            withoutShare.updateParkingLots(editedParkingLots);
        }
        catch(DmlException e){
            if(e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST') && e.getMessage().contains('Type__c')){
                List<String> typeList= new List<String>();
                Schema.DescribeFieldResult fieldResult = Parking_Lot__c.Type__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                    typeList.add(pickListVal.getLabel());
                }    
                throw new AuraHandledException('Invalid Type value: '+typeList.toString());
            }
            else if(e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST') && e.getMessage().contains('Status__c')){
                List<String> statusList= new List<String>();
                Schema.DescribeFieldResult fieldResult = Parking_Lot__c.Status__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                    statusList.add(pickListVal.getLabel());
                }    
                throw new AuraHandledException('Invalid Status value: '+statusList.toString());
            }
            else{
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
    
    public class SessionWrapper{
        @AuraEnabled public Id recordId                 {get; set;}
        @AuraEnabled public String  sessionName         {get; set;}
        @AuraEnabled public String  sessionFullName     {get; set;}
        @AuraEnabled public DateTime  startdatetime     {get; set;}
        @AuraEnabled public DateTime  enddatetime       {get; set;}
        @AuraEnabled public String  description         {get; set;}
        @AuraEnabled public String  timezone            {get; set;}
    }
    
    //Needs inner class declared without sharing for guest users to retrieve relevant records
    private without sharing class WithoutSharingClass {
        
        public void updateParkingLots(List<Parking_Lot__c> editedParkingLots){
            update editedParkingLots;
        }
        
        public List<Contact> getContacts(String contactId){
            return [SELECT Id, Name, Email from Contact WHERE Id = :contactId];
        }
        
        public List<Session__c> getSessions(String eventId){
            return [SELECT Name, Id,
                    Subtitle__c,  
                    Start_Date_Time__c, 
                    End_Date_Time__c, 
                    Description__c, 
                    Time_Zone__c
                    FROM Session__c 
                    WHERE Event__r.Id = :eventId 
                    AND IsActive__c = true 
                    ORDER By Name ASC, Start_Date_Time__c ASC];
        }
        
        public List<Session__c> getSessionsWithParticipants(String eventRecordId, String contactId){
            return [SELECT Name, Id,
                    Subtitle__c,  
                    Start_Date_Time__c, 
                    End_Date_Time__c, 
                    Description__c, 
                    Time_Zone__c
                    FROM Session__c 
                    WHERE Event__r.Id = :eventRecordId 
                    AND Id IN (SELECT Session__c FROM Session_Participant__c
                               WHERE Contact__c =: contactId 
                               AND Event__c = :eventRecordId)
                    AND IsActive__c = true 
                    ORDER By Name ASC, Start_Date_Time__c ASC];
        }
        
        // Updated by MMallorca [CCN790,791,792] Oct212021 
        public List<Parking_Lot__c> getParkingLots(String eventRecordId, String sortByValue){
            String soqlQuery = 'SELECT Id, Name, Description__c, Escalated_To__c, Event__c, Event__r.Name,';
                    soqlQuery += 'Raised_By__c, Raised_By__r.FirstName, Raised_By__r.LastName, Raised_By__r.Email, Raised_By__r.Name, ';
                    soqlQuery += 'Addressed_By__c, Addressed_By__r.FirstName, Addressed_By__r.LastName, Addressed_By__r.Email, Addressed_By__r.Name, '; 
                    soqlQuery += 'Resolution_Answer__c, Session__c, Session__r.Name, ';
                    soqlQuery += 'Site__c, Status__c, Type__c, Category__c ';
                    soqlQuery += 'FROM Parking_Lot__c ';
                    soqlQuery += 'WHERE Event__c = :eventRecordId ';
            if(sortByValue != null){
                soqlQuery += 'ORDER BY '+ sortByValue +' ';
            }
            else{
                soqlQuery += 'ORDER BY Name DESC ';
            }
            system.debug('soqlQuery'+soqlQuery);
            return Database.query(soqlQuery);
        }
        //CCN-EVE-3029-DV Rex David - Added fields
        public Event__c getEvent(String eventCode){
            return [SELECT Id, Name,
                    Subtitle__c,
                    Event_Id__c,
                    Hero_Image_URL__c,
                    Campaign_Logo_URL__c, 
                    Description__c,
                    Parking_Lot_Tag_Line__c,
                    Parking_Lot_Message__c,
                    Location__r.BillingStreet,
                    Location__r.BillingCity, 
                    Location__r.BillingPostalCode,
                    Location__r.BillingState,
                    Location__r.BillingCountry,
                    Location__r.Name,
                    OwnerId,
                    Start_Date_Time__c, 
                    Contact_Us_User__c,
                    Time_Zone__c,
                    Status__c,
                    Parking_Lot_Page_Title__c,
                    End_Date_Time__c,
                    Parking_Lot_Close_Date__c,
                    Parking_Lot_Close_Message__c
                    FROM Event__c 
                    WHERE Event_Id__c = :eventCode 
                    LIMIT 1];
        }
    } 
}