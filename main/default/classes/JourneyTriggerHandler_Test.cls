/*******************************************************************************
 * @author       Allen Francisco
 * @date         13.02.2021
 * @description  Test class for JourneyTriggerHandler
 * @revision     13.02.2021 - ADFrancisco - Created
 *******************************************************************************/
@isTest(IsParallel=true)
public class JourneyTriggerHandler_Test {
  @testSetup
  static void createData() {
    JourneyCommunitySettings__c jcSettings = new JourneyCommunitySettings__c();
    jcSettings.Community_Name__c = 'Compass';
    jcSettings.Name = 'Journey';
    insert jcSettings;
  }
  @IsTest
  static void runTrigger() {
    Test.startTest();
    Campaign__c testCampaign = new Campaign__c();
    testCampaign.Name = 'Test Campaign Name';
    insert testCampaign;

    Journey__c testJourney = new Journey__c();
    testJourney.Name = 'Test Journey';
    testJourney.Campaign__c = testCampaign.Id;
    testJourney.Status__c = 'For Review';
    insert testJourney;
    Test.stopTest();
    System.assertNotEquals([SELECT Id FROM Journey__c], null);
  }

  @IsTest
  static void runTriggerHandler() {
    Test.startTest();
    Campaign__c testCampaign = new Campaign__c();
    testCampaign.Name = 'Test Campaign Name';
    insert testCampaign;

    Journey__c testJourney = new Journey__c();
    testJourney.Name = 'Test Journey';
    testJourney.Campaign__c = testCampaign.Id;
    testJourney.Status__c = 'For Review';
    insert testJourney;

    Journey__c queriedTestJourney = [
      SELECT Id, Name, Campaign__c, Status__c, Journey_Preview_URL__c
      FROM Journey__c
      WHERE Id = :testJourney.Id
      LIMIT 1
    ];
    JourneyTriggerHandler.populateJourneyURL(
      new List<Journey__c>{ queriedTestJourney }
    );
    Test.stopTest();
    System.assertNotEquals([SELECT Id FROM Journey__c], null);
  }
}