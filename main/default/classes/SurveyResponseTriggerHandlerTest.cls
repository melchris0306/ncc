/*******************************************************************************************
  * @name: SurveyResponseTriggerHandlerTest
  * @author: Von Pernicia
  * @created: 03-02-2022
  * @description: [CCN-496]
*********************************************************************************************/
@isTest
private class SurveyResponseTriggerHandlerTest {

    @TestSetup
    static void createData(){
        Account newAccount = new Account();
        newAccount.Name = 'John Doe\'s Inc.';
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        newAccount.RecordTypeId = accRecordTypeId;
        insert newAccount;

        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.Email = 'test@email.com';
        testContact.Account = newAccount;
        insert testContact;

        Campaign__c testCampaign = new Campaign__c();
        testCampaign.Name = 'Test Campaign Name';
        insert testCampaign;

        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'Test Journey';
        testJourney.Campaign__c = testCampaign.Id;
        testJourney.Status__c = 'Approved';
        insert testJourney;

       
        Communication__c testRecord = new Communication__c();
        testRecord.Campaign__c = testCampaign.Id;
        testRecord.Status__c = 'Draft';
        testRecord.Frequency__c = 'Real-time';
        testRecord.Active__c = true;
        testRecord.Subject__c = 'Test Comm Subject';
        testRecord.Body__c = 'Test Comm HTML Body';
        testRecord.Email_Recipient_CC__c = 'testCC1@testEmailUtility.test, testCC2@testEmailUtility.test, testCC3@testEmailUtility.test, testCC4@testEmailUtility.test';
        testRecord.Email_Recipient_BCC__c = 'testBCC1@testEmailUtility.test, testBCC2@testEmailUtility.test, testBCC3@testEmailUtility.test, testBCC4@testEmailUtility.test';
        testRecord.OwnerId = UserInfo.getUserId();
        testRecord.Journey__c = testJourney.Id;
        testRecord.Milestone__c = true;
        insert testRecord;

        //create Communication_Recipient__c
        List<Communication_Recipient__c> crList = new List<Communication_Recipient__c>();
        crList.add(new Communication_Recipient__c(CC_Communication__c=testRecord.Id, Contact__c = testContact.Id));
        insert crList;

        EmailTemplate e = new EmailTemplate (DeveloperName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        System.runAs( new User(Id = UserInfo.getUserId())){
            insert e;
        }

        Compass_Setting__c compSetting = new Compass_Setting__c();
        compSetting.Name = 'Default Settings';
        compSetting.Email_Sender_Id__c = '123';
        compSetting.Email_Sender_Name__c = 'NAME';
        compSetting.Email_Template_Invitation_Id__c = e.Id;
        compSetting.Email_Template_Registration_Id__c = e.Id;
        insert compSetting;

        OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'Edera' LIMIT 1];

        Event__c testEvent = new Event__c();
        testEvent.Name = 'Test Event';
        testEvent.Campaign__c = testCampaign.Id;
        testEvent.Journey__c = testJourney.Id;
        testEvent.Milestone__c = true;
        testEvent.Email_Sender_Id__c = testContact.Id;
        testEvent.Email_Sender_Id__c = owea.Id;
        insert testEvent;

        TestFactory.createSession('Test Session 1', testEvent.Id);

        TestFactory.createParticipant( testEvent.Id, testContact);

        Survey__c testSurvey = new Survey__c();
        testSurvey.Name = 'Test survey';
        testSurvey.Event__c = testEvent.Id;
        testSurvey.Survey_Campaign__c = testCampaign.Id;
        testSurvey.Journey__c = testJourney.Id;
        testSurvey.Milestone__c = true;
        testSurvey.Active__c = true;
        insert testSurvey;

        //TestFactory.createSurveyResponse(testEvent.Id, testSurvey.Id, newAccount.Id);

        List<Adhoc_Journey_Assignment__c> adhocList = new List<Adhoc_Journey_Assignment__c>();
        Adhoc_Journey_Assignment__c adhoc1 = new Adhoc_Journey_Assignment__c(
            Journey__c = testJourney.Id,
            Survey__c = testSurvey.Id,
            //Event__c = testEvent.Id,
            Type__c = 'Survey'
        );
        adhocList.add(adhoc1);

        Adhoc_Journey_Assignment__c adhoc2 = new Adhoc_Journey_Assignment__c(
            Journey__c = testJourney.Id,
            //Survey__c = testSurvey.Id,
            Event__c = testEvent.Id,
            Type__c = 'Event'
        );
        adhocList.add(adhoc2);

        insert adhocList;
    }

    @IsTest
    static void testBehavior() {

        Event__c testEvent = [SELECT Id FROM Event__c];
        Survey__c testSurvey = [SELECT Id FROM Survey__c];
        Account newAccount = [SELECT Id FROM Account];
        Contact testContact = [SELECT Id FROM Contact];

        Survey_Response__c newSR = new Survey_Response__c();
        newSR.Event__c = testEvent.id;
        newSR.Survey__c = testSurvey.id;
        newSR.Account__c = newAccount.id;
        newSR.Contact__c = testContact.id;
        insert newSR;

    }
}