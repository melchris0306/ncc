/**
 * Created by angelorivera on 7/4/2022.
 */

@IsTest
private class BatchUpdateCompletedMilestones_Test {

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
        //CCN-1004 Xen Reyes January 25, 2022
        crList.add(new Communication_Recipient__c(CC_Communication__c=testRecord.Id, Contact__c = testContact.Id, Send_as__c = 'To'));
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
        testSurvey.Campaign_1__c = testCampaign.Id;
        testSurvey.Journey__c = testJourney.Id;
        testSurvey.Milestone__c = true;
        testSurvey.Active__c = true;
        insert testSurvey;

        TestFactory.createSurveyResponse(testEvent.Id, testSurvey.Id, newAccount.Id);

        Journey_Participant__c testParticipant = new Journey_Participant__c();
        testParticipant.Journey__c = testJourney.Id;
        testParticipant.Contact__c = testContact.Id;
        insert testParticipant;

        Milestone_Metric__c mm = new Milestone_Metric__c();
        mm.Type__c = 'Event';
        mm.Tracked_Field__c='Registration Date';
        mm.Journey__c = testJourney.Id;
        insert mm;

        Milestone_Metric__c mm1 = new Milestone_Metric__c();
        mm1.Type__c = 'Event';
        mm1.Tracked_Field__c='Attendance Date';
        mm1.Journey__c = testJourney.Id;
        insert mm1;

        Milestone_Metric__c mm2 = new Milestone_Metric__c();
        mm2.Type__c = 'Communication';
        mm2.Tracked_Field__c='Date Sent';
        mm2.Journey__c = testJourney.Id;
        insert mm2;

        Milestone_Metric__c mm3 = new Milestone_Metric__c();
        mm3.Type__c = 'Survey';
        mm3.Tracked_Field__c='Date Responded';
        mm3.Journey__c = testJourney.Id;
        insert mm3;

        Milestone__c testCheckpoint = new Milestone__c();
        testCheckpoint.RecordTypeId = Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName().get('Checkpoint').getRecordTypeId();
        testCheckpoint.Journey__c = testJourney.Id;
        testCheckpoint.Name = 'Test Checkpoint';
        testCheckpoint.Type__c = 'Checkpoint';
        insert testCheckpoint;

        Milestone__c testParentMilestone = new Milestone__c();
        testParentMilestone.Journey__c = testJourney.Id;
        testParentMilestone.Name = 'Test Parent Milestone';
        testParentMilestone.Type__c = 'Event';
        testParentMilestone.Parent__c = testCheckpoint.Id;
        testParentMilestone.End_Date__c = System.today() - 5;
        insert testParentMilestone;

        Milestone__c testMilestone2 = new Milestone__c();
        testMilestone2.Journey__c = testJourney.Id;
        testMilestone2.Name = 'Test Event';
        testMilestone2.Type__c = 'Event';
        testMilestone2.Parent_Milestone__c = testParentMilestone.Id;
        insert testMilestone2;

        Milestone__c testMilestone3 = new Milestone__c();
        testMilestone3.Journey__c = testJourney.Id;
        testMilestone3.Name = 'Test Comm Subject';
        testMilestone3.Type__c = 'Communication';
        testMilestone3.Parent__c = testCheckpoint.Id;
        insert testMilestone3;

        Milestone__c testMilestone4 = new Milestone__c();
        testMilestone4.Journey__c = testJourney.Id;
        testMilestone4.Name = 'Test survey';
        testMilestone4.Type__c = 'Survey';
        testMilestone4.Parent__c = testCheckpoint.Id;
        insert testMilestone4;

        Journey_Participant__c testParticipant2 = new Journey_Participant__c();
        testParticipant2.Journey__c = testJourney.Id;
        testParticipant2.Contact__c = testContact.Id;
        insert testParticipant2;

    }

    @IsTest
    static void testBatchCreateParticipantMilestones(){

        Set<Id> setUserJourneyId = new Set<Id>();
        Set<Id> setJourneyIds = new Set<Id>();
        Map<Id, Map<String, List<String>>> mapMilestoneMetricByTypeByJourneyId = new Map<Id, Map<String, List<String>>>();
        Id  idJourney;
        for(Participant_Milestone__c pm : [SELECT Id, Journey__c, Journey__r.Journey__c FROM Participant_Milestone__c]){
            setUserJourneyId.add(pm.Journey__c);
            setJourneyIds.add(pm.Journey__r.Journey__c);
            idJourney = pm.Journey__r.Journey__c;
            System.debug('!@#$: pm.Journey__r.Journey__c: '+ pm.Journey__r.Journey__c);
        }
        String strRet = ParticipantMilestoneMetricService.generateParticipantMilestonMetric(idJourney);

        BatchUpdateCompletedMilestones batchObj = new  BatchUpdateCompletedMilestones();
        Id batchProcessId = Database.executeBatch(batchObj,200);


        BatchUpdateCompletePartMilestones  batchObj1 = new  BatchUpdateCompletePartMilestones ();
        Id batchProcessId2 = Database.executeBatch(batchObj1,200);

    }
}