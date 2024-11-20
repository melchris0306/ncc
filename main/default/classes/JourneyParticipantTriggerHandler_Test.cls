/*******************************************************************************
 * @author       Allen Francisco
 * @date         13.02.2021
 * @description  Test class for JourneyParticipantTriggerHandler
 * @revision     13.02.2021 - ADFrancisco - Created
 *******************************************************************************/
@isTest(IsParallel=true)
public class JourneyParticipantTriggerHandler_Test {
  @IsTest
  static void runTrigger() {
    Campaign__c testCampaign = new Campaign__c();
    testCampaign.Name = 'Test Campaign Name';

    insert testCampaign;

    Journey__c testJourney = new Journey__c();
    testJourney.Name = 'Test Journey';
    testJourney.Campaign__c = testCampaign.Id;
    testJourney.Status__c = 'For Review';
    insert testJourney;

    Test.startTest();
    Journey_Participant__c testParticipant = new Journey_Participant__c();
    testParticipant.Journey__c = testJourney.Id;
    insert testParticipant;
    Test.stopTest();
    System.assertNotEquals([SELECT Id FROM Journey_Participant__c], null);
  }
}