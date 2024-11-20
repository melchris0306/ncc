/**
 * Created by angelorivera on 19.03.2021.
 */

public with sharing class MilestoneMetricTriggerHandler {
  /*******************************************************************************
   * @description  handles all after insert events.
   * @param        newMap - Trigger.newMap context variable
   * @revision     19.03.2021 - APRivera - Created
   *******************************************************************************/
  public static void handleAfterInsert(Map<Id, Milestone_Metric__c> newMap) {
    processMilestonesMetric(newMap, 'INSERT');
  }

  /*******************************************************************************
   * @description  handles all after delete events.
   * @param        oldMap - Trigger.oldMap context variable
   * @revision     19.03.2021 - APRivera - Created
   *******************************************************************************/
  public static void handleAfterDelete(Map<Id, Milestone_Metric__c> oldMap) {
    processMilestonesMetric(oldMap, 'DELETE');
  }

  /*******************************************************************************
   * @author       Angelo Rivera
   * @date         19.03.2021
   * @description  Process inserted Milestones metrics
   * @param        newMap - map of the new records
   * @param        evt - trigger event
   * @revision     19.03.2021 - APRivera - Created
   *******************************************************************************/
  public static void processMilestonesMetric(
    Map<Id, Milestone_Metric__c> newMap,
    String evt
  ) {
    List<Milestone_Metric__c> lstMetrics = new List<Milestone_Metric__c>();
    Set<Id> setJourneyIds = new Set<Id>();
    Set<String> setMetricType = new Set<String>();
    for (Milestone_Metric__c metric : newMap.values()) {
      if (metric.Journey__c != null) {
        setJourneyIds.add(metric.Journey__c);
        lstMetrics.add(metric);
        setMetricType.add(metric.Type__c);
      }
    }

    if (!setJourneyIds.isEmpty()) {
      JourneyParticipantServices.processMilestoneMetric(
        setJourneyIds,
        lstMetrics,
        setMetricType,
        evt
      );
    }
  }
}