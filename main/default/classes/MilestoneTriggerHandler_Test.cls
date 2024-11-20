/*******************************************************************************
 * @author       Allen Francisco
 * @date         13.02.2021
 * @description  Test class for MilestoneTriggerHandler
 * @revision     13.02.2021 - ADFrancisco - Created
 *******************************************************************************/
@isTest(IsParallel=true)
public class MilestoneTriggerHandler_Test {
  @IsTest
  static void runTrigger() {
    Campaign__c testCampaign = new Campaign__c();
    testCampaign.Name = 'Test Campaign Name';
    insert testCampaign;

    Journey__c testJourneyA = new Journey__c();
    testJourneyA.Name = 'Test Journey A';
    testJourneyA.Campaign__c = testCampaign.Id;
    testJourneyA.Status__c = 'For Review';
    insert testJourneyA;

    Id recordTypeId = Schema.SObjectType.Milestone__c.getRecordTypeInfosByDeveloperName()
      .get('Checkpoint')
      .getRecordTypeId();
    Test.startTest();
    Milestone__c testMilestoneA = new Milestone__c();
    testMilestoneA.Journey__c = testJourneyA.Id;
    testMilestoneA.Name = 'Test Milestone A';
    testMilestoneA.Type__c = 'Communication';
    testMilestoneA.RecordTypeId = recordTypeId;
    testMilestoneA.Is_Active__c = true;
    insert testMilestoneA;

    Milestone__c testMilestoneB = new Milestone__c();
    testMilestoneB.Parent__c = testMilestoneA.Id;
    testMilestoneB.Journey__c = testJourneyA.Id;
    testMilestoneB.Name = 'Test Milestone B';
    testMilestoneB.Type__c = 'Communication';
    insert testMilestoneB;

    //Added by Kyzer Buhay 05/03/2021
    Milestone__c testInsertedMilestone = [
      SELECT Id, Name
      FROM Milestone__c
      WHERE Id = :testMilestoneB.Id
      LIMIT 1
    ];
    testInsertedMilestone.Name = 'Test Milestone C';
    update testInsertedMilestone;

    delete testInsertedMilestone;
    Test.stopTest();

    System.assertNotEquals([SELECT Id FROM Milestone__c], null);
  }
}