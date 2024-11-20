/**
 * Created by angelorivera on 4/1/2022.
 */

public without sharing class ParticipantMilestoneMetricTriggerHandler {
    /*******************************************************************************
     * @description  handles all after insert events.
     * @param        newMap - Trigger.newMap context variable
     * @revision     04.01.2022 - APRivera - Created
     *******************************************************************************/
    public static void handleAfterUpdate(Map<Id, Participant_Milestone_Metric__c> newMap) {
        processParticipantMilestonesMetric(newMap);
    }


    /*******************************************************************************
     * @author       Angelo Rivera
     * @date         04.01.2022
     * @description  Process inserted Milestones metrics
     * @param        newMap - map of the new records
     * @revision     04.01.2022 - APRivera - Created
     * @revision     25.11.2022 - APRivera - Fix - CCN-2243
     * @version      07-12-2022 - APRivera - CCN-2355 - Fixed Checkpoint progress calculation
     *******************************************************************************/
    public static void processParticipantMilestonesMetric(Map<Id, Participant_Milestone_Metric__c> newMap) {
        Map<Id, List<Participant_Milestone_Metric__c>> mapMetricsByParticipantMilestoneIds = new Map<Id, List<Participant_Milestone_Metric__c>>();

        for (Participant_Milestone_Metric__c metric : newMap.values()) {
            //group metrics by participant milestone Ids
            if (mapMetricsByParticipantMilestoneIds.containsKey(metric.Milestone__c)) {
                mapMetricsByParticipantMilestoneIds.get(metric.Milestone__c).add(metric);
            } else {
                mapMetricsByParticipantMilestoneIds.put(metric.Milestone__c, new List<Participant_Milestone_Metric__c>());
                mapMetricsByParticipantMilestoneIds.get(metric.Milestone__c).add(metric);
            }
        }

        if (!mapMetricsByParticipantMilestoneIds.isEmpty()) {
            Map<Id, Map<Id, List<Participant_Milestone__c>>> mapParticipantMilestonesByParticipantIds = new Map<Id, Map<Id, List<Participant_Milestone__c>>>();
            Set<Id> setParentParticipantMilestonesIds = new Set<Id>();
            Set<Id> setJourneyParticipantIds = new Set<Id>();

            for (Participant_Milestone__c participantMilestone : [SELECT Id, Name, Parent_Milestone__c, Journey__c, Progress__c, Type__c, Checkpoint_Name__c, Milestone_Status__c
                                                                    FROM Participant_Milestone__c
                                                                    WHERE Id IN: mapMetricsByParticipantMilestoneIds.keySet()
                                                                    ORDER BY Journey__c,Parent_Milestone__c, Progress__c ASC]) {
                // check if participant milestone has a parent
                // make sure that only child milestone will be processed
                if (participantMilestone.Parent_Milestone__c != null) {
                    // process participant milestones with parent (child participant milestones)
                    setJourneyParticipantIds.add(participantMilestone.Journey__c);
                    setParentParticipantMilestonesIds.add(participantMilestone.Parent_Milestone__c);
                    //group child participant milestone by Parent Milestones by Journey Participants
                    if(mapParticipantMilestonesByParticipantIds.containsKey(participantMilestone.Journey__c)){
                        Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByParentMilestoneIds = new Map<Id, List<Participant_Milestone__c>>();
                        mapParticipantMilestonesByParentMilestoneIds = mapParticipantMilestonesByParticipantIds.get(participantMilestone.Journey__c);
                        if (mapParticipantMilestonesByParentMilestoneIds.containsKey(participantMilestone.Parent_Milestone__c)) {
                            mapParticipantMilestonesByParentMilestoneIds.get(participantMilestone.Parent_Milestone__c).add(participantMilestone);
                        } else {
                            mapParticipantMilestonesByParentMilestoneIds.put(participantMilestone.Parent_Milestone__c, new List<Participant_Milestone__c>());
                            mapParticipantMilestonesByParentMilestoneIds.get(participantMilestone.Parent_Milestone__c).add(participantMilestone);
                        }
                        mapParticipantMilestonesByParticipantIds.get(participantMilestone.Journey__c).putAll(mapParticipantMilestonesByParentMilestoneIds);
                    }else{
                        Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByParentMilestoneIds = new Map<Id, List<Participant_Milestone__c>>();
                        mapParticipantMilestonesByParentMilestoneIds.put(participantMilestone.Parent_Milestone__c, new List<Participant_Milestone__c>());
                        mapParticipantMilestonesByParentMilestoneIds.get(participantMilestone.Parent_Milestone__c).add(participantMilestone);
                        mapParticipantMilestonesByParticipantIds.put(participantMilestone.Journey__c, new Map<Id, List<Participant_Milestone__c>>());
                        mapParticipantMilestonesByParticipantIds.get(participantMilestone.Journey__c).putAll(mapParticipantMilestonesByParentMilestoneIds);
                    }
                }
            }

            if(!mapParticipantMilestonesByParticipantIds.isEmpty()){
                // retrieve parent milestones and its metrics
                Map<Id, Map<Id, List<Participant_Milestone_Metric__c>>> mapMetricsByMilestonesIdsByParticipantIds = new Map<Id,Map<Id, List<Participant_Milestone_Metric__c>>>();
                Map<Id, Participant_Milestone__c> mapParticipantMilestoneByIds = new Map<Id, Participant_Milestone__c>();
                for(Participant_Milestone__c parentParticipantMilestone : [SELECT Id, Journey__c, Milestone__c, Progress__c, Milestone_Status__c,
                                                                            (SELECT Id, Metric_Used__c, Completion_Date__c FROM Participant_Milestone_Metrics__r)
                                                                            FROM Participant_Milestone__c
                                                                            WHERE Milestone__c IN: setParentParticipantMilestonesIds
                                                                            AND Journey__c IN: setJourneyParticipantIds
                                                                            ORDER BY Journey__c, Progress__c ASC]){
                    if(!parentParticipantMilestone.Participant_Milestone_Metrics__r.isEmpty()){
                        mapParticipantMilestoneByIds.put(parentParticipantMilestone.Id, parentParticipantMilestone);
                        // group Parent milestones and metrics by Journey Participants
                        if(mapMetricsByMilestonesIdsByParticipantIds.containsKey(parentParticipantMilestone.Journey__c)){
                            Map<Id, List<Participant_Milestone_Metric__c>> mapMetricsByParentParticipantMilestoneIds = new Map<Id, List<Participant_Milestone_Metric__c>>();
                            mapMetricsByParentParticipantMilestoneIds = mapMetricsByMilestonesIdsByParticipantIds.get(parentParticipantMilestone.Journey__c);
                            mapMetricsByParentParticipantMilestoneIds.put(parentParticipantMilestone.Id, new List<Participant_Milestone_Metric__c>());
                            mapMetricsByParentParticipantMilestoneIds.get(parentParticipantMilestone.Id).addAll(parentParticipantMilestone.Participant_Milestone_Metrics__r);
                            mapMetricsByMilestonesIdsByParticipantIds.get(parentParticipantMilestone.Journey__c).putAll(mapMetricsByParentParticipantMilestoneIds);
                        }else{
                            mapMetricsByMilestonesIdsByParticipantIds.put(parentParticipantMilestone.Journey__c, new  Map<Id, List<Participant_Milestone_Metric__c>>());
                            Map<Id, List<Participant_Milestone_Metric__c>> mapMetricsByParentParticipantMilestoneIds = new Map<Id, List<Participant_Milestone_Metric__c>>();
                            mapMetricsByParentParticipantMilestoneIds.put(parentParticipantMilestone.Id, new List<Participant_Milestone_Metric__c>());
                            mapMetricsByParentParticipantMilestoneIds.get(parentParticipantMilestone.Id).addAll(parentParticipantMilestone.Participant_Milestone_Metrics__r);
                            mapMetricsByMilestonesIdsByParticipantIds.get(parentParticipantMilestone.Journey__c).putAll(mapMetricsByParentParticipantMilestoneIds);
                        }
                    }
                }

                if(!mapMetricsByMilestonesIdsByParticipantIds.isEmpty()){
                    List<Participant_Milestone_Metric__c> lstParticipantMilestoneMetricsToBeUpdated = new List<Participant_Milestone_Metric__c>();
                    Set<Id> setParticipantMilestoneIds = new Set<Id>();
                    // iterate over Journey participants
                    for(Id journeyParticipantId : mapMetricsByMilestonesIdsByParticipantIds.keySet()){
                        Map<Id, List<Participant_Milestone_Metric__c>> mapMetricsOfParentParticipantMilestoneIds = mapMetricsByMilestonesIdsByParticipantIds.get(journeyParticipantId);

                        // go through each parent participant milestone related the Journey Participant in the iteration
                        for(Id parentParticipantMilestoneId : mapMetricsOfParentParticipantMilestoneIds.keySet()){
                            List<Participant_Milestone_Metric__c> lstParentParticipantMilestoneMetrics = new List<Participant_Milestone_Metric__c>();

                            // get the participant milestone metrics of the parent milestone related the Journey Participant in the iteration
                            lstParentParticipantMilestoneMetrics = mapMetricsOfParentParticipantMilestoneIds.get(parentParticipantMilestoneId);

                            Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByJourneyParticipantIds = new Map<Id, List<Participant_Milestone__c>>();
                            List<Participant_Milestone__c> lstChildParticipantMilestones = new List<Participant_Milestone__c>();
                            // get the list of child milestones related the Journey Participant in the iteration
                            if(mapParticipantMilestonesByParticipantIds.containsKey(journeyParticipantId)){
                                mapParticipantMilestonesByJourneyParticipantIds = mapParticipantMilestonesByParticipantIds.get(journeyParticipantId);

                                // retrieve parent participant milestone record to get the corresponding milestone
                                Participant_Milestone__c parentMilestone = new Participant_Milestone__c();
                                parentMilestone = mapParticipantMilestoneByIds.get(parentParticipantMilestoneId);

                                if(mapParticipantMilestonesByJourneyParticipantIds.containsKey(parentMilestone.Milestone__c)){
                                    // get all child participant milestones of the Parent Participant milestone in the iteration
                                    lstChildParticipantMilestones = mapParticipantMilestonesByJourneyParticipantIds.get(parentMilestone.Milestone__c);

                                    // go through each Child Participant Milestone related the Journey Participant in the iteration
                                    for(Participant_Milestone__c childParticipantMilestone : lstChildParticipantMilestones){
                                        List<Participant_Milestone_Metric__c> lstChildParticipantMilestoneMetrics = new List<Participant_Milestone_Metric__c>();
                                        // get metrics of the child milestone
                                        if(mapMetricsByParticipantMilestoneIds.containsKey(childParticipantMilestone.Id)){
                                            lstChildParticipantMilestoneMetrics = mapMetricsByParticipantMilestoneIds.get(childParticipantMilestone.Id);
                                            Map<String, Participant_Milestone_Metric__c> mapMetricsByMetricUsed = new Map<String, Participant_Milestone_Metric__c>();
                                            for(Participant_Milestone_Metric__c pmm : lstChildParticipantMilestoneMetrics){
                                                // only roll up metrics to Parent Milestone if Participant Milestone Status != 'Missed' and Metric used != 'Registration Date'
                                                if(pmm.Metric_Used__c != 'Registration Date'){
                                                    mapMetricsByMetricUsed.put(pmm.Metric_Used__c, pmm);
                                                } else {
                                                    if(childParticipantMilestone.Milestone_Status__c != 'Missed'){
                                                        mapMetricsByMetricUsed.put(pmm.Metric_Used__c, pmm);
                                                    }
                                                }
                                            }

                                            // go through each Metric of Parent Participant Milestone
                                            if(!lstParentParticipantMilestoneMetrics.isEmpty()){
                                                for(Participant_Milestone_Metric__c pmm : lstParentParticipantMilestoneMetrics){
                                                    if(mapMetricsByMetricUsed.containsKey(pmm.Metric_Used__c)){
                                                        // update the metric of the parent participant milestone
                                                        pmm.Completion_Date__c = mapMetricsByMetricUsed.get(pmm.Metric_Used__c).Completion_Date__c;
                                                        if(!setParticipantMilestoneIds.contains(pmm.Id)) {
                                                            lstParticipantMilestoneMetricsToBeUpdated.add(pmm);
                                                            setParticipantMilestoneIds.add(pmm.Id);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if(!lstParticipantMilestoneMetricsToBeUpdated.isEmpty()){
                        System.debug(LoggingLevel.DEBUG, '!@#$ Parent Metrics To Be Completed : ' + lstParticipantMilestoneMetricsToBeUpdated);
                        Database.update(lstParticipantMilestoneMetricsToBeUpdated);
                    }
            
                }
            }
        }
    }
}