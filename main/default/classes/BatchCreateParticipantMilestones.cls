/*******************************************************************************
 * @author       Angelo Rivera
 * @date         14.Jan.2022
 * @description  Creates Participant Milestones
 * @revision     14.Jan.2022 - APRivera - Created
 *******************************************************************************/
global class BatchCreateParticipantMilestones implements Database.Batchable<SObject>, Database.Stateful{

    public String strQuery = '';
    public Map<Id, Journey__c> mapJourneysByIds = new Map<Id, Journey__c>();
    public String strJourneyCommunityURL = '';
    public Map<Id, List<Milestone__c>> mapMilestonesByJourneyIds = new Map<Id, List<Milestone__c>>();
    public Set<Id> setIds = new Set<Id>();
    public static List<Participant_Milestone__c> lstUserMilestonesToInsert = new List<Participant_Milestone__c>();

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        try {
            strQuery = 'SELECT Id, Journey__c, Description__c, Contact__c, Journey_URL__c, CreatedDate ' +
                    'FROM Journey_Participant__c ' +
                    'WHERE Id IN: setIds ORDER BY CreatedDate ASC ';
//                    'LIMIT ' + String.valueOf(Limits.getLimitQueryRows() - Limits.getQueryRows());
            System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
            return Database.getQueryLocator(strQuery);
        } catch(Exception e) {
            return null;
        }
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        List<Journey_Participant__c> lstJourneyParticipants = (List<Journey_Participant__c>)scope;

        for (Journey_Participant__c userJourney : lstJourneyParticipants) {
            //retrieves Journey details to be copied over to user journey
            Journey__c journey = mapJourneysByIds.get(userJourney.Journey__c);

            List<Milestone__c> lstMilestones = new List<Milestone__c>();
            if(mapMilestonesByJourneyIds.containsKey(journey.Id)) lstMilestones.addAll(mapMilestonesByJourneyIds.get(journey.Id));
            //checks if there are Milestones from the Journey Template
            if (!lstMilestones.isEmpty()) {
                JourneyParticipantServices.createUserMilestones(lstMilestones, userJourney, lstUserMilestonesToInsert );
            }
        }
        try {
            if (!lstUserMilestonesToInsert.isEmpty()) {
                Database.insert(lstUserMilestonesToInsert);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.DEBUG,'!@# ERROR IN INSERTING Participant_Milestone__c: ' + ex.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}