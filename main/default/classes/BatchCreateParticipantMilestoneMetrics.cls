/*******************************************************************************
 * @author       Angelo Rivera
 * @date         14.Jan.2022
 * @description  Creates Participant Milestone Metrics
 * @revision     14.Jan.2022 - APRivera - Created
 *******************************************************************************/
global class BatchCreateParticipantMilestoneMetrics implements Database.Batchable<SObject>, Database.Stateful{

    public String strQuery;
    public static List<Participant_Milestone_Metric__c> lstUserMilestoneMetrics = new List<Participant_Milestone_Metric__c>();
    public Map<Id, Map<String, List<String>>> mapMilestoneMetricByTypeByJourneyId = new Map<Id, Map<String, List<String>>>();
    public Set<Id> setJourneyIds = new Set<Id>();
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        try {
            strQuery = 'SELECT Id, CreatedDate, Journey__c, Type__c, Journey__r.Journey__c ' +
                    'FROM Participant_Milestone__c ' +
                    'WHERE Progress__c = null AND Journey__r.Journey__c IN: setJourneyIds ORDER BY CreatedDate ASC '; //+
//                    'LIMIT ' + String.valueOf(Limits.getLimitQueryRows() - Limits.getQueryRows());
            System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
            return Database.getQueryLocator(strQuery);
        } catch(Exception e) {
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        Set<Id> setUserJourneyId = new Set<Id>();
        Map<Id, Id> mapJourneyIdsByUserJourneyIds = new Map<Id, Id>();
        List<Participant_Milestone__c> lstUserMilestones = (List<Participant_Milestone__c>)scope;
        for(Participant_Milestone__c pm : lstUserMilestones){
            setUserJourneyId.add(pm.Journey__c);
        }
        mapJourneyIdsByUserJourneyIds = JourneyParticipantServices.getJourneyIds(setUserJourneyId);
        for (Participant_Milestone__c userMilestone : lstUserMilestones) {
            Id journeyId = mapJourneyIdsByUserJourneyIds.get(userMilestone.Journey__c);// <Journey Participants Id , Journey Record>
            if (mapMilestoneMetricByTypeByJourneyId.containsKey(journeyId)) {
                Map<String, List<String>> mapMilestoneMetricByType = mapMilestoneMetricByTypeByJourneyId.get(journeyId);
                if (mapMilestoneMetricByType.containsKey(userMilestone.Type__c)) {
                    for (String strField : mapMilestoneMetricByType.get(userMilestone.Type__c)) {
                        Participant_Milestone_Metric__c umm = new Participant_Milestone_Metric__c();
                        umm.Metric_Used__c = strField;
                        umm.Milestone__c = userMilestone.Id;
                        lstUserMilestoneMetrics.add(umm);
                    }
                }
            }
        }

        try {
            if (!lstUserMilestoneMetrics.isEmpty()) {
                Database.insert(lstUserMilestoneMetrics);
            }
        } catch (Exception ex) {
            System.debug( LoggingLevel.DEBUG, '!@# ERROR IN INSERTING Participant_Milestone_Metric__c: ' + ex.getMessage() );
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}