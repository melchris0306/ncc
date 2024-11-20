/**
 * Created by angelorivera on 6/12/2022.
 */

global class UpdateCheckpointProgressBatch implements Database.Batchable <SObject>, Database.Stateful{
    public String strQuery;
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }

/*******************************************************************************
* @author       angelorivera
* @date         na
* @return       strResult
* @revision     27/12/2022 - angelorivera [CCN-2429]: Added journeyParticipantbyJourneyIdMap
*******************************************************************************/
    global void execute(Database.BatchableContext BC, List<SObject> participantMilestoneRecs)
    {
        List<Participant_Milestone_Metric__c> participantMilestoneMetricList = (List<Participant_Milestone_Metric__c>)participantMilestoneRecs;
        Set<Id> setMilestoneIds = new Set<Id>();
        // Start CCN-2429: Added journeyParticipantbyJourneyIdMap
        Map<Id, Set<Id>> journeyParticipantbyJourneyIdMap = new Map<Id, Set<Id>>();
        for (Participant_Milestone_Metric__c metric : participantMilestoneMetricList) {

            // get all Participant Milestone Ids
            setMilestoneIds.add(metric.Milestone__c);
            Set<Id> journeyParticipantSet = new Set<Id>();

            // get the groupings of Journey Participants by Journet Id
            if (journeyParticipantbyJourneyIdMap.containsKey(metric.Milestone__r.Journey__r.Journey__c)) {
                journeyParticipantSet.add(metric.Milestone__r.Journey__c);
                journeyParticipantbyJourneyIdMap.get(metric.Milestone__r.Journey__r.Journey__c).addAll(journeyParticipantSet);
            } else {
                journeyParticipantSet.add(metric.Milestone__r.Journey__c);
                journeyParticipantbyJourneyIdMap.put(metric.Milestone__r.Journey__r.Journey__c, new Set<Id>());
                journeyParticipantbyJourneyIdMap.get(metric.Milestone__r.Journey__r.Journey__c).addAll(journeyParticipantSet);
            }
        }

        // End CCN-2429: Added journeyParticipantbyJourneyIdMap

        if (!setMilestoneIds.isEmpty()) {
            Map<Id,Participant_Milestone__c> mapParentParticipantMilestoneById = new Map<Id, Participant_Milestone__c>();
            Set<Id> setParticipantCheckpointIds = new Set<Id>();
            Map<Id, Map<Id, Set<Id>>> mapMilestonesByCheckpointIdsByParticipantIds = new Map<Id, Map<Id, Set<Id>>>();
            for (Participant_Milestone__c participantMilestone : [SELECT Id, Name, Parent_Milestone__c, Journey__c, Progress__c, Type__c, Checkpoint_Name__c
                                                                    FROM Participant_Milestone__c
                                                                    WHERE Id IN: setMilestoneIds 
                                                                    ORDER BY Journey__c,Parent_Milestone__c, Progress__c ASC]) {

                // group parent milestone Ids by checkpoint Ids and by Participant Ids
                //if(participantMilestone.Checkpoint_Name__c != null){
                if(mapMilestonesByCheckpointIdsByParticipantIds.containsKey(participantMilestone.Journey__c)){
                    Map<Id, Set<Id>> mapMilestoneIdByCheckpoint = new Map<Id, Set<Id>>();
                    //get map of Parent Participant Milestones by Checkpoint Id
                    mapMilestoneIdByCheckpoint = mapMilestonesByCheckpointIdsByParticipantIds.get(participantMilestone.Journey__c);
                    if (mapMilestoneIdByCheckpoint.containsKey(participantMilestone.Checkpoint_Name__c)) {
                        mapMilestoneIdByCheckpoint.get(participantMilestone.Checkpoint_Name__c).add(participantMilestone.Id);
                    } else {
                        mapMilestoneIdByCheckpoint.put(participantMilestone.Checkpoint_Name__c, new Set<Id>());
                        mapMilestoneIdByCheckpoint.get(participantMilestone.Checkpoint_Name__c).add(participantMilestone.Id);
                    }
                    mapMilestonesByCheckpointIdsByParticipantIds.get(participantMilestone.Journey__c).putAll(mapMilestoneIdByCheckpoint);
                }else{
                    Map<Id, Set<Id>> mapMilestoneIdByCheckpoint = new Map<Id, Set<Id>>();
                    mapMilestoneIdByCheckpoint.put(participantMilestone.Checkpoint_Name__c, new Set<Id>());
                    mapMilestoneIdByCheckpoint.get(participantMilestone.Checkpoint_Name__c).add(participantMilestone.Id);
                    mapMilestonesByCheckpointIdsByParticipantIds.put(participantMilestone.Journey__c, new Map<Id, Set<Id>>());
                    mapMilestonesByCheckpointIdsByParticipantIds.get(participantMilestone.Journey__c).putAll(mapMilestoneIdByCheckpoint);
                }
                setParticipantCheckpointIds.add(participantMilestone.Checkpoint_Name__c);
                mapParentParticipantMilestoneById.put(participantMilestone.Id, participantMilestone);
                //}
            }
            // update checkpoint progress
            // Start CCN-2429: Added journeyParticipantbyJourneyIdMap param
            updateCheckpointPMM(journeyParticipantbyJourneyIdMap, mapParentParticipantMilestoneById, setParticipantCheckpointIds, mapMilestonesByCheckpointIdsByParticipantIds);
            // End CCN-2429: Added journeyParticipantbyJourneyIdMap
        }
    }

/*******************************************************************************
* @author       angelorivera
* @date         na
* @return       strResult
* @revision     27/12/2022 - angelorivera [CCN-2429]: Added journeyParticipantbyJourneyIdMap
*******************************************************************************/
    global static void updateCheckpointPMM(Map<Id, Set<Id>> journeyParticipantbyJourneyIdMap, Map<Id,Participant_Milestone__c> mapParticipantMilestoneById,  Set<Id> pmCheckpointIds,  Map<Id, Map<Id, Set<Id>>> mapMilestonesByCheckpointIdsByParticipantIds){
        Map<Id,List<Participant_Milestone__c>> mapParticipantCheckpointById = new Map<Id, List<Participant_Milestone__c>>();
        for(Participant_Milestone__c participantCheckpointRec : [SELECT Id, Name, Checkpoint_Progress__c, Milestone__c, Journey__c, Sort_Order__c
                                                                    FROM Participant_Milestone__c
                                                                    WHERE Milestone__c IN: pmCheckpointIds AND Is_Active__c = TRUE
                                                                    ORDER BY Journey__c, Milestone__c]){
            if(mapParticipantCheckpointById.containsKey(participantCheckpointRec.Journey__c)){
                mapParticipantCheckpointById.get(participantCheckpointRec.Journey__c).add(participantCheckpointRec);
            }else{
                mapParticipantCheckpointById.put(participantCheckpointRec.Journey__c, new List<Participant_Milestone__c>());
                mapParticipantCheckpointById.get(participantCheckpointRec.Journey__c).add(participantCheckpointRec);
            }
        }

        List<Participant_Milestone__c> listParticipantCheckpointsTobeUpdated = new List<Participant_Milestone__c>();

        // Start CCN-2429: Added new iteration for journeyParticipantbyJourneyIdMap
        // iterate through each Journey
        for(Id journeyId : journeyParticipantbyJourneyIdMap.keySet()){
            // go through each journey participant
            for(Id journeyParticipantId : journeyParticipantbyJourneyIdMap.get(journeyId)){
                Map<Id, Set<Id>> mapMilestoneIdByCheckpoint = new Map<Id, Set<Id>>();
                if(mapMilestonesByCheckpointIdsByParticipantIds.containsKey(journeyParticipantId)){
                    // get map of Parent Participant Milestones by Checkpoint Id
                    mapMilestoneIdByCheckpoint = mapMilestonesByCheckpointIdsByParticipantIds.get(journeyParticipantId);

                    // go through each checkpoint
                    for(Id checkpointId : mapMilestoneIdByCheckpoint.keySet()){
                        Set<Id> setParentMilestoneIds = new Set<Id>();
                        // get all Parent Milestone Ids
                        setParentMilestoneIds.addAll(mapMilestoneIdByCheckpoint.get(checkpointId));

                        // go through all parent milestone linked to the current checkpoint in the iteration
                        Double tempProgress = 0;
                        Double iCtr = 0;
                        System.debug(LoggingLevel.DEBUG,'@@@@@ Checkpoint : ' + checkpointId);

                        // go through each parent participant milestone
                        for(Id parentMilestoneId : setParentMilestoneIds){
                            if(mapParticipantMilestoneById.containsKey(parentMilestoneId)){
                                // get the progress of the parent milestones
                                tempProgress = tempProgress + mapParticipantMilestoneById.get(parentMilestoneId).Progress__c;
                                System.debug(LoggingLevel.DEBUG,'@@@@@ Progress: ' + mapParticipantMilestoneById.get(parentMilestoneId).Progress__c);
                                iCtr++;
                            }
                        }
                        System.debug(LoggingLevel.DEBUG,'@@@@@ tempProgress: ' + tempProgress);
                        System.debug(LoggingLevel.DEBUG,'@@@@@ Number of milestones: ' + iCtr);

                        // update the progress of the checkpoint
                        for(Participant_Milestone__c pm : mapParticipantCheckpointById.get(journeyParticipantId)){
                            if(pm.Milestone__c == checkpointId){
                                Double dProgress = tempProgress/iCtr;
                                System.debug(LoggingLevel.DEBUG,'@@@@@ dProgress: ' + dProgress);
                                pm.Checkpoint_Progress__c = dProgress;
                                System.debug(LoggingLevel.DEBUG,'@@@@@ Participant_Milestone__c: ' + pm.Checkpoint_Progress__c);
                                listParticipantCheckpointsTobeUpdated.add(pm);
                            }
                        }
                    }
                }
            }
            // End CCN-2429: Added new iteration for journeyParticipantbyJourneyIdMap
        }
        if(!listParticipantCheckpointsTobeUpdated.isEmpty()){
            Database.update(listParticipantCheckpointsTobeUpdated);
        }
    }

    global void finish(Database.BatchableContext bc){

    }
}