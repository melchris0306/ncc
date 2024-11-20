/*
* @filename        : CloneEventController
* @created         : 09.25.2021
* @author          : Mel
* @description     : CloneEventController Test Class
*/ 

@isTest
public with sharing class CloneEventControllerTest {
    
 @isTest
    public static void testcloneEventRecord(){
        //Account
        Account testAccount2 = new Account();
        testAccount2.Name = 'Test Account 09252021';
        testAccount2.BillingStreet = '12345 Gold Street';
        testAccount2.BillingCity = 'Melbourne';
        testAccount2.BillingPostalCode = '3055';
        testAccount2.BillingState = 'VIC';
        testAccount2.BillingCountry = 'Australia';
        insert testAccount2;
        
        
        Campaign parentEvent = TestFactory.createCampaign('Parent Event 2', 'Event');
        parentEvent.Location__c = testAccount2.Id;
        parentEvent.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
        parentEvent.End_Date_Time__c = DateTime.newInstance(2020, 8, 31, 12, 30, 0);
        update parentEvent;
        
        Campaign childSession = TestFactory.createCampaign('Child Session 2', 'Session');
        childSession.ParentId = parentEvent.Id;
        childSession.Start_Date_Time__c = DateTime.newInstance(2020, 8, 29, 8, 30, 0);
        childSession.End_Date_Time__c = DateTime.newInstance(2020, 8, 29, 12, 30, 0);
        update childSession;
        
        Contact attendee = TestFactory.createContact('Test', 'Attendee2', 'test.attendee2@gmail.com');
        CampaignMember cm = TestFactory.createCampaignMember(parentEvent.Id, attendee);
       
        //Event
        Event__c e = TestFactory.createEvent('Test Event');
        
        //Event Role
        Event_Role__c newEventRole = new Event_Role__c();
        newEventRole.Show_in_Event_Site__c = true;
        newEventRole.Role__c = 'Speaker';
        newEventRole.Contact__c = attendee.Id;
        newEventRole.Event__c = e.Id;
        newEventRole.Campaign__c = childSession.Id;
        insert newEventRole;
        
        //Session
        Session__c testSessionRec = new Session__c();
        testSessionRec.Contact__c = attendee.Id;
        testSessionRec.Session__C = childSession.Id;
        testSessionRec.Event__c = e.Id;
        insert testSessionRec;
        
        //Session Role
        Session_Role__c sessRole = new Session_Role__c();
        sessRole.Role_Title__c = 'Test Role';
        sessRole.Role_Description__c = 'Test Role';
        sessRole.Number_of_Role__c = 1;
        sessRole.Session__c = testSessionRec.Id;
        insert sessRole;
        
        //Internal Session Role
        Internal_Resource_Role__c intRole = new Internal_Resource_Role__c();
        intRole.Session__c = testSessionRec.Id;
        insert intRole;
        
        //Survey
        Survey__c newSurvey1 = TestFactory.createSurvey(e.Id, 'Test Survey With Event With No Selected Fields');
        TestFactory.createSurveyQuestion(newSurvey1.Id, 'What is your name?', 'Text', 1);
        
        Test.startTest();
        System.assertNotEquals(CloneEventController.cloneEventRecord(e.Id), null);
        Test.stopTest();
    }
}