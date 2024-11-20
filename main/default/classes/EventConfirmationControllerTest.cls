/**
@author Jasmine Nguyen
@date 31 August 2020
@group NCC
@description Event Confirmation Template
@revision   Jasmine Nguyen - 05 Septemper: Uncommented and modified testGetSessionsDetails()
to accomondate the changes in the helper class
**/

@isTest
public with sharing class EventConfirmationControllerTest {
  
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
            Session__c testSessionRec = new Session__c();
            testSessionRec.Contact__c = attendee.Id;
            testSessionRec.Session__C = childSession.Id;
            testSessionRec.Event__c = e.Id;
            testSessionRec.Start_Date_Time__c = System.now().addDays(7);
            testSessionRec.End_Date_Time__c = System.now().addDays(8);
            testSessionRec.Time_Zone__c = 'PST';
            insert testSessionRec;
            
            Participant__c p = TestDataFactory.createParticipant(e.Id, attendee.Id);
            insert p;
            
            Session_Participant__c sp = TestDataFactory.createSessionParticipant(testSessionRec.Id);
            sp.Event__c = e.Id;
            sp.Contact__c = attendee.Id;
            sp.Status__c = 'Registered';
            insert sp;
        }
    }

    @isTest
    public static void testGetSessionsDetailsWithContactUsUser(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testUser15092020@gmail.com' LIMIT 1];
        System.runAs(testUser){
            Account testAccount2 = new Account();
            testAccount2.Name = 'Some Account 2';
            testAccount2.BillingStreet = '456 Green Avenue';
            testAccount2.BillingCity = 'Melbourne';
            testAccount2.BillingPostalCode = '3055';
            testAccount2.BillingState = 'VIC';
            testAccount2.BillingCountry = 'Australia';
            insert testAccount2;
            User contactUsUser = TestFactory.createInteralUser('ContactUs', 'User', 'contactus@gmail.com', 'System Administrator');
            contactUsUser.TimeZoneSidKey = 'America/New_York';
            update contactUsUser;
            User campaignOwner2 = TestFactory.createInteralUser('Campaign', 'Owner2', 'campaign.owner2@gmail.com', 'System Administrator');
            campaignOwner2.TimeZoneSidKey = 'America/New_York';
            update campaignOwner2;
            Campaign parentEvent = TestFactory.createCampaign('Parent Event 2', 'Event');
            parentEvent.Location__c = testAccount2.Id;
            parentEvent.OwnerId = campaignOwner2.Id;
            parentEvent.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            parentEvent.End_Date_Time__c = DateTime.newInstance(2020, 8, 31, 12, 30, 0);
            parentEvent.Contact_Us_User__c = contactUsUser.Id;
            update parentEvent;
            Campaign childSession = TestFactory.createCampaign('Child Session 2', 'Session');
            childSession.ParentId = parentEvent.Id;
            childSession.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            childSession.End_Date_Time__c = DateTime.newInstance(2020, 8, 29, 12, 30, 0);
            update childSession;
            Contact attendee = TestFactory.createContact('Test', 'Attendee2', 'test.attendee2@gmail.com');
            CampaignMember cm = TestFactory.createCampaignMember(parentEvent.Id, attendee);
            Event__c e = TestFactory.createEvent('Test Event2');
            Session__c testSessionRec = new Session__c();
            testSessionRec.Contact__c = attendee.Id;
            testSessionRec.Session__C = childSession.Id;
            testSessionRec.Event__c = e.Id;
            insert testSessionRec;
            List<CampaignMember> campaignMemberList = [SELECT Id FROM CampaignMember WHERE Contact.Email = 'test.attendee2@gmail.com'];
            if (campaignMemberList.size() > 0){
                EventConfirmationController ecc = new EventConfirmationController();
                ecc.setCampaignMemberId(campaignMemberList[0].Id);
                Test.startTest();
                List<EventConfirmationHelper.SessionWrapper> resultSessions = ecc.getSessions();
                Test.stopTest();
                if (resultSessions != null && resultSessions.size() > 0){
                    System.assertEquals(campaignMemberList[0].Id, ecc.getCampaignMemberId());
                    System.assertEquals(1, resultSessions.size());
                    System.assertEquals('Child Session 2', resultSessions[0].Name);
                    System.assertEquals('08/29/2020', resultSessions[0].SessionDate);
                    System.assertEquals('8:30 AM to 12:30 PM', resultSessions[0].SessionTime);
                    System.assertEquals('456 Green Avenue, Melbourne, VIC 3055, Australia', resultSessions[0].SessionLocation);
                }
            }
        }
    }


    @isTest
    public static void testGetSessionsDetailsWithoutContactUsUser(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testUser15092020@gmail.com' LIMIT 1];
        System.runAs(testUser){
            List<CampaignMember> campaignMemberList = [SELECT Id FROM CampaignMember WHERE Contact.Email = 'test.attendee@gmail.com'];
            if (campaignMemberList.size() > 0){
                EventConfirmationController ecc = new EventConfirmationController();
                ecc.setCampaignMemberId(campaignMemberList[0].Id);
                Test.startTest();
                List<EventConfirmationHelper.SessionWrapper> resultSessions = ecc.getSessions();
                Test.stopTest();
                if (resultSessions != null && resultSessions.size() > 0){
                    System.assertEquals(campaignMemberList[0].Id, ecc.getCampaignMemberId());
                    System.assertEquals(1, resultSessions.size());
                    System.assertEquals('Child Session', resultSessions[0].Name);
                    System.assertEquals('08/29/2020', resultSessions[0].SessionDate);
                    System.assertEquals('8:30 AM to 12:30 PM', resultSessions[0].SessionTime);
                    System.assertEquals('123 Green Avenue, Melbourne, VIC 3000, Australia', resultSessions[0].SessionLocation);
                }
            }
        }
    }

    @isTest
    public static void testGetFormattedDateTimeNull(){
        EventConfirmationController ecc = new EventConfirmationController();
        System.assertEquals('', ecc.getFormattedDatetime());
    }
    
    @isTest
    public static void testGetFormattedStartDateTimeWithContactUsUser(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testUser15092020@gmail.com' LIMIT 1];
        System.runAs(testUser){
            Account testAccount3 = new Account();
            testAccount3.Name = 'Some Account 3';
            testAccount3.BillingStreet = '789 Green Avenue';
            testAccount3.BillingCity = 'Melbourne';
            testAccount3.BillingPostalCode = '3022';
            testAccount3.BillingState = 'VIC';
            testAccount3.BillingCountry = 'Australia';
            insert testAccount3;
            User contactUsUser3 = TestFactory.createInteralUser('ContactUs', 'User3', 'contactus3@gmail.com', 'System Administrator');
            contactUsUser3.TimeZoneSidKey = 'America/New_York';
            update contactUsUser3;
            User campaignOwner3 = TestFactory.createInteralUser('Campaign', 'Owner3', 'campaign.owner3@gmail.com', 'System Administrator');
            campaignOwner3.TimeZoneSidKey = 'America/New_York';
            update campaignOwner3;
            Campaign parentEvent = TestFactory.createCampaign('Parent Event 2', 'Event');
            parentEvent.Location__c = testAccount3.Id;
            parentEvent.OwnerId = campaignOwner3.Id;
            parentEvent.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            parentEvent.End_Date_Time__c = DateTime.newInstance(2020, 8, 31, 12, 30, 0);
            parentEvent.Contact_Us_User__c = contactUsUser3.Id;
            update parentEvent;
            Campaign childSession = TestFactory.createCampaign('Child Session 2', 'Session');
            childSession.ParentId = parentEvent.Id;
            childSession.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
            childSession.End_Date_Time__c = DateTime.newInstance(2020, 8, 29, 12, 30, 0);
            update childSession;
            Contact attendee = TestFactory.createContact('Test', 'Attendee2', 'test.attendee2@gmail.com');
            CampaignMember cm = TestFactory.createCampaignMember(parentEvent.Id, attendee);
            Event__c e = TestFactory.createEvent('Test Event1');
            Session__c testSessionRec = new Session__c();
            testSessionRec.Contact__c = attendee.Id;
            testSessionRec.Session__C = childSession.Id;
            testSessionRec.Event__c = e.Id;
            insert testSessionRec;
            List<Campaign> campaigns = [SELECT ID, OwnerId FROM Campaign WHERE Name = 'Parent Event 2' LIMIT 1];
            if (campaigns.size() > 0){
                EventConfirmationController ecc = new EventConfirmationController();
                ecc.campaignId = campaigns[0].Id;
                ecc.campaignOwnerId = campaigns[0].OwnerId;
                ecc.defined_format = 'EEE, d MMM yyyy h:mm a';
                ecc.startOrEndDate = 'start';
                //System.assertEquals('Sat, 29 Aug 2020 8:30 AM', ecc.getFormattedDatetime());   
            }
        }
    }
    
    @isTest
    public static void testGetFormattedEndDateTime(){
        /*User testUser = [SELECT Id FROM User WHERE Username = 'testUser15092020@gmail.com' LIMIT 1];
        System.runAs(testUser){
            List<Campaign> campaigns = [SELECT ID, OwnerId FROM Campaign WHERE Name = 'Parent Event' LIMIT 1];
            if (campaigns.size() > 0){
                EventConfirmationController ecc = new EventConfirmationController();
                ecc.campaignId = campaigns[0].Id;
                ecc.campaignOwnerId = campaigns[0].OwnerId;
                ecc.defined_format = 'EEE, d MMM yyyy h:mm a';
                ecc.startOrEndDate = 'end';
                //System.assertEquals('Mon, 31 Aug 2020 12:30 PM', ecc.getFormattedDatetime());   
            }
        }*/
        List<Campaign> campaigns = [SELECT ID, OwnerId FROM Campaign WHERE Name = 'Parent Event' LIMIT 1];
        List<Event__c> event = [SELECT Id FROM Event__c LIMIT 1];
        Test.startTest();
        EventConfirmationHelper.getFormattedDateTimeHelper(campaigns[0].OwnerId, event[0].Id, 'start', 'EEE, d MMM yyyy h:mm a', 'date');
        Test.stopTest();
    }
    
    @isTest
    public static void testGetFormattedEndDateTimeWithException(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testUser15092020@gmail.com' LIMIT 1];
        System.runAs(testUser){
            List<Campaign> campaigns = [SELECT ID, OwnerId FROM Campaign WHERE Name = 'Parent Event' LIMIT 1];
            if (campaigns.size() > 0){
                EventConfirmationController ecc = new EventConfirmationController();
                EventConfirmationHelper.throwFakeException = true;
                ecc.campaignId = campaigns[0].Id;
                ecc.campaignOwnerId = campaigns[0].OwnerId;
                ecc.defined_format = 'EEE, d MMM yyyy h:mm a';
                ecc.startOrEndDate = 'end';
                System.assertEquals('', ecc.getFormattedDatetime());   
            }
        }
    }
    
    @isTest
    public static void getSessionsDetailsTest() {
        List<Participant__c> participantList = [SELECT Id FROM Participant__c LIMIT 1];
        Test.startTest();
        EventConfirmationHelper.EventConfirmationWrapper ecw = EventConfirmationHelper.getSessionsDetails(participantList[0].Id);
        Test.stopTest();
    }
}