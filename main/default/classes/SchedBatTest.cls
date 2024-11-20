@isTest
private class SchedBatTest {

    @testSetup
    static void setup(){

        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
        	insert e;
        }

        Compass_Setting__c setting = new Compass_Setting__c();
        setting.Name = 'Default Settings';
        setting.Email_Sender_Name__c = 'NAME';
        setting.Email_Template_Invitation_Id__c = e.Id;
        setting.Email_Template_Registration_Id__c = e.Id;
        setting.Email_Sender_Id__c = owea.Id;
        insert setting;

        Contact con1 = new Contact();
        con1.FirstName = 'Test Contact';
        con1.LastName = 'Record 1';
        con1.Email = 'testemail@testemail.com';
        insert con1;
        
        //Campaign  
        List<Campaign__c> campList = new List<Campaign__c>();
        Campaign__c camp1 = new Campaign__c();
        camp1.Name = 'Test Campaign 001';
        campList.add(camp1);
        
        insert campList;
   
        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'Test Journey';
        testJourney.Campaign__c = campList[0].Id;
        testJourney.Status__c = 'Approved';
        insert testJourney;
        
        Batch_Processor__c batchProcessor = new Batch_Processor__c(
            Record_Id__c = con1.Id,
            Record_Id_2__c= testJourney.Id,
            Type__c = 'BatchSyncParticipantMilestoneMetric'
        );

        insert batchProcessor;

        Event__c testEvent = new Event__c();
        testEvent.Campaign__c = [SELECT Id FROM Campaign__c LIMIT 1].Id;
        testEvent.Journey__c = [SELECT Id FROM Journey__c LIMIT 1].Id;
        testEvent.Milestone__c = true;
        testEvent.Email_Sender_Name__c = 'TEST 123';
        testEvent.Email_Message_CC__c = 'testMail@mail.com';
        testEvent.Email_Message_BCC__c = 'testMail@mail.com';
        testEvent.Email_Sender_Id__c = owea.Id;
        insert testEvent;

        Participant__c participantData = new Participant__c();
        participantData.Event__c = testEvent.Id;
        participantData.Member_Contact__c = con1.Id;
        participantData.Session_Modified__c = false;
        participantData.Status__c = '';
        insert participantData;

        /* Batch_Processor__c batchProcessor2 = new Batch_Processor__c(
            Record_Id__c = participantData.Id,
            Record_Id_2__c= testJourney.Id,
            Parameter_1__c = 'Invited',
            Type__c = 'ParticipantEmailCommunicationBatch'
        ); 
        insert batchProcessor2; */
        BatchProcessorUtility.insertBatchRecord(new Set<String>{participantData.Id},'ParticipantEmailCommunicationBatch','ParticipantTriggerHandler',UtilityConstant.PARTICIPANT_STATUS_INVITED);
        BatchProcessorUtility.insertBatchRecord(new Set<String>{participantData.Id},'ParticipantEmailCommunicationBatch','ParticipantTriggerHandler',UtilityConstant.PARTICIPANT_STATUS_REGISTERED);
        
    }

    static testmethod void testSchedBatSyncParticipantMilestoneMetric() {
        Test.startTest();
        	new SchedBatSyncParticipantMilestoneMetric().execute(null);
        Test.stopTest();
    }

    static testmethod void testSchedBatParticipantEmailComm() {
        Test.startTest();
            new SchedBatParticipantEmailComm().execute(null);
        Test.stopTest();
    }
}