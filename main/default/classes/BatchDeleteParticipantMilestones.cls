/*******************************************************************************
 * @author       Angelo Rivera
 * @date         14.Jan.2022
 * @description  Deletes Participant Milestones
 * @revision     14.Jan.2022 - APRivera - Created
 *******************************************************************************/
global class BatchDeleteParticipantMilestones implements Database.Batchable<SObject>, Database.Stateful{

    public String strQuery = '';
    public Set<Id> setJourneyIds = new Set<Id>();
    public List<Milestone__c> lstMilestones = new List<Milestone__c>();
    public Set<Decimal> setSortOrder = new Set<Decimal>();
    public Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByIds = new Map<Id, List<Participant_Milestone__c>>();
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        try {
            strQuery = 'SELECT Id  FROM Journey_Participant__c WHERE Journey__c IN :setJourneyIds ORDER BY CreatedDate ASC ';// +
//                        ' LIMIT ' + String.valueOf(Limits.getLimitQueryRows() - Limits.getQueryRows());
            System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
            return Database.getQueryLocator(strQuery);
        } catch(Exception e) {
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        List<Journey_Participant__c> lstJourneyParticipants = (List<Journey_Participant__c>)scope;

        if (!lstJourneyParticipants.isEmpty()) {
            System.debug(LoggingLevel.DEBUG,'!@# lstMilestones: ' + lstMilestones);

            Set<Id> setId = new Set<Id>();
            for(Journey_Participant__c journeyParticipant : lstJourneyParticipants){
                setId.add(journeyParticipant.Id);
            }

            for(Participant_Milestone__c pm : [SELECT Id, Name, Sort_Order__c, Journey__c
                                                FROM Participant_Milestone__c
                                                WHERE Sort_Order__c IN: setSortOrder
                                                AND Journey__c IN: setId]){
                if(mapParticipantMilestonesByIds.containsKey(pm.Journey__c)){
                    mapParticipantMilestonesByIds.get(pm.Journey__c).add(pm);
                }else{
                    mapParticipantMilestonesByIds.put(pm.Journey__c, new List<Participant_Milestone__c>());
                    mapParticipantMilestonesByIds.get(pm.Journey__c).add(pm);
                }
            }

            List<Participant_Milestone__c> lstParticipantMilestones = new List<Participant_Milestone__c>();
            for (Milestone__c m : lstMilestones) {
                for (Journey_Participant__c jp : lstJourneyParticipants) {
                    if (mapParticipantMilestonesByIds.containsKey(jp.Id)) {
                        for (Participant_Milestone__c pm : mapParticipantMilestonesByIds.get(jp.Id)) {
                            if ( pm.Sort_Order__c == m.Sort_Order__c) {
                                lstParticipantMilestones.add(pm);
                            }
                        }
                    }
                }
            }
            if (!lstParticipantMilestones.isEmpty()) Database.delete(lstParticipantMilestones);
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}