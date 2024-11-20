/*******************************************************************************************
  * @name: SurveyResponseTriggerHandlerTest
  * @author: Von Pernicia
  * @created: 03-02-2022
  * @description: [CCN-496]
*********************************************************************************************/
@isTest
private class CommunicationRecipientTriggerHandlerTest {

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
    }

    @IsTest
    static void testBehavior() {

        Communication__c comm = [SELECT Id FROM Communication__c];
        Contact testContact =[SELECT Id FROM Contact];

        //create Communication_Recipient__c
        List<Communication_Recipient__c> crList = new List<Communication_Recipient__c>();
        crList.add(new Communication_Recipient__c(CC_Communication__c=comm.Id, Contact__c = testContact.Id, Send_as__c = 'To'));
        insert crList;

        EmailTemplate e = new EmailTemplate (DeveloperName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        System.runAs( new User(Id = UserInfo.getUserId())){
            insert e;
        }

        Communication__c updateComm = [SELECT Id, Status__c FROM Communication__c];
        updateComm.Status__c = 'Sent';
        
        Communication_Recipient__c updateCommRecip = [SELECT id, Date_Sent__c FROM Communication_Recipient__c];
        updateCommRecip.Date_Sent__c = System.today();

        update updateCommRecip;
    }
}