/**
@author Paolo Quiambao
@date 26 August 2020
@group NCC
@description Test class for EventConfirmationResponseController.apxc
**/
@isTest
public class EventConfirmationResponseControllerTest {
    @testSetup
    static void testSetup() {
        Apex_Trigger_Switch__c aps_sp = TestDataFactory.createTriggerSwitch('SessionParticipantTrigger');
        aps_sp.Active__c = false;
        insert aps_sp;
        
        Compass_Setting__c cSetting = TestDataFactory.createCSData(1);
        cSetting.Domain_Name__c  = 'https://dev3-nationalcoordinationcenter.cs90.force.com/Compass';
        insert cSetting;
        
        Campaign__c campaign = TestDataFactory.createCampaign(1);
        insert campaign;
        
        Event__c event = TestDataFactory.createEvent('Test Event', campaign.id);
        insert event;
        
        Session__c session = TestDataFactory.createSession('Test Session', event.Id);
        insert session;
        
        Session_Participant__c sessionParticipant = TestDataFactory.createSessionParticipant(session.Id);
        insert sessionParticipant;

        Contact attendee = TestDataFactory.createContact('Test', 'Attendee', 'test.attendee@gmail.com');
        insert attendee;

         // Create Internal Resources
         Internal_Resource__c ir = new Internal_Resource__c();
         ir.Contact__c  = attendee.Id;
         ir.Event__c    = event.Id;

         insert ir;

         // Create Internal Resources Session
         Internal_Resource_Session__c irs = new Internal_Resource_Session__c();
         irs.Contact__c  = attendee.Id;
         irs.Event__c    = event.Id;
         irs.Resource__c = ir.Id;
         irs.Session__c  = session.Id;
         irs.Resource_Session_Status__c = 'Registered';

         insert irs;
    }
    
    @isTest
    static void updateSessionParticipantStatus_confirmed() {
        Session_Participant__c sessionParticipant = [SELECT Id FROM Session_Participant__c LIMIT 1];
        PageReference pageRef = Page.EventConfirmationResponse;
        pageRef.getParameters().put('id', sessionParticipant.Id);
        pageRef.getParameters().put('response', 'Confirmed');
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        EventConfirmationResponseController controller = new EventConfirmationResponseController();
        controller.updateSessionParticipantStatus();
        Session_Participant__c sp = [SELECT Status__c, Confirmed_Date__c FROM Session_Participant__c LIMIT 1];
        System.assertEquals('Confirmed' , sp.Status__c, 'Status should be set to Confirmed.');
        Test.stopTest();       
    }
    
    @isTest
    static void updateSessionParticipantStatus_declined() {
        Session_Participant__c sessionParticipant = [SELECT Id FROM Session_Participant__c LIMIT 1];
        PageReference pageRef = Page.EventConfirmationResponse;
        pageRef.getParameters().put('id', sessionParticipant.Id);
        pageRef.getParameters().put('response', 'Declined');
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        EventConfirmationResponseController controller = new EventConfirmationResponseController();
        controller.updateSessionParticipantStatus();
        Session_Participant__c sp = [SELECT Status__c, Declined_Date__c FROM Session_Participant__c LIMIT 1];
        System.assertEquals('Declined' , sp.Status__c, 'Status should be set to Declined.');
        Test.stopTest();       
    }

    @isTest
    static void updateInternalResourceSession_confirmed() {
        Internal_Resource_Session__c sessionParticipant = [SELECT Id FROM Internal_Resource_Session__c LIMIT 1];
        PageReference pageRef = Page.EventConfirmationResponse;
        pageRef.getParameters().put('id', sessionParticipant.Id);
        pageRef.getParameters().put('response', 'Confirmed');
        Test.setCurrentPage(pageRef);
        
        Test.startTest();
        EventConfirmationResponseController controller = new EventConfirmationResponseController();
        controller.updateSessionParticipantStatus();
        Internal_Resource_Session__c sp = [SELECT Resource_Session_Status__c, Resource_Confirmed_Date_Time__c FROM Internal_Resource_Session__c LIMIT 1];
        System.assertEquals('Confirmed' , sp.Resource_Session_Status__c, 'Status should be set to Confirmed.');
        Test.stopTest();       
    }
}