@IsTest
private class InternalResourceSessionTrigger_Test {
    @TestSetup
    static void makeData(){

        // Create Apex Trigger Switch
        List<Apex_Trigger_Switch__c> atsList = new List<Apex_Trigger_Switch__c>();

        Apex_Trigger_Switch__c ats = new Apex_Trigger_Switch__c();
        ats.Name        = 'InternalResourceSessionTrigger';
        ats.Active__c   = true;
        insert ats;
        
        Compass_Setting__c cSetting = TestDataFactory.createCSData(1);
        cSetting.Domain_Name__c  = 'https://dev3-nationalcoordinationcenter.cs90.force.com/Compass';
        insert cSetting;

        // Create Contacts
        List<Contact> contactsList = new List<Contact>();

        Contact testContact1 = new Contact();
        testContact1.FirstName  = 'Test 1';
        testContact1.LastName   = 'Contact 1';
        testContact1.Email      = 'testContact1@testemail.com';
        contactsList.add(testContact1);

        Contact testContact2 = new Contact();
        testContact2.FirstName  = 'Test 2';
        testContact2.LastName   = 'Contact 2';
        testContact2.Email      = 'testContact2@testemail.com';
        contactsList.add(testContact2);

        insert contactsList;

        // Create Location
        Id locationRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
        Account testLocation = new Account();
        testLocation.Name           = 'Test Location';
        testLocation.RecordTypeId   = locationRecTypeId;
        insert testLocation;

        // Create Campaign
        Campaign__c testCampaign1 = new Campaign__c();
        testCampaign1.Name = 'Test Campaign 001';
        testCampaign1.Account__c = testLocation.Id;
        insert testCampaign1;

        OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress LIMIT 1];

        // Create Events
        List<Event__c> eventsList = new List<Event__c>();

        Event__c testEvent1 = new Event__c();
        testEvent1.Name                                 = 'Test Event 001';
        testEvent1.Campaign__c                          = testCampaign1.Id;
        testEvent1.Email_Sender_Id__c                   = owea.Id;
        testEvent1.Email_Sender_Name__c                 = owea.DisplayName;
        testEvent1.Milestone__c                         = true;
        testEvent1.IsActive__c                          = true;
        testEvent1.Start_Date_Time__c                   = system.today();
        testEvent1.End_Date_Time__c                     = system.today() + 1;
        testEvent1.Time_Zone__c                         = 'AKDT';
        testEvent1.Resource_Calendar_Invite_Delivery__c = 'Send on session registration';
        eventsList.add(testEvent1);

        Event__c testEvent2 = new Event__c();
        testEvent2.Name                                 = 'Test Event 002';
        testEvent2.Campaign__c                          = testCampaign1.Id;
        testEvent2.Email_Sender_Id__c                   = owea.Id;
        testEvent2.Email_Sender_Name__c                 = owea.DisplayName;
        testEvent2.Milestone__c                         = true;
        testEvent2.IsActive__c                          = true;
        testEvent2.Start_Date_Time__c                   = system.today();
        testEvent2.End_Date_Time__c                     = system.today() + 1;
        testEvent2.Time_Zone__c                         = 'CDT';
        testEvent2.Resource_Calendar_Invite_Delivery__c = 'Send on session confirmation';
        eventsList.add(testEvent2);

        insert eventsList;

        // Create Sessions
        List<Session__c> sessionsList = new List<Session__c>();
        
        Session__c testSession1 = new Session__c();
        testSession1.Name                           = 'Test Session 001';
        testSession1.Event__c                       = testEvent1.Id;
        testSession1.Time_Zone__c                   = 'AKDT';
        testSession1.Start_Date_Time__c             = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        testSession1.End_Date_Time__c               = DateTime.newInstance(2020, 08, 29, 10, 30, 0);
        testSession1.Do_Not_Send_Calendar_Invite__c = false;
        sessionsList.add(testSession1);

        Session__c testSession2 = new Session__c();
        testSession2.Name                           = 'Test Session 001';
        testSession2.Event__c                       = testEvent2.Id;
        testSession2.Time_Zone__c                   = 'CDT';
        testSession2.Start_Date_Time__c             = DateTime.newInstance(2020, 08, 29, 9, 30, 0);
        testSession2.End_Date_Time__c               = DateTime.newInstance(2020, 08, 29, 10, 30, 0);
        testSession2.Do_Not_Send_Calendar_Invite__c = false;
        sessionsList.add(testSession2);

        insert sessionsList;

        // Create Internal Resources
        List<Internal_Resource__c> internalResources = new List<Internal_Resource__c>();

        Internal_Resource__c ir1 = new Internal_Resource__c();
        ir1.Contact__c  = testcontact1.Id;
        ir1.Event__c    = testEvent1.Id;
        internalResources.add(ir1);

        Internal_Resource__c ir2 = new Internal_Resource__c();
        ir2.Contact__c  = testcontact2.Id;
        ir2.Event__c    = testEvent2.Id;
        internalResources.add(ir2);

        insert internalResources;
    }

    
    @IsTest
    static void testEmailForRegisteredResource() {
        
        Internal_Resource__c internalResource = [SELECT Id, Contact__c, Contact__r.LastName FROM Internal_Resource__c WHERE Contact__r.LastName = 'Contact 1'];
        Session__c session = [SELECT Id, Event__c, Event__r.Resource_Calendar_Invite_Delivery__c FROM Session__c WHERE Event__r.Resource_Calendar_Invite_Delivery__c = 'Send on session registration'];

        Test.startTest();
            Internal_Resource_Session__c irSession = new Internal_Resource_Session__c();
            irSession.Event__c                      = session.Event__c;
            irSession.Contact__c                    = internalResource.Contact__c;
            irSession.Resource__c                   = internalResource.Id;
            irSession.Session__c                    = session.Id;
            irSession.Resource_Session_Status__c    = 'Registered';

            insert irSession;

            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        //system.assert(emailInvocations > 0, 'An email should be sent');
    }

    
    @IsTest
    static void testEmailForConfirmedResource() {
        
        Internal_Resource__c internalResource = [SELECT Id, Contact__c, Contact__r.LastName FROM Internal_Resource__c WHERE Contact__r.LastName = 'Contact 2'];
        Session__c session = [SELECT Id, Event__c, Event__r.Resource_Calendar_Invite_Delivery__c FROM Session__c WHERE Event__r.Resource_Calendar_Invite_Delivery__c = 'Send on session confirmation'];
        Internal_Resource_Session__c irSession = new Internal_Resource_Session__c();
            irSession.Event__c                      = session.Event__c;
            irSession.Contact__c                    = internalResource.Contact__c;
            irSession.Resource__c                   = internalResource.Id;
            irSession.Session__c                    = session.Id;
            irSession.Resource_Session_Status__c    = 'Registered';

        insert irSession;

        Test.startTest();
            Internal_Resource_Session__c irSessionUpdate = [SELECT Id, Resource_Session_Status__c FROM Internal_Resource_Session__c WHERE Resource_Session_Status__c = 'Registered'];
            irSessionUpdate.Resource_Session_Status__c = 'Confirmed';

            update irSessionUpdate;

            Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        //system.assert(emailInvocations > 0, 'An email should be sent');
    }
}