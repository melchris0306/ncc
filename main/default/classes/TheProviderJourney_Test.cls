/*******************************************************************************
* @author       Allen Francisco
* @date         11.02.2021
* @description  Test class for TheProviderJourney
* @revision     11.02.2021 - ADFrancisco - Created
*******************************************************************************/
@isTest(IsParallel=true)
public class TheProviderJourney_Test {
    @TestSetup
    static void createData() {

        Compass_Setting__c compassSetting = new Compass_Setting__c();
        compassSetting.Name = 'Default Settings';
        compassSetting.Email_Sender_Name__c = 'Test Sender';
        insert compassSetting;

        Account ac = new Account(name ='Ulapp3');
        insert ac;
        Campaign__c testCampaign = new Campaign__c();
        testCampaign.Name = 'Test Campaign Name';
        testCampaign.Account__c = ac.Id;
        insert testCampaign;

        Event__c eve = new Event__c();
        eve.Name = 'Test Event';
        eve.Campaign__c = testCampaign.Id;
        eve.Email_Sender_Id__c = null;
        insert eve;
        
        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'Test Journey';
        testJourney.Campaign__c = testCampaign.Id;
        testJourney.Status__c = 'For Review';
        testJourney.End_Date__c = Date.TODAY() + 10;
        insert testJourney;
        
        Account newAccount = new Account();
        newAccount.Name = 'John Doe\'s Inc.';
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeId();
        newAccount.RecordTypeId = accRecordTypeId;
        insert newAccount;
        
        Contact newContact = new Contact();
        newContact.Firstname = 'John';
        newContact.Lastname = 'Doe';
        newContact.Email = 'john.doe@test.com';
        newContact.AccountId = newAccount.Id;
        insert newContact;
        
        Journey_Participant__c testParticipant = new Journey_Participant__c();
        testParticipant.Journey__c = testJourney.Id;
        testParticipant.Contact__c = newContact.Id;
        insert testParticipant;

        Participant_Milestone__c testPMilestones = new Participant_Milestone__c();
        testPMilestones.Journey__c = testParticipant.Id;
        insert testPMilestones;

        Participant_Milestone__c testPMilestones2 = new Participant_Milestone__c();
        testPMilestones2.Journey__c = testParticipant.Id;
        insert testPMilestones2;

        Milestone__c testMilestoneComms = new Milestone__c();
        testMilestoneComms.Journey__c = testJourney.Id;
        testMilestoneComms.Name = 'Test Milestone Comms';
        testMilestoneComms.Type__c = 'Communication';
        testMilestoneComms.Related_RecordId__c = eve.Id;
        insert testMilestoneComms;
        
        Milestone__c testMilestoneSurvey = new Milestone__c();
        testMilestoneSurvey.Journey__c = testJourney.Id;
        testMilestoneSurvey.Name = 'Test Milestone Survey';
        testMilestoneSurvey.Type__c = 'Survey';
        testMilestoneSurvey.Related_RecordId__c = eve.Id;
        insert testMilestoneSurvey;
        
        testPMilestones.Milestone__c = testMilestoneComms.Id;
        update testPMilestones;

        testPMilestones.Milestone__c = testMilestoneSurvey.Id;
        update testPMilestones2;

        Participant_Milestone_Metric__c pMilesMetric = new Participant_Milestone_Metric__c();
        pMilesMetric.Milestone__c = testPMilestones.Id;
        // Updated by RiannoRizarri [CCN843] March252022
        pMilesMetric.Metric_used__c = 'Attendance Date';
        // Updated by RiannoRizarri [CCN843] March252022
        insert pMilesMetric;
        
        Task testTask = new Task();
        testTask.WhatId = testPMilestones.Id;
        testTask.Type = 'Related Information';
        insert testTask;
    }
    
    @IsTest
    static void getUserJourney() {
        Test.startTest();
        try {
            Journey__c jData = [SELECT Id FROM Journey__c LIMIT 1];
            Journey_Participant__c jParticipant = [
                SELECT Id
                FROM Journey_Participant__c
                LIMIT 1
            ];
            TheProviderJourney.UserJourneyWrapperClass wrapperClass = new TheProviderJourney.UserJourneyWrapperClass();
            wrapperClass = TheProviderJourney.getUserJourney(jParticipant.Id);
            wrapperClass = TheProviderJourney.getUserJourney(jData.Id);
            System.assertNotEquals(wrapperClass, null);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.DEBUG,
                '!@# ERROR IN INSERT: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    //Kyzer Buhay - 05/03/2021
    //01057 - positive testing
    @IsTest
    static void contactUsProcessingNoErrors() {
        Journey_Participant__c jParticipant = [
            SELECT
            Id,
            Contact__r.Id,
            Contact__r.FirstName,
            Contact__r.LastName,
            Contact__r.Email,
            Contact__r.Phone,
            Journey__r.Id,
            Journey__r.CreatedById
            FROM Journey_Participant__c
            LIMIT 1
        ];
        Test.startTest();
        try {
            //Sample Contact Us Form input values to TheProviderJourney.createTaskContactUs
            Boolean hasError = TheProviderJourney.createTaskContactUs( jParticipant.Contact__r.Id, jParticipant.Contact__r.FirstName, jParticipant.Contact__r.LastName,
                                                                      jParticipant.Contact__r.Email, jParticipant.Contact__r.Phone, jParticipant.Journey__r.Id, 'Test Subject', 'Test Comment' );
            
            Integer taskCount = [ SELECT COUNT() FROM Task WHERE WhoId = :jParticipant.Contact__r.Id AND Subject = 'Test Subject'];
            //System.assertEquals(1, taskCount);
            //System.assert(!hasError);
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, '!@# ERROR IN INSERT: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void processSurveyAssessmentCompleteTest(){
        String ppmId = [SELECT Id FROM Participant_Milestone__c LIMIT 1].Id;
        Test.startTest();
        Boolean hasError = TheProviderJourney.processSurveyAssessmentComplete(ppmId);
        Test.stopTest();
        //System.assert(!hasError);
    }

    @IsTest
    static void processEventCatchUpTest(){
        String ppmId = [SELECT Id FROM Participant_Milestone__c LIMIT 1].Id;
        Test.startTest();
        Boolean hasError = TheProviderJourney.processEventCatchUp(ppmId);
        Test.stopTest();
        System.assert(!hasError);
    }

    @IsTest
    static void checkObjectTest(){
        String ppmId = [SELECT Id FROM Participant_Milestone__c LIMIT 1].Id;
        Test.startTest();
        String objType = TheProviderJourney.checkObject(ppmId);
        Test.stopTest();
        System.assertNotEquals(objType, null);
    }

    @IsTest
    static void validateParticipantTest(){
        Journey__c jData = [SELECT Id FROM Journey__c LIMIT 1];
        Test.startTest();
        String resp = TheProviderJourney.validateParticipant('john.doe@test.com',jData.Id);
        Test.stopTest();
        System.assertNotEquals(resp, null);
    }
    // Updated by RiannoRizarri [CCN843] March252022
    @isTest
    static void test_updateParticipantMilestone(){
        Participant_Milestone__c ppmId = [SELECT Id FROM Participant_Milestone__c LIMIT 1];
        TheProviderJourney.ElevatedContext provider = new TheProviderJourney.ElevatedContext();
        provider.updateParticipantMilestone(ppmId);
    }
    // Updated by RiannoRizarri [CCN843] March252022
    
    @isTest
    static void test_saveAnswers(){
        String json = '[{"a9GDS0000004boK2AQ":{"Answer":"Canberra","QuickCheckId":"a9FDS0000000KWB2A2","ParticipantMilestoneId":"a5DDS000003m3672AA","QuestionId":"a9GDS0000004boK2AQ","Question":"<p>What is the Capital of Canberra</p>","CorrectAnswers":"Melbourne","ContactId":"003DS00000uBYdzYAG"}}]';
        Test.startTest();
        TheProviderJourney.saveAnswers(json);
        Test.stopTest();
    }
}