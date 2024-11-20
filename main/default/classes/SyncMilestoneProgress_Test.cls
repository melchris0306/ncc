/*******************************************************************************
* @author       Kyzer Buhay
* @date         05/04/2021
* @description  Test class for SyncMilestoneProgress
*******************************************************************************/
@IsTest
public class SyncMilestoneProgress_Test {

    @testSetup
    static void createData(){
        OrgWideEmailAddress owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.Email = 'test@email.com';
        insert testContact;
        
		Campaign__c testCampaign = new Campaign__c();
        testCampaign.Name = 'Test Campaign Name';
        
        insert testCampaign;
        
        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'Test Journey';
        testJourney.Campaign__c = testCampaign.Id;
        testJourney.Status__c = 'Approved';
        insert testJourney;
        
        Journey_Participant__c testParticipant = new Journey_Participant__c();
        testParticipant.Journey__c = testJourney.Id;
        testParticipant.Contact__c = testContact.Id;
        //System.debug('####### 3rd' + testContact.Id);
        insert testParticipant;
        
        Account newAccount = new Account();
        newAccount.Name = 'John Doe\'s Inc.';
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        newAccount.RecordTypeId = accRecordTypeId;
        insert newAccount;
        
        Participant_Milestone__c testPMilestones = new Participant_Milestone__c();
        testPMilestones.Journey__c = testParticipant.Id;
        testPMilestones.Contact__c = testContact.Id;
        testPMilestones.Type__c = 'Event';
        insert testPMilestones;
        
        Milestone__c testMilestone = new Milestone__c();
        testMilestone.Journey__c = testJourney.Id;
        testMilestone.Name = 'Test Milestone';
        testMilestone.Type__c = 'Communication';
        insert testMilestone;
        
        Participant_Milestone_Metric__c pMilesMetric = new 	Participant_Milestone_Metric__c();
        pMilesMetric.Milestone__c = testPMilestones.Id;
        pMilesMetric.Metric_Used__c = 'Date Invited';
        insert pMilesMetric;
        
        Task testTask = new Task();
        testTask.WhatId = testPMilestones.Id;
        testTask.Type = 'Related Information';
        insert testTask;
        
        Apex_Trigger_Switch__c apexSwitch = TestDataFactory.createTriggerSwitch('EventTrigger');
        apexSwitch.Name = 'EventTrigger';
        insert apexSwitch;
        
        Apex_Trigger_Switch__c apexSwitch1 = TestDataFactory.createTriggerSwitch('EventTrigger');
        apexSwitch1.Name = 'SessionParticipantTrigger';
        insert apexSwitch1;
            
        
        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test', IsActive = true);
        system.runAs( new User(Id = UserInfo.getUserId())){
        	insert e;
        }
        
        Compass_Setting__c compSetting = new Compass_Setting__c();
        compSetting.Name = 'Default Settings';
        compSetting.Email_Sender_Id__c = '123';
        compSetting.Email_Sender_Name__c = 'NAME';
        compSetting.Email_Template_Invitation_Id__c = e.Id;
        compSetting.Email_Template_Registration_Id__c = e.Id;
        insert compSetting;
        
        Event__c testEvent = new Event__c();
        testEvent.Campaign__c = testCampaign.Id;
        testEvent.Journey__c = testJourney.Id;
        //System.debug('####### 2nd' + testJourney.Id);
        testEvent.Milestone__c = true;
        testEvent.Email_Sender_Id__c = testContact.Id;
        testEvent.Email_Sender_Id__c = owea.Id;
        insert testEvent;
        
        Survey__c testSurvey = new Survey__c();
        testSurvey.Name = 'Test survey';
        testSurvey.Event__c = testEvent.Id;
        testSurvey.Survey_Campaign__c = testCampaign.Id;
        testSurvey.Journey__c = testJourney.Id;
        testSurvey.Milestone__c = true;
        insert testSurvey;
        
        Participant_Milestone__c pmRec = [SELECT Id, Name FROM Participant_Milestone__c WHERE Id=:testPMilestones.Id];
        Session__c testSession = new Session__c();
        testSession.Name = pmRec.Name;
        //System.debug('####### 1st' + pmRec.Name);
        testSession.Event__c = testEvent.Id;
        testSession.Milestone__c = true;
        testSession.Time_Zone__c = 'AKDT';
        testSession.Start_Date_Time__c = system.today();
        testSession.End_Date_Time__c = system.today() + 10;
        insert testSession;
        
        Communication__c testComms = new Communication__c();
        testComms.Journey__c = testJourney.Id;
        testComms.Campaign__c = testCampaign.Id;
        testComms.Milestone__c = true;
        insert testComms;
        
        Session_Participant__c sessParticipant = new Session_Participant__c();
        sessParticipant.Event__c = testEvent.Id;
        sessParticipant.Contact__c = testContact.Id;
        sessParticipant.Session__c = testSession.Id;
        insert sessParticipant;
        
        Participant__c participantData = new Participant__c();
        participantData.Event__c = testEvent.Id;
        participantData.Member_Contact__c = testContact.Id;
        insert participantData;
        
        Milestone_Metric__c mMetric = new Milestone_Metric__c();
        mMetric.Journey__c = testJourney.Id;
        mMetric.Type__c = 'Communication';
        //mMetric.Name = 'Test Milestone Metric';
        insert mMetric;
    }
    
    @IsTest static void syncMilestoneProgressTest(){
        try{
            Test.startTest();
                Journey__c testJourney = [SELECT Id, Name FROM Journey__c WHERE Name='Test Journey' LIMIT 1];
            
                Journey_Participant__c jParticipant = [SELECT Id,Journey__r.Id, Contact__r.Id FROM Journey_Participant__c WHERE Journey__r.Id = :testJourney.Id LIMIT 1];
                SyncMilestoneProgress.syncMilestoneProgress(jParticipant.Id);
                SyncMilestoneProgress syncMilestoneProg = new SyncMilestoneProgress();
            
            	Session__c session = [SELECT Id, Name FROM Session__c LIMIT 1];
            	//System.debug('###### 4th ' + session.Name +  '------- ' + testJourney.Id + ' --------- ' +jParticipant.Contact__r.Id);
            	syncMilestoneProg.getEventDetails(session.Name, testJourney.Id, jParticipant.Contact__r.Id);
            
                syncMilestoneProg.sync(jParticipant.Id);
            
        	Test.stopTest();
        }catch(Exception e){
            System.debug(LoggingLevel.DEBUG, '!@# ERROR IN INSERT: ' + e.getMessage());
        }
        
    }
}