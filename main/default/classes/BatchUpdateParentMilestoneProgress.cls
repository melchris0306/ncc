/*******************************************************************************
 * @author       Angelo Rivera
 * @date         22.07.2022
 * @description  CCN-JOU-1799-DV - Updated Parent Milestone's Progress
 * @revision     22.07.2022- APRivera - Created
 *******************************************************************************/

global class BatchUpdateParentMilestoneProgress implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

    public String strQuery = '';
    global Set<Id> setJourneyIds = new Set<Id>(); // Start/End 1/17/2023 CCN-2431 Von Pernicia: added variable to insert record in BatchProcessor
    global Database.QueryLocator start(Database.BatchableContext BC) {
        strQuery = 'SELECT Journey__r.Journey__c, Journey__r.Name, Journey__r.Journey__r.Name, Id, Name, Journey__c, Milestone__c, Contact__r.Name, Contact__c, ' +
                'Milestone_Status__c, Parent_Milestone__c, Parent_Milestone__r.Name, Parent_Milestone__r.Session_Catch_Up_Start_Date__c, ' +
                '(SELECT Id, Name, Metric_Used__c, Completion_Date__c FROM Participant_Milestone_Metrics__r ' +
                'WHERE Metric_Used__c = \'Registration Date\' AND Completion_Date__c != NULL) ' +
                'FROM Participant_Milestone__c ' +
                'WHERE Milestone_Status__c = \'Missed\' ' +
                'AND Parent_Milestone__c != NULL ' +
                'AND Parent_Milestone__r.Session_Catch_Up_Start_Date__c = NULL ' +
            	// Start 1/25/2023 CCN-2517 Von Pernicia: added new filter to pull the active journey
            	'AND Journey__r.Journey__r.End_Date__c >= TODAY'; 
        		// End 1/25/2023 CCN-2517 Von Pernicia: added new filter to pull the active journey

        System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<Participant_Milestone__c> lstMilestones = (List<Participant_Milestone__c>) scope;
        if (!lstMilestones.isEmpty()) {

            // Variable Declarations
            Map<Id, Map<Id, List<Participant_Milestone__c>>> mapParticipantMilestonesByJourneyPartIdsByJourneyIds = new Map<Id, Map<Id, List<Participant_Milestone__c>>>();
            //journeyIds = new Set<String>(); // Start/End 1/17/2023 CCN-2431 Von Pernicia: added variable to insert record in BatchProcessor
            Set<Id> setParentMilestoneIds = new Set<Id>();
            Set<Id> setParticipantIds = new Set<Id>();
            //Set<Id> setJourneyIds = new Set<Id>();
            //setJourneyIds = new Set<Id>();


            // iterate over the list of participant milestones
            for (Participant_Milestone__c pm : lstMilestones) {

                // consolidate Journey Ids
                setJourneyIds.add(pm.Journey__r.Journey__c);

                // consolidate the parent milestones in a set
                setParentMilestoneIds.add(pm.Parent_Milestone__c);

                //create contact Ids set
                setParticipantIds.add(pm.Journey__c);

                // check if journey id exists on the map
                if (!mapParticipantMilestonesByJourneyPartIdsByJourneyIds.containsKey(pm.Journey__r.Journey__c)) {
                    // if not existing, create new map for the journey
                    mapParticipantMilestonesByJourneyPartIdsByJourneyIds.put(pm.Journey__r.Journey__c, new Map<Id, List<Participant_Milestone__c>>());

                    // create the map for the journey participant and add the participant milestone to the list
                    Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();
                    mapParticipantMilestonesByParticipantIds.put(pm.Journey__c, new List<Participant_Milestone__c>());
                    mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);

                    // populate the map of Journey and map of journey participants and participant milestones
                    mapParticipantMilestonesByJourneyPartIdsByJourneyIds.get(pm.Journey__r.Journey__c).putAll(mapParticipantMilestonesByParticipantIds);

                }
                else {
                    // if journey id exists on the map, get the map value = Map<Id,List<Participant_Milestone__c>>
                    Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();
                    mapParticipantMilestonesByParticipantIds = mapParticipantMilestonesByJourneyPartIdsByJourneyIds.get(pm.Journey__r.Journey__c);

                    // check if journey participant id exists on the map
                    if (!mapParticipantMilestonesByParticipantIds.containsKey(pm.Journey__c)) {
                        // if not existing, create the map for the journey participant and add the participant milestone to the list
                        mapParticipantMilestonesByParticipantIds.put(pm.Journey__c, new List<Participant_Milestone__c>());
                        mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);
                    } else {
                        // if existing, get the existing map of participant and add the participant milestone to the list
                        mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);
                    }

                    // populate the map of Journey and map of journey participants and participant milestones
                    mapParticipantMilestonesByJourneyPartIdsByJourneyIds.get(pm.Journey__r.Journey__c).putAll(mapParticipantMilestonesByParticipantIds);
                }
            }

            // variable declarations
            Map<Id, Map<Id,List<Participant_Milestone__c>>> mapChildParticipantMilestonesByParticipantByParentMilestoneIds = new Map<Id, Map<Id, List<Participant_Milestone__c>>>();

            // retrieve all child milestones that are not missed yet  (either 'Upcoming' or 'On-Going' or 'Completed')
            for (Participant_Milestone__c pm : [SELECT Id, Journey__r.Journey__c, Parent_Milestone__c, Child_Milestone__c,
                                                Journey__c, Milestone_Status__c, Milestone_Completed__c, Milestone__c,
                                                (SELECT Id, Metric_Used__c, Completion_Date__c FROM Participant_Milestone_Metrics__r
                                                    WHERE Metric_Used__c = 'Registration Date' AND Completion_Date__c != NULL)
                                                    FROM Participant_Milestone__c
                                                        WHERE Journey__c IN: setParticipantIds
                                                        AND Parent_Milestone__c IN: setParentMilestoneIds
                                                        AND Child_Milestone__c = TRUE
                                                        AND Journey__r.Journey__c IN: setJourneyIds
                                                        AND Milestone_Status__c != 'Missed']) {

                // create map of Participant milestones by Participant Ids by Parent Milestone (Milestone__c)
                // check if Parent milestone exists in the map
                if(!mapChildParticipantMilestonesByParticipantByParentMilestoneIds.containsKey(pm.Parent_Milestone__c)){

                    // if not, put parent milestone key on the map
                    mapChildParticipantMilestonesByParticipantByParentMilestoneIds.put(pm.Parent_Milestone__c, new Map<Id,List<Participant_Milestone__c>>());

                    // initialize the list
                    Map<Id,List<Participant_Milestone__c>> mapParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();

                    // create map of participant milestone by Participant id as key
                    mapParticipantMilestonesByParticipantIds.put(pm.Journey__c, new List<Participant_Milestone__c>());
                    mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);

                    mapChildParticipantMilestonesByParticipantByParentMilestoneIds.get(pm.Parent_Milestone__c).putAll(mapParticipantMilestonesByParticipantIds);

                }
                else{
                    // initialize map of Participant milestone by Participant id as key
                    Map<Id,List<Participant_Milestone__c>> mapParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();

                    // get map value (Participant milestone by Participant id) of Parent Milestone Key
                    mapParticipantMilestonesByParticipantIds = mapChildParticipantMilestonesByParticipantByParentMilestoneIds.get(pm.Parent_Milestone__c);

                    // check if Journey participant exist as key in Map
                    if(!mapParticipantMilestonesByParticipantIds.containsKey(pm.Journey__c)){
                        // If not, create entry on map and add the participant milestone
                        mapParticipantMilestonesByParticipantIds.put(pm.Journey__c, new List<Participant_Milestone__c>());
                        mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);
                    }else{
                        // get the existing key (Journey Participant) and add the participant milestone to it.
                        mapParticipantMilestonesByParticipantIds.get(pm.Journey__c).add(pm);
                    }

                    mapChildParticipantMilestonesByParticipantByParentMilestoneIds.get(pm.Parent_Milestone__c).putAll(mapParticipantMilestonesByParticipantIds);
                }
            }

            // variable declaration
            // map of child participant milestones by Participant Id where parent participant milestone progress needs to be updated
            Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByIdsByParticipants = new Map<Id, List<Participant_Milestone__c>>();

            // go through each journey
            for(Id journeyId : mapParticipantMilestonesByJourneyPartIdsByJourneyIds.keySet()){

                Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();
                mapParticipantMilestonesByParticipantIds = mapParticipantMilestonesByJourneyPartIdsByJourneyIds.get(journeyId);

                // iterate over each journey participant
                for(Id participantId : mapParticipantMilestonesByParticipantIds.keySet()){

                    // iterate over each child milestone that was missed by the participant
                    for(Participant_Milestone__c pm : mapParticipantMilestonesByParticipantIds.get(participantId)){

                        // checks if there is a Metric_Used__c = 'Registration Date' AND Completion_Date__c != NULL
                        // this means the participant registered but did not attended, hence missed the session
                        if(!pm.Participant_Milestone_Metrics__r.isEmpty()){

                            // get map value (Child Participant milestone by Participant id) of Parent Milestone Key
                            Map<Id,List<Participant_Milestone__c>> mapChildParticipantMilestonesByParticipantIds = new Map<Id, List<Participant_Milestone__c>>();
                            if(!mapChildParticipantMilestonesByParticipantByParentMilestoneIds.isEmpty() && mapChildParticipantMilestonesByParticipantByParentMilestoneIds.containsKey(pm.Parent_Milestone__c)){
                                mapChildParticipantMilestonesByParticipantIds.putAll(mapChildParticipantMilestonesByParticipantByParentMilestoneIds.get(pm.Parent_Milestone__c));

                                // get the list of child participant milestones of the current journey participant in the iteration
                                List<Participant_Milestone__c> lstUpcomingOnGoingChildParticipantMilestones = new List<Participant_Milestone__c>();
                                if(!mapChildParticipantMilestonesByParticipantIds.isEmpty() && mapChildParticipantMilestonesByParticipantIds.containsKey(participantId)){
                                    lstUpcomingOnGoingChildParticipantMilestones.addAll(mapChildParticipantMilestonesByParticipantIds.get(participantId));

                                    // check if the there are one or more than one child participant milestone
                                    // this means the missed child participant milestone has a sibling that is either 'Upcoming' or 'On-Going' or 'Completed'
                                    if(!lstUpcomingOnGoingChildParticipantMilestones.isEmpty()){
                                        Boolean bHasRegistration = false;
                                        for(Participant_Milestone__c participantMilestone : lstUpcomingOnGoingChildParticipantMilestones){
                                            // check the participant's registration through the metrics
                                            if(!participantMilestone.Participant_Milestone_Metrics__r.isEmpty()){
                                                bHasRegistration = true;
                                            }
                                        }
                                        if(!bHasRegistration){
                                            // this means the participant has not registered to a session yet
                                            // put the Participant_Milestone__c pm to map, its parent milestone's progress will need to be updated
                                            if(!mapParticipantMilestonesByIdsByParticipants.containsKey(participantId)){
                                                mapParticipantMilestonesByIdsByParticipants.put(participantId, new List<Participant_Milestone__c>());
                                                mapParticipantMilestonesByIdsByParticipants.get(participantId).add(pm);
                                            }
                                            else{
                                                mapParticipantMilestonesByIdsByParticipants.get(participantId).add(pm);
                                            }
                                            bHasRegistration = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // variable declarations
            Map<Id, Map<Id,List<Participant_Milestone_Metric__c>>> mapParticipantMilestoneMetricsByParentMilestoneIdsByMilestoneIds = new Map<Id, Map<Id,List<Participant_Milestone_Metric__c>>>();
            Map<Id, Participant_Milestone__c> mapParentParticipantMilestonesByIds = new Map<Id, Participant_Milestone__c>();
            Map<Id, Id> mapMetricJourneyId = new Map<Id, Id>();
            // retrieve participant milestones and its metrics that are tagged as parent milestones
            for(Participant_Milestone__c pm : [SELECT Id, Name, Milestone__c, Journey__c, Journey__r.Journey__c, Parent_Milestone__c, 
                                                (SELECT Id, Metric_Used__c, Completion_Date__c, Milestone__r.Journey__r.Journey__c FROM Participant_Milestone_Metrics__r)
                                                FROM Participant_Milestone__c
                                                WHERE Milestone__c IN: setParentMilestoneIds
                                                AND Journey__c IN: setParticipantIds
                                                AND Journey__r.Journey__c IN: setJourneyIds
                                                AND Parent_Milestone__c = NULL]){

                // create map of Participant Milestone Metrics by Parent Participant Milestone Id by Milestone Id
                if(!mapParticipantMilestoneMetricsByParentMilestoneIdsByMilestoneIds.containsKey(pm.Milestone__c)){
                    mapParticipantMilestoneMetricsByParentMilestoneIdsByMilestoneIds.put(pm.Milestone__c, new Map<Id,List<Participant_Milestone_Metric__c>>());

                    Map<Id,List<Participant_Milestone_Metric__c>> mapMilestoneMetricsByParentMilestones = new Map<Id, List<Participant_Milestone_Metric__c>>();
                    mapMilestoneMetricsByParentMilestones.put(pm.Id, new List<Participant_Milestone_Metric__c>());
                    mapMilestoneMetricsByParentMilestones.get(pm.Id).addAll(pm.Participant_Milestone_Metrics__r);

                    mapParticipantMilestoneMetricsByParentMilestoneIdsByMilestoneIds.get(pm.Milestone__c).putAll(mapMilestoneMetricsByParentMilestones);
                }
                else{
                    Map<Id,List<Participant_Milestone_Metric__c>> mapMilestoneMetricsByParentMilestones = new Map<Id, List<Participant_Milestone_Metric__c>>();
                    mapMilestoneMetricsByParentMilestones.put(pm.Id, new List<Participant_Milestone_Metric__c>());
                    mapMilestoneMetricsByParentMilestones.get(pm.Id).addAll(pm.Participant_Milestone_Metrics__r);

                    mapParticipantMilestoneMetricsByParentMilestoneIdsByMilestoneIds.get(pm.Milestone__c).putAll(mapMilestoneMetricsByParentMilestones);
                }
                mapParentParticipantMilestonesByIds.put(pm.Id, pm);
            }

            // variable declaration
            // list of Participant Milestone Metrics to be updated
            List<Participant_Milestone_Metric__c> lstParticipantMilestoneMetricsToBeUpdated = new List<Participant_Milestone_Metric__c>();

            if(!mapParticipantMilestonesByIdsByParticipants.isEmpty()){
                // iterate over each participant
                for(Id participantId : mapParticipantMilestonesByIdsByParticipants.keySet()){
                    // iterate over each missed child participant milestone
                    if(mapParticipantMilestonesByIdsByParticipants.containsKey(participantId)){
                        for(Participant_Milestone__c pm : mapParticipantMilestonesByIdsByParticipants.get(participantId)){

                            Map<Id,List<Participant_Milestone_Metric__c>> mapMilestoneMetricsByParentMilestones = new Map<Id, List<Participant_Milestone_Metric__c>>();
                            if(mapParticipantMilestoneMetricsByParentMilestoneIdsByMilestoneIds.containsKey(pm.Parent_Milestone__c)){
                                mapMilestoneMetricsByParentMilestones = mapParticipantMilestoneMetricsByParentMilestoneIdsByMilestoneIds.get(pm.Parent_Milestone__c);

                                for(Id parentParticipantMilestoneId : mapMilestoneMetricsByParentMilestones.keySet()){

                                    Participant_Milestone__c parentParticipantMilestone = new Participant_Milestone__c();
                                    if(mapParentParticipantMilestonesByIds.containsKey(parentParticipantMilestoneId)){
                                        parentParticipantMilestone = mapParentParticipantMilestonesByIds.get(parentParticipantMilestoneId);

                                        // to get the right Parent Participant Milestone of the Participant
                                        if(parentParticipantMilestone.Journey__c == participantId){
                                            if(mapMilestoneMetricsByParentMilestones.containsKey(parentParticipantMilestoneId)){
                                                for(Participant_Milestone_Metric__c pmm : mapMilestoneMetricsByParentMilestones.get(parentParticipantMilestoneId)){
                                                    if((pmm.Metric_Used__c == 'Registration Date') && (pmm.Completion_Date__c != (Datetime)null)){
                                                        pmm.Completion_Date__c = null;
                                                        lstParticipantMilestoneMetricsToBeUpdated.add(pmm);
                                                        mapMetricJourneyId.put(pmm.Id,pmm.Milestone__r.Journey__r.Journey__c);
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
				// Start 1/25/2023 CCN-2517 Von Pernicia: added logic to consolidate all journey ids to be used to process UpdateCheckpointProgressQueueable
                if(!lstParticipantMilestoneMetricsToBeUpdated.isEmpty()){
                    //Database.update(lstParticipantMilestoneMetricsToBeUpdated);
                    Database.SaveResult[] myResult = Database.update(lstParticipantMilestoneMetricsToBeUpdated, false);
                    for(Integer i=0; i < myResult.size(); i++) {
                        if(myResult.get(i).isSuccess()) {
                            System.debug('Records are updated Successfully');                            
                            setJourneyIds.add(mapMetricJourneyId.get(myResult.get(i).Id));
                        } 
                    }
                }
                // End 1/25/2023 CCN-2517 Von Pernicia: added logic to consolidate all journey ids to be used to process UpdateCheckpointProgressQueueable
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Start 1/17/2023 CCN-2431 Von Pernicia: added logic to insert record in BatchProcessor
        String finalJourneyId ;
        for (Id jId: setJourneyIds) {
            if (String.isEmpty(finalJourneyId)) {
                finalJourneyId = '\'' + String.valueOf(jId) + '\'';
            } else {
                finalJourneyId = finalJourneyId + ',' + '\'' + String.valueOf(jId) + '\'';
            }
        }
        
        system.debug('@@ JOURNEY TO PROCESS >>' + finalJourneyId);

        UpdateCheckpointProgressQueueable checkpointProgressQueueable = new UpdateCheckpointProgressQueueable(finalJourneyId);
        Id jobPsa = System.enqueueJob(checkpointProgressQueueable);
        // End 1/17/2023 CCN-2431 Von Pernicia: added logic to insert record in BatchProcessor
    }

    global void execute(SchedulableContext sc) {
        BatchUpdateParentMilestoneProgress batchObj = new BatchUpdateParentMilestoneProgress ();
        Id batchProcessId = Database.executeBatch(batchObj, 50);
    }
}