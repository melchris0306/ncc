/*******************************************************************************************
* @name: BatchSyncParticipantMilestoneMetric
* @author: DinoBrinas
* @created: 13-01-2022
* @description: [CCN1122] This is batch to Sync all the Participant Milestone Metricx
*
* Changes (version)
* -------------------------------------------------------------------------------------------
*            No.   Date(dd-mm-yyy)  Author                  Description
*           ----   ---------        --------------------    -----------------------------
* @version   1.0   13-01-2022       DinoBrinas               Initial version.
* @version   2.0   15-02-2022       APRivera                 Added logic of Adhoc Journey Assignment
* @version   2.1   20-04-2022       APRivera                 CCN-JOU-1501-DV
* @version   2.3   12-10-2022       APRivera                 CCN-2168
* @version   3.0   07-12-2022       APRivera                 CCN-2355 - Fixed Checkpoint progress calculation
*********************************************************************************************/
global class BatchSyncParticipantMilestoneMetric implements Database.Batchable<SObject>, Database.Stateful{

    public static Map<String, String> objFieldMap { get; set; }
    public static Map<String, Participant__c> participantMap { get; set; }
    public static Map<String, Session_Participant__c> session_ParticipantMap { get; set; }
    public static Map<String, Communication_Recipient__c> communication_RecipientMap { get; set; }
    public static Map<String, Survey_Response__c> survey_ResponseMap { get; set; }
    public static List<Participant_Milestone_Metric__c> participant_Milestone_MetricToUpdate { get; set; }
    public static Set<Id> setEventIds { get; set; }
    public static Set<Id> setSurveyIds { get; set; }

    public String strQuery;
    global String journeyId;
    global String finalContactId; // CCN-2429 [01-01-2023]: Added new Parameter - Von Pernicia
    global Set<String> journeyIds = new Set<String>();
    public List<Batch_Processor__c> batchProcessorList = new List<Batch_Processor__c>();

    public Map<Id, Participant_Milestone_Metric__c> metricsMapByIds;
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(strQuery);
    }
    global void execute(Database.BatchableContext BC, List<SObject> paricipantMilestoneRecs)
    {
        process(paricipantMilestoneRecs, journeyId, journeyIds);
    }

    /*******************************************************************************
     * @author       DinoBrinas
     * @date         na
     * @description  this will sync participat milestone metrics
     * @return       strResult
     * @revision     Na         - DinoBrinas: Initial
     *               10/08/2022 - Von Pernicia [CCN-1984]: approach inside for loops to fix cpu timeout
     *******************************************************************************/
    global void process(List<SObject> paricipantMilestoneRecs, String journeyId, Set<String> journeyIds) {

        List<Participant_Milestone_Metric__c> participantMilestoneMetricList = (List<Participant_Milestone_Metric__c>)paricipantMilestoneRecs;
        setEventIds = new Set<Id>();
        setSurveyIds = new Set<Id>();

        // Initial Processes before sync up
        getObjFieldDescribed();
        participant_Milestone_MetricToUpdate = new List<Participant_Milestone_Metric__c>();

        if (!String.isEmpty(journeyId)) {
            journeyIds.add(journeyId);
        }

        // retrieves all events/survey linked via Adhoc_Journey_Assignment__c

        for(Adhoc_Journey_Assignment__c adhocJourney : [SELECT Id, Journey__c, Survey__c, Event__c
                                                        FROM Adhoc_Journey_Assignment__c
                                                        WHERE Journey__c IN: journeyIds]){
            //CCN-2303 XEN REYES Nov122022
            if(adhocJourney.Event__c != null) setEventIds.add(adhocJourney.Event__c);
            if(adhocJourney.Survey__c != null) setSurveyIds.add(adhocJourney.Survey__c);
        }

        System.debug(LoggingLevel.DEBUG, '!@# setEventIds: ' + setEventIds);
        System.debug(LoggingLevel.DEBUG, '!@# setSurveyIds: ' + setSurveyIds);

        participantMap = getparticipantMap(journeyIds);
        survey_ResponseMap = getsurvey_ResponseMap(journeyIds);
        communication_RecipientMap = getcommunication_RecipientMap(journeyIds);
        session_ParticipantMap = getsession_ParticipantMap(journeyIds);

        // Start CCN-2168: APRivera - recalculate parent milestones
        metricsMapByIds = new Map<Id, Participant_Milestone_Metric__c>();

        for (Participant_Milestone_Metric__c oParticipant_Milestone_Metric : participantMilestoneMetricList ) {
            metricsMapByIds.put(oParticipant_Milestone_Metric.Id, oParticipant_Milestone_Metric);

            String milestoneKey =  oParticipant_Milestone_Metric.Milestone__r.MileStone__r.Related_RecordId__c + String.valueOf(oParticipant_Milestone_Metric.Milestone__r.Contact__c);

            //CCN-2243 XenReyes Nov142022
            String relatedRecordsObject;
            if(oParticipant_Milestone_Metric.Milestone__r.MileStone__r.Related_RecordId__c != null){
                Id sId = (Id) oParticipant_Milestone_Metric.Milestone__r.MileStone__r.Related_RecordId__c;
                relatedRecordsObject = sId.getSObjectType().getDescribe().getName();
            }

            if(!oParticipant_Milestone_Metric.Milestone__r.Checkpoint__c){
                //------------------------------------- START Participant Milestone Metric Updates ----------------------------------------------------------//
                String fldName = null;
                Datetime fldValue = null;
                if (oParticipant_Milestone_Metric.Milestone__r.Type__c == 'Event') {

                    if(participantMap.get(milestoneKey) != null) {

                        Participant__c oParticipant = participantMap.get(milestoneKey);
                        fldname = objFieldMap.get( 'Participant__c' + oParticipant_Milestone_Metric.Metric_Used__c  );
                        if (fldName != null) {
                            fldValue = (Datetime) oParticipant.get(fldName);
                        }

                    } else if(session_ParticipantMap.get(milestoneKey) != null) {
                        Session_Participant__c oSession_Participant = session_ParticipantMap.get(milestoneKey);
                        fldname = objFieldMap.get('Session_Participant__c' +oParticipant_Milestone_Metric.Metric_Used__c);
                        if (fldName != null) {
                            fldValue = (Datetime) oSession_Participant.get(fldName);
                        }

                        //CCN-2243 XenReyes Nov142022
                        //TO NULLIFY METRIC USED FIELDS IN CASE NO LONGER APPLICABLE
                    } else if(relatedRecordsObject != null){
                        if(relatedRecordsObject.contains('Event__c')){
                            fldname = objFieldMap.get( 'Participant__c' + oParticipant_Milestone_Metric.Metric_Used__c);
                        } else if(relatedRecordsObject.contains('Session__c')){
                            fldname = objFieldMap.get('Session_Participant__c' +oParticipant_Milestone_Metric.Metric_Used__c);
                        }
                        fldValue = null;
                    }

                } else if (oParticipant_Milestone_Metric.Milestone__r.Type__c == 'Survey') {
                    if (survey_ResponseMap.get(milestoneKey) != null) {
                        Survey_Response__c oSurvey_Response = survey_ResponseMap.get(milestoneKey);

                        fldname = oParticipant_Milestone_Metric.Metric_Used__c;
                        if (oParticipant_Milestone_Metric.Metric_Used__c == 'Date Sent') {
                            fldValue = oSurvey_Response.Survey__r.CreatedDate;

                        } else if ( oParticipant_Milestone_Metric.Metric_Used__c =='Date Responded') {
                            fldValue = oSurvey_Response.CreatedDate;
                        }

                        //CCN-2243 XenReyes Nov142022
                        //TO NULLIFY METRIC USED FIELDS IN CASE NO LONGER APPLICABLE
                    } else if(relatedRecordsObject != null){
                        fldname = oParticipant_Milestone_Metric.Metric_Used__c;
                        fldValue = null;
                    }

                } else if (oParticipant_Milestone_Metric.Milestone__r.Type__c == 'Communication') {
                    if (communication_RecipientMap.get(milestoneKey) != null) {
                        Communication_Recipient__c oCommunication_Recipient = communication_RecipientMap.get( milestoneKey);
                        fldname = objFieldMap.get('Communication_Recipient__c' +oParticipant_Milestone_Metric.Metric_Used__c);
                        if (fldName != null) {
                            fldValue = (Datetime) oCommunication_Recipient.get(fldName);
                        }

                        //CCN-2243 XenReyes Nov142022
                        //TO NULLIFY METRIC USED FIELDS IN CASE NO LONGER APPLICABLE
                    } else if(relatedRecordsObject != null){
                        fldname = objFieldMap.get('Communication_Recipient__c' +oParticipant_Milestone_Metric.Metric_Used__c);
                        fldValue = null;
                    }
                }

                if (String.isNotEmpty(fldName)) {

                    //CCN-2243 XenReyes Nov142022
                    //(oParticipant_Milestone_Metric.Completion_Date__c == null) {
                    oParticipant_Milestone_Metric.Completion_Date__c = fldValue;
                    participant_Milestone_MetricToUpdate.Add(oParticipant_Milestone_Metric);
                    //system.debug('@@ oParticipant_Milestone_Metric >>' + oParticipant_Milestone_Metric);
                    //}
                }
                //------------------------------------- END Participant Milestone Metric Updates ----------------------------------------------------------//
            }
        }

        //try {
        if(participant_Milestone_MetricToUpdate.size() > 0){
            update participant_Milestone_MetricToUpdate;
        }
		
        // Start CCN-2429: Von Pernicia - Comment out ParticipantMilestoneMetricTriggerHandler and migrate to ProcessPartMileMetricQueueable
        // Start CCN-2168: APRivera - recalculate Parent Milestone progress of child milestones that were re-parented
        //ParticipantMilestoneMetricTriggerHandler.processParticipantMilestonesMetric(metricsMapByIds);
        // End CCN-2429: Von Pernicia - Comment out ParticipantMilestoneMetricTriggerHandler and migrate to ProcessPartMileMetricQueueable
    }

    /*******************************************************************************
     * @author       Von
     * @date         na
     * @description  This will cleanup records in batch processor object
     * @return       strResult
     * @revision     10/08/2022 - Von Pernicia [CCN-1984]: This will cleanup records in batch processor object
     *               21/12/2022 - Von Pernicia [CCN-2429]: use journeyIds instead of journeyId and pass the finalJourneyId to UpdateCheckpointProgressQueueable
     *******************************************************************************/
    global void finish(Database.BatchableContext BC) {

        // delete processed records from Batch processor
        if (!this.batchProcessorList.isEmpty()) {
            delete this.batchProcessorList;
        }

        // enqueue Checkpoint Batch update
        // Start CCN-2429: Von Pernicia
        System.debug('@@@ ID:' + journeyIds);
        String finalJourneyId ;
        for (String jId: journeyIds) {
            if (String.isEmpty(finalJourneyId)) {
                finalJourneyId = '\'' + jId + '\'';
            } else {
                finalJourneyId = finalJourneyId + ',' + '\'' + jId + '\'';
            }
        }
        
        //UpdateCheckpointProgressQueueable checkpointProgressQueueable = new UpdateCheckpointProgressQueueable(finalJourneyId);
        //Id jobPsa = System.enqueueJob(checkpointProgressQueueable);

        ProcessPartMileMetricQueueable processParticipantMilestonesMetricQueueable = new ProcessPartMileMetricQueueable(finalJourneyId, finalContactId);
        Id jobPsa = System.enqueueJob(processParticipantMilestonesMetricQueueable);
        // End CCN-2429: Von Pernicia

    }

    global static void objFieldDescribed(String objName,Map<String, Schema.SObjectType> schemaMap) {
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objName).getDescribe().fields.getMap();
        for (Schema.SObjectField sfield : fieldMap.values()) {
            Schema.DescribeFieldResult dfield = sfield.getDescribe();
            objFieldMap.put(objName + dfield.getLabel(), dfield.getName());
        }
    }
    global static void getObjFieldDescribed() {
        // Loading object fields Described
        objFieldMap = new Map<String, String>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        objFieldDescribed('Participant__c', schemaMap);
        objFieldDescribed('Session_Participant__c', schemaMap);
        objFieldDescribed('Communication_Recipient__c', schemaMap);
        objFieldDescribed('Survey_Response__c', schemaMap);
    }

    /*********** Populating Journeys related Participants ***********/
    global static Map<String, Participant__c> getparticipantMap(Set<String> journeyIds) {
        participantMap = new Map<String, Participant__c>();

        List<Participant__c> participantMapTemp = [SELECT Id, Name,Event__c, Member_Contact__c, Invitation_Date__c, Registration_Date__c,
                Attendance_Date__c, Event__r.Journey__c, Event__r.Name, Event__r.Id
        FROM Participant__c
        WHERE (Event__r.Journey__c IN: journeyIds AND Member_Contact__c != NULL AND Event__r.Milestone__c = TRUE)
        OR (Event__r.Id IN: setEventIds AND Member_Contact__c != NULL AND Event__r.Milestone__c = TRUE)
        ORDER BY LastModifiedDate DESC];

        // In case of multiple participants - Which record is qualified for mapping? //
        for (Participant__c oParticipant : participantMapTemp) {
            if (participantMap.get( oParticipant.Event__r.Id + String.valueOf(oParticipant.Member_Contact__c)) == null) {
                participantMap.put( oParticipant.Event__r.Id + String.valueOf(oParticipant.Member_Contact__c), oParticipant);
            }
        }

        return participantMap;
    }

    /*********** Populating Journeys related Sessions ***********/
    global static Map<String, Session_Participant__c> getsession_ParticipantMap(Set<String> journeyIds) {
        session_ParticipantMap = new Map<String, Session_Participant__c>();

        for (Session_Participant__c oSession_Participant : [ SELECT Id, Name, Session__c, Event__c,  Contact__c, Invitation_Date__c,
                Registration_Date__c, Attendance_Date__c, Session__r.Event__r.Journey__c, Session__r.Name, Session__r.Id
        FROM Session_Participant__c
        WHERE (Session__r.Event__r.Journey__c IN:journeyIds AND Contact__c != NULL AND Session__r.Milestone__c = TRUE)
        OR (Session__r.Event__r.Id IN: setEventIds AND Contact__c != NULL AND Session__r.Milestone__c = TRUE)]) {
            if (session_ParticipantMap.get( oSession_Participant.Session__r.Id + String.valueOf(oSession_Participant.Contact__c)) == null) {
                session_ParticipantMap.put( oSession_Participant.Session__r.Id + String.valueOf(oSession_Participant.Contact__c), oSession_Participant);
            }
        }

        return session_ParticipantMap;
    }

    /*********** Populating Journeys related Communications ***********/
    global static Map<String, Communication_Recipient__c> getcommunication_RecipientMap(Set<String> journeyIds) {
        communication_RecipientMap = new Map<String, Communication_Recipient__c>();

        for (Communication_Recipient__c oCommunication_Recipient : [
                SELECT Id, Name, CC_Communication__c, Contact__c, Date_Read__c, Date_Sent__c, CC_Communication__r.Journey__c, CC_Communication__r.Name, CC_Communication__r.Id
                FROM Communication_Recipient__c
                WHERE CC_Communication__r.Journey__c IN: journeyIds
                AND Contact__c != NULL
                AND CC_Communication__r.Milestone__c = TRUE
                AND Send_as__c = 'To' //CCN-1004 Xen Reyes January 25, 2022
        ]) {
            if ( communication_RecipientMap.get( oCommunication_Recipient.CC_Communication__r.Id + String.valueOf(oCommunication_Recipient.Contact__c)) == null) {
                communication_RecipientMap.put( oCommunication_Recipient.CC_Communication__r.Id + String.valueOf(oCommunication_Recipient.Contact__c),oCommunication_Recipient);
            }
        }

        return communication_RecipientMap;
    }
    /*********** Populating Journeys related Surveys ***********/
    global static Map<String, Survey_Response__c> getsurvey_ResponseMap(Set<String> journeyIds) {
        survey_ResponseMap = new Map<String, Survey_Response__c>();
        for (Survey_Response__c oSurvey_Response : [SELECT Id, Name, Survey__c, Contact__c, Survey__r.CreatedDate, Survey__r.Journey__c, Survey__r.Name, Survey__r.Id, CreatedDate
        FROM Survey_Response__c
        WHERE (Survey__r.Journey__c IN:journeyIds AND Contact__c != NULL AND Survey__r.Milestone__c = TRUE)
        OR (Survey__r.Id IN: setSurveyIds AND Contact__c != NULL AND Survey__r.Milestone__c = TRUE)]) {
            if (survey_ResponseMap.get( oSurvey_Response.Survey__r.Id + String.valueOf(oSurvey_Response.Contact__c)) == null){
                survey_ResponseMap.put( oSurvey_Response.Survey__r.Id + String.valueOf(oSurvey_Response.Contact__c), oSurvey_Response);
            }
        }

        return survey_ResponseMap;
    }
}