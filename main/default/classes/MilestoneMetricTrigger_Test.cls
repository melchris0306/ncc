/*******************************************************************************
 * @author       Kyzer Buhay
 * @date         05/04/2021
 * @description  Test class for MilestoneMetricTrigger/Handler
 *******************************************************************************/
@IsTest(IsParallel=true)
public class MilestoneMetricTrigger_Test {
  @testSetup
  static void createData() {
    Campaign__c testCampaign = new Campaign__c();
    testCampaign.Name = 'Test Campaign Name';
    insert testCampaign;

    Journey__c testJourney = new Journey__c();
    testJourney.Name = 'Test Journey';
    testJourney.Campaign__c = testCampaign.Id;
    testJourney.Status__c = 'Approved';
    insert testJourney;
  }
  @isTest
  static void insertMilestoneMetric() {
    Test.startTest();
    Journey__c testJourney = [
      SELECT Id, Name
      FROM Journey__c
      WHERE Name = 'Test Journey'
      LIMIT 1
    ];

    Milestone_Metric__c mMetric = new Milestone_Metric__c();
    mMetric.Journey__c = testJourney.Id;
    mMetric.Type__c = 'Communication';
    insert mMetric;
    Test.stopTest();
    System.assertNotEquals([SELECT Id FROM Milestone_Metric__c], null);
  }

  @isTest
  static void deleteMilestoneMetric() {
    Test.startTest();
    Journey__c testJourney = [
      SELECT Id, Name
      FROM Journey__c
      WHERE Name = 'Test Journey'
      LIMIT 1
    ];

    Milestone_Metric__c mMetric = new Milestone_Metric__c();
    mMetric.Journey__c = testJourney.Id;
    mMetric.Type__c = 'Communication';
    insert mMetric;

    delete mMetric;
    Test.stopTest();
    System.assertNotEquals([SELECT Id FROM Milestone_Metric__c], null);
  }
}