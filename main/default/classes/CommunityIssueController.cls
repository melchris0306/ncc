/**
@revision Kyzer Buhay - New Object Reference (Project_Issue__c) to Issue__c
                      - Changed Apex Class Name (CommunityProjectIssueController) to CommunityIssueController
                      - Updated Aura component communityProjectIssue apex controller name
**/
global with sharing class CommunityIssueController  {

    private static WithoutSharingClass withoutShare = new WithoutSharingClass(); 
    
    // Added by JaysonLabnao [NamespaceIssueFixes] August192022
    @AuraEnabled
    public static string getNamespacePrefix(){
        String prefix = String.isNotBlank(FlsUtils.prefix) ? FlsUtils.prefix : '';
        return prefix;
    }

    @AuraEnabled 
    //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param 
    public static string getProjectDetails(String eventId, String sortByValue){
        
        Map<String,Object> returnMap = new Map <String,Object>();
        String eventRecordId = '';
        Event__c campaignRecord;
        sortByValue = (sortByValue == 'Session_Name' ? 'Session__r.Name' : sortByValue);
        try{
            if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Subtitle__c','Event_Id__c','Hero_Image_URL__c','Campaign_Logo_URL__c',
                'Description__c','Contact_Us_Tag_Line__c','Contact_Us_Message__c', 'OwnerId', 'Start_Date_Time__c','Contact_Us_User__c',
                'Time_Zone__c','Status__c','End_Date_Time__c','Parking_Lot_Tag_Line__c','Parking_Lot_Message__c'}) 
                    && FlsUtils.isAccessible('Account', new List<String>{'BillingStreet','BillingCity',
                        'BillingPostalCode','BillingState','BillingCountry','Name'})){

                campaignRecord = withoutShare.getEvent(eventId);
            }
            
            eventRecordId =  campaignRecord.Id;
            returnMap.put('campaignRecord',campaignRecord);

        } catch(QueryException e){
            if(String.isBlank(eventRecordId)){
                throw new AuraHandledException('Invalid Event Id');     
            }
        }

        List<Session__c> sessionList = new List<Session__c>();

        if(FlsUtils.isAccessible('Session__c', new List<String>{'Name','Subtitle__c','Start_Date_Time__c','End_Date_Time__c','Description__c','Time_Zone__c'})){
            sessionList = withoutShare.getSessions(eventRecordId);   
        }

        if (!sessionList.isEmpty()){
            returnMap.put('session', sessionList.get(0));
        } else {
            throw new AuraHandledException('The event has no active session');
        }

        String strTZone = [SELECT Id, TimeZoneSidKey FROM Organization LIMIT 1].TimeZoneSidKey;

        //wrap sessionList
        List<CustomParkingLotFormController.SessionWrapper> sessionWrapper = new List<CustomParkingLotFormController.SessionWrapper>();
        final String STARTDATE_SAME_WITH_ENDDATE_FORMAT = '{0} - {1}, {2} to {3} {4}';
        final String STARTDATE_NOT_SAME_WITH_ENDDATE_FORMAT = '{0} - {1}, {2} to {3}, {4} {5}';

        for(Session__c session : sessionList){
            CustomParkingLotFormController.SessionWrapper wrapper = new CustomParkingLotFormController.SessionWrapper();
            String sessionName = '';
            DateTime startDT = session.Start_Date_Time__c;
            DateTime endDT = session.End_Date_Time__c;

            if(startDT.date() == endDT.date()){
                sessionName = String.format(STARTDATE_SAME_WITH_ENDDATE_FORMAT, 
                                        new List<Object>{session.Name, startDT.format('MMMMM dd, yyyy', strTZone),
                                            startDT.format('hh:mm aaa', strTZone), endDT.format('hh:mm aaa', strTZone),
                                            session.Time_Zone__c});
            } else{
                sessionName = String.format(STARTDATE_NOT_SAME_WITH_ENDDATE_FORMAT, 
                                        new List<Object>{session.Name, startDT.format('MMMMM dd, yyyy', strTZone),
                                            startDT.format('hh:mm aaa', strTZone), endDT.format('hh:mm aaa', strTZone),
                                            endDT.format('hh:mm aaa', strTZone), session.Time_Zone__c});
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

        returnMap.put('sessionWrapper', sessionWrapper);
        returnMap.put('sessionList',  sessionList);
        
        //Get Project issues list List
        List<Issue__c> projIssueList = new List<Issue__c>();
        if(FlsUtils.isAccessible('Issue__c', new List<String>{'Name','Date_Raised__c','Raised_By__c','CreatedDate','Likelihood__c','Impact__c',
                'Status__c','Due_Date__c','Assigned_To__c','Resolution__c','Notes__c','Raised_By_Email__c','Description__c','Type__c','Session__c'})
            && FlsUtils.isAccessible('Session__c', new List<String>{'Name'})){
                //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param
                projIssueList = withoutShare.getProjectIssues(eventRecordId, sortByValue);
        }
        returnMap.put('projIssueList', projIssueList);
        
        List<String> typeList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Issue__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry pickListVal : ple){
            typeList.add(pickListVal.getLabel());
        }

        returnMap.put('typeList',typeList);    
        
        return JSON.serialize(returnMap);                                    
    }
    
    @AuraEnabled
    // Create project issue
    public static void createProjectIssue(String eventId, String session, String email, String description, String type){
        final String STATUS_NEW = 'New';

        if (String.isBlank(session) || String.isBlank(eventId) || String.isBlank(email) || String.isBlank(description) || String.isBlank(type)){ 
            throw new AuraHandledException('Error on creating project raid: Required fields missing');
        }

        Issue__c newProjectIssue = new Issue__c(
            Session__c = session,
            Event__c = withoutShare.getEventName(eventId).Id,
            Raised_By_Email__c = email,
            Description__c = description,
            Status__c = STATUS_NEW,
            Type__c = type,
            Date_Raised__c = Date.today()
        );

        String contactId = checkIfContactExist(email);

        if(String.isNotBlank(contactId)){
            newProjectIssue.Raised_By__c = contactId;
        }

        try{
            if(FlsUtils.isCreateable(newProjectIssue, new List<String>{'Session__c','Event__c','Raised_By_Email__c','Description__c','Status__c',
                    'Type__c', 'Date_Raised__c'})){

                withoutShare.createProjectIssue(newProjectIssue);
            }
        } catch(DmlException e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static String checkIfContactExist(String email){
        List<Contact> contacts = new List<Contact>();
        if(FlsUtils.isAccessible('Contact', new List<String>{'Firstname','Lastname', 'Email'})){
            contacts = withoutShare.getContact(email);
        }

        return !contacts.isEmpty() ? String.valueOf(contacts[0].Id) : '';
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
        //needs tro be inside without sharing because guest user does not have access to contact records (for Raised_By__c)
        public void createProjectIssue(Issue__c projectIssue){
            insert projectIssue;
        }

        public List<Contact> getContact(String email){
            return [SELECT Id, Firstname, Lastname, Email FROM Contact WHERE Email = :email LIMIT 1];
        }

        //Updated by MMallorca [CCN793,794,795] Oct192021 Add sortByValue param
        public List<Issue__c> getProjectIssues(String eventId, String sortByValue){
            String soqlQuery = 'SELECT Id, Name, CreatedDate, Date_Raised__c, Raised_By__c, Likelihood__c, Impact__c, Status__c, Due_Date__c, ';
            soqlQuery += 'Assigned_To__c, Resolution__c, Notes__c, Raised_By_Email__c, Description__c, Type__c, Session__r.Name, Session__c ';
            soqlQuery += 'FROM Issue__c ';
            soqlQuery += 'WHERE Event__r.Id = :eventId  ';
            if(sortByValue != null){
                soqlQuery += 'ORDER BY '+ sortByValue +' ASC';
            }
            else{
                soqlQuery += 'ORDER BY Name DESC ';
            }
            return Database.query(soqlQuery);
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

        public Event__c getEventName(String eventCode){
            return [SELECT Id, Name
                FROM Event__c 
                WHERE Event_Id__c = :eventCode];
        }

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
                Issue_Tracker_Page_Title__c,
                End_Date_Time__c
                FROM Event__c 
                WHERE Event_Id__c = :eventCode];
        }
    }
}