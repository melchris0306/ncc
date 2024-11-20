@isTest
public with sharing class BatchEventDeliveryConfirmationTest {

    @TestSetup
    static void makeData(){
        //User testUser = TestFactory.createInteralUser('Test', 'User', 'testUser15092020@gmail.com', 'System Administrator');
        User testUser = TestDataFactory.createUser('Test', 'User', 'testUser15092020@gmail.com', 'System Administrator');
        System.runAs(testUser){
            Compass_Setting__c cSetting = TestDataFactory.createCSData(1);
            cSetting.Domain_Name__c  = 'https://dev3-nationalcoordinationcenter.cs90.force.com/Compass';
            insert cSetting;
            
            List<Apex_Trigger_Switch__c> atsList = new List<Apex_Trigger_Switch__c>();
            Apex_Trigger_Switch__c aps_p = TestDataFactory.createTriggerSwitch('ParticipantTrigger');
            aps_p.Active__c = false;
            atsList.add(aps_p);
            
            Apex_Trigger_Switch__c aps_sp = TestDataFactory.createTriggerSwitch('SessionParticipantTrigger');
            aps_sp.Active__c = false;
            atsList.add(aps_sp);
            insert atsList;
            
            Account testAccount = TestDataFactory.createAccount('Test Account');
            testAccount.BillingStreet = '123 Green Avenue';
            testAccount.BillingCity = 'Melbourne';
            testAccount.BillingPostalCode = '3000';
            testAccount.BillingState = 'VIC';
            testAccount.BillingCountry = 'Australia';
            insert testAccount;
            
            User campaignOwner = TestDataFactory.createUser('Campaign', 'Owner', 'campaign.owner@gmail.com', 'System Administrator');
            campaignOwner.TimeZoneSidKey = 'America/New_York';
            insert campaignOwner;
            
            Campaign parentEvent = TestDataFactory.createStandardCampaign('Parent Event');
            parentEvent.Location__c = testAccount.Id;
            parentEvent.OwnerId = campaignOwner.Id;
            parentEvent.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            parentEvent.End_Date_Time__c = DateTime.newInstance(2020, 8, 31, 12, 30, 0);
            insert parentEvent;
            
            Campaign childSession = TestDataFactory.createStandardCampaign('Child Session');
            childSession.ParentId = parentEvent.Id;
            childSession.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            childSession.End_Date_Time__c = DateTime.newInstance(2020, 8, 29, 12, 30, 0);
            insert childSession;
            
            Contact attendee = TestDataFactory.createContact('Test', 'Attendee', 'test.attendee@gmail.com');
            insert attendee;
            
            CampaignMember cm = TestFactory.createCampaignMember(parentEvent.Id, attendee);
            Event__c e = TestFactory.createEvent('Test Event');
	    
	    DateTime dt = System.now().addDays(7);
	    
            Session__c testSessionRec = new Session__c();
            testSessionRec.Contact__c = attendee.Id;
            testSessionRec.Session__C = childSession.Id;
            testSessionRec.Event__c = e.Id;
            testSessionRec.Start_Date_Time__c = Datetime.newInstance(dt.year(), dt.month(), dt.day(), 12, 30, 2);
            testSessionRec.End_Date_Time__c = Datetime.newInstance(dt.year(), dt.month(), dt.day(), 12, 31, 2);
            testSessionRec.Time_Zone__c = 'PST';
            insert testSessionRec;
            
            Participant__c p = TestDataFactory.createParticipant(e.Id, attendee.Id);
            insert p;
            
            Session_Participant__c sp = TestDataFactory.createSessionParticipant(testSessionRec.Id);
            sp.Event__c = e.Id;
            sp.Contact__c = attendee.Id;
            sp.Status__c = 'Registered';
            insert sp;

            // Create Internal Resources
            Internal_Resource__c ir = new Internal_Resource__c();
            ir.Contact__c  = attendee.Id;
            ir.Event__c    = e.Id;

            insert ir;

            // Create Internal Resources Session
            Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
            irs.Contact__c  = attendee.Id;
            irs.Event__c    = e.Id;
            irs.Resource__c = ir.Id;
            irs.Session__c  = testSessionRec.Id;
            irs.Resource_Session_Status__c = 'Registered';

            insert irs;

            Batch_Processor__c bp = new Batch_Processor__c();
            bp.Record_Id__c = ir.Id;
            bp.Type__c = 'BatchEventDeliveryConfirmation';
            bp.Trigger_Source__c = 'InternalResourceSessionTriggerHandler';
            insert bp;
        }
    }

    @isTest
    static void BatchEventDeliveryConfirmationExcuteTest() {
        
        Test.startTest();
        BatchEventDeliveryConfirmation abc = new BatchEventDeliveryConfirmation();
        abc.execute(null);
        Test.stopTest();       
    }
}