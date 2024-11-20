public with sharing class TestDataFactory {
    public static Compass_Setting__c createCSData(Integer recordCounter) {
        Compass_Setting__c record = new Compass_Setting__c(
            Name             = 'Default Settings',
            Email_Sender_Name__c     = 'Default Name',
            Notify_User__c        =  UserInfo.getUserId(),
            Notify_Emails__c      = 'test@gmail.com'
        );
        return record;
    }
    public static Campaign__c createCampaign(Integer recordCounter) {
        
        Account acc = createAccount('Test Account');
        insert acc;
        
        Campaign__c record = new Campaign__c(
            Name = 'Test Campaign' + recordCounter,
            Site_Picklist_Values__c = 'Site 1,Site 2,Site 3',
            Account__c = acc.Id
        );
        return record;
    }
    public static Apex_Trigger_Switch__c createTriggerSwitch(String operationName) {
        Apex_Trigger_Switch__c record = new Apex_Trigger_Switch__c(
            Name          = operationName,
            Active__c        = true
        );
        
        return record;
    }
    public static Account createAccount(String name) {
        Account record = new Account(
            Name = name
        );
        
        return record;
    }
    public static User createUser(String firstname, String lastname, String email, String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name =: profileName LIMIT 1];
        User record = new User(
            FirstName = firstname,
            LastName = lastname,
            Email = email,
            Username = email,
            Alias = firstname.charAt(0)+lastname,
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/New_York'
        );
        
        return record;
    }
    public static Campaign createStandardCampaign(String campaignName) {
        Campaign record = new Campaign(
            Name = campaignName,
            IsActive = true
        );
        
        return record;
    }
    public static Event__c createEvent(String name, Id campaignId) {
        Event__c record = new Event__c(
            Name = name,
            Campaign__c = campaignId
        );
        
        return record;
    }
    public static Session__c createSession(String name, String eventId) {
        Session__c record = new Session__c(
            Name = name,
            Event__c = eventId
        );
        
        return record;
    }
    public static Participant__c createParticipant(Id eventId, Id contactId) {
        Participant__c record = new Participant__c(
            Event__c = eventId,
            Member_Contact__c = contactId
        );
        
        return record;
    }
    public static Session_Participant__c createSessionParticipant(Id sessionId) {
        Session_Participant__c record = new Session_Participant__c(
            Session__c = sessionId
        );
        
        return record;
    }
    public static Contact createContact(String firstname, String lastname, String email){
        Contact newContact = new Contact(
            Firstname = firstname,
            Lastname = lastname,
            Email = email,
            Contact_Type__c = 'Client'
        );
        return newContact;
    }
    //update every time a new switch is added
    public static List<Apex_Trigger_Switch__c> createAllTriggerSwitch() {
        List<Apex_Trigger_Switch__c> apexSwitchRecords = new List<Apex_Trigger_Switch__c>();
        apexSwitchRecords.add(TestDataFactory.createTriggerSwitch('EventTrigger'));
        apexSwitchRecords.add(TestDataFactory.createTriggerSwitch('SessionParticipantTrigger'));
        return apexSwitchRecords;
    }
}