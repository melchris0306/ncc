/*******************************************************************************
 * @author       Allen Francisco
 * @date         11.02.2021
 * @description  Test class for JourneyParticipantServices
 * @revision     11.02.2021 - ADFrancisco - Created
*                07.08.2022 - APR - Additional Test Coverage CCN-1849/CCN-1856
*                07.13.2022 - APR - Additional Test Coverage CCN-1843
 *******************************************************************************/
@IsTest(IsParallel=true)
public class JourneyParticipantServices_Test {
  @TestSetup
  static void createData() {
    OrgWideEmailAddress owea = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'National Coordination Center' LIMIT 1];

    /*Organization org = new Organization();
        org.Name = 'Test org';
        org.TimeZoneSidKey = 'America/Chicago';
        insert org;*/
    Account ac = new Account(name ='Ulapp3');
    insert ac;
      
    Contact testContact = new Contact();
    testContact.LastName = 'Test Contact';
    testContact.Email = 'test@email.com';
    insert testContact;

    Campaign__c testCampaign = new Campaign__c();
    testCampaign.Name = 'Test Campaign Name';
    testCampaign.Account__c = ac.Id;

    insert testCampaign;

    Journey__c testJourney = new Journey__c();
    testJourney.Name = 'Test Journey';
    testJourney.Campaign__c = testCampaign.Id;
    testJourney.Status__c = 'Approved';
    testJourney.End_Date__c = Date.TODAY() + 10;
    insert testJourney;

    Journey_Participant__c testParticipant = new Journey_Participant__c();
    testParticipant.Journey__c = testJourney.Id;
    insert testParticipant;
    
    Participant_Milestone__c testPMilestones = new Participant_Milestone__c();
    testPMilestones.Journey__c = testParticipant.Id;
    insert testPMilestones;
      
    Milestone__c testMilestone = new Milestone__c();
    testMilestone.Journey__c = testJourney.Id;
    testMilestone.Name = 'Test Milestone';
    testMilestone.Type__c = 'Communication';
    testMilestone.Start_Date__c = System.today();
    testMilestone.End_Date__c = System.today();
    insert testMilestone;

    Participant_Milestone_Metric__c pMilesMetric = new Participant_Milestone_Metric__c();
    pMilesMetric.Milestone__c = testPMilestones.Id;
    insert pMilesMetric;

    Task testTask = new Task();
    testTask.WhatId = testPMilestones.Id;
    testTask.Type = 'Related Information';
    insert testTask;

    Apex_Trigger_Switch__c apexSwitch = TestDataFactory.createTriggerSwitch(
      'EventTrigger'
    );
    apexSwitch.Name = 'EventTrigger';
    insert apexSwitch;

    Apex_Trigger_Switch__c apexSwitch1 = TestDataFactory.createTriggerSwitch(
      'EventTrigger'
    );
    apexSwitch1.Name = 'SessionParticipantTrigger';
    insert apexSwitch1;

    EmailTemplate e = new EmailTemplate(
      developerName = 'test',
      FolderId = UserInfo.getUserId(),
      TemplateType = 'Text',
      Name = 'test',
      IsActive = true
    );
    System.runAs(new User(Id = UserInfo.getUserId())) {
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
    testEvent.Milestone__c = true;
    testEvent.Email_Sender_Id__c = testContact.Id;
    testEvent.Email_Sender_Id__c = owea.Id;
    testEvent.Start_Date_Time__c = system.today();
    testEvent.End_Date_Time__c = system.today() + 10;
    testEvent.Time_Zone__c = 'ET';
    insert testEvent;

    Survey__c testSurvey = new Survey__c();
    testSurvey.Name = 'Test survey';
    testSurvey.Event__c = testEvent.Id;
    testSurvey.Campaign_1__c = testCampaign.Id;
    testSurvey.Journey__c = testJourney.Id;
    testSurvey.Milestone__c = true;
    insert testSurvey;

    Session__c testSession = new Session__c();
    testSession.Name = 'Test CC Session';
    testSession.Event__c = testEvent.Id;
    testSession.Milestone__c = true;
    testSession.Time_Zone__c = 'AKDT';
    testSession.Start_Date_Time__c = system.today();
    //testSession.End_Date_Time__c = system.today() + 10;
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

  @IsTest
  static void generateMilestone() {
    Id journeyId = [SELECT Id FROM Journey__c LIMIT 1].Id;
    Test.startTest();
    String strResult = JourneyParticipantServices.generateMilestones(journeyId);
    Test.stopTest();
    System.assertNotEquals(strResult, null);
  }

    @IsTest
    static void createJourneyParticipants() {
      Id journeyId = [SELECT Id FROM Journey__c LIMIT 1].Id;
      List<Id> lstIds = new List<Id>();
      for(Event__c evt : [SELECT Id FROM Event__c]){
        lstIds.add(evt.Id);
      }
      Test.startTest();
        JourneyParticipantServices.JourneyEventsWrapper journeyWrapper = new JourneyParticipantServices.JourneyEventsWrapper();
        journeyWrapper = JourneyParticipantServices.retrieveJourneyEvents(journeyId);

        String strResult = JourneyParticipantServices.createJourneyParticipants(journeyId, lstIds);
      Test.stopTest();
      System.assertNotEquals(strResult, null);
    }

    @IsTest
    static void getUserJourney() {
      Set<Id> setIds = new Set<Id>();
      setIds.add([SELECT Id FROM Journey_Participant__c LIMIT 1].Id);
      Test.startTest();
      Map<Id, Journey_Participant__c> mapResult = JourneyParticipantServices.getUserJourneys(
        setIds
      );
      Test.stopTest();
      System.assertNotEquals(mapResult, null);
    }
    @IsTest
    static void getMilestoneFromJourney() {
      Set<Id> setIds = new Set<Id>();
      setIds.add([SELECT Id FROM Journey__c LIMIT 1].Id);
      Test.startTest();
      Journey__c j = JourneyParticipantServices.getMilestoneFromJourney(setIds);
      Test.stopTest();
      System.assertNotEquals(j, null);
    }

    @IsTest
    static void getUserMilestones() {
    Set<Id> setIds = new Set<Id>();
    setIds.add([SELECT Id FROM Participant_Milestone__c LIMIT 1].Id);
    Test.startTest();
    Map<Id, Participant_Milestone__c> userMilestones = JourneyParticipantServices.getUserMilestones(
      setIds
    );
    Test.stopTest();
    System.assertNotEquals(userMilestones, null);
    }

    @IsTest
    static void getParticipantMilestoneMetricTest(){
        Id participantMilestoneId = [SELECT Id FROM Participant_Milestone__c LIMIT 1].Id;
        Test.startTest();
            Participant_Milestone_Metric__c ppm = JourneyParticipantServices.getParticipantMilestoneMetric(participantMilestoneId);
        Test.stopTest();
        System.assert(ppm != null);
    }

    @IsTest
    static void getJourneyParticipantsWithMilestonesTest(){
        Id journeyId = [SELECT Id FROM Journey__c LIMIT 1].Id;
        
        Test.startTest();
            List<Journey_Participant__c> jParticipantList = JourneyParticipantServices.getJourneyParticipantsWithMilestones(new Set<Id>{journeyId});
            List<Participant_Milestone__c> journeyParticipantMilestones = new List<Participant_Milestone__c>();
            journeyParticipantMilestones = JourneyParticipantServices.getJourneyParticipantMilestones(journeyId);
        Test.stopTest();
        System.assert(jParticipantList.size() > 0);
    }
    
    @IsTest
    static void processUpdatedMilestonesTest(){
        Id journeyId = [SELECT Id FROM Journey__c LIMIT 1].Id;
        List<Milestone__c> milestoneList = [SELECT Id, Sort_Order__c, Is_Active__c, Type__c, Parent__c, RecordTypeId, Description__c,
                                            Milestone_URL__c, Start_Date__c, End_Date__c
                                            , Parent_Milestone__c, Display_In_Dashboard__c // Added by DinoBrinas [CCN973] Dec302021
                                            FROM Milestone__c LIMIT 1];
        
        Test.startTest();
            JourneyParticipantServices.processUpdatedMilestones(new Set<Id>{journeyId}, milestoneList);
        
        	List<Journey_Participant__c> lstContactUsDetails = new List<Journey_Participant__c>();
        	lstContactUsDetails.addAll(lstContactUsDetails);
        
        	Set<Id> setJIds = new Set<Id>();
        	setJIds.add(journeyId);
        	String strJ = JourneyParticipantServices.deleteJourneyPartWhereTotalMilZero(journeyId);
        Test.stopTest();
        
        Participant_Milestone__c pm = [SELECT Id, Sort_Order__c FROM Participant_Milestone__c LIMIT 1];
        System.assertEquals(milestoneList[0].Sort_Order__c, pm.Sort_Order__c);
    }
    
    @IsTest
    static void processDeletedMilestonesTest(){

        List<Milestone__c> milestoneList = [SELECT Id, Sort_Order__c, Is_Active__c, Type__c, Parent__c, RecordTypeId FROM Milestone__c LIMIT 1];
        
        Test.startTest();
          delete milestoneList;
        Test.stopTest();
    }

  @IsTest
  static void getJourneyParticipantInfo() {
    Journey_Participant__c jp = [SELECT Id FROM Journey_Participant__c LIMIT 1];

    Test.startTest();
      JourneyParticipantServices.JourneyParticipantWrapper wrapper = new JourneyParticipantServices.JourneyParticipantWrapper();
      wrapper = JourneyParticipantServices.getJourneyParticipantInfo(jp.Id);
     
    Test.stopTest();

  }

  }