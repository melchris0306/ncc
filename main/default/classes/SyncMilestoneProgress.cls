/**
* @description Aura Handler for SyncMilestoneProgress
* @revision
*           11.02.2021 - APRivera - Initial Creation
**/


public with sharing class SyncMilestoneProgress {

    @AuraEnabled
    public static String syncMilestoneProgress(Id journeyId){
        String strReturn;

        Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByIds = new Map<Id, List<Participant_Milestone__c>>();
        mapParticipantMilestonesByIds = getJourneyParticipants(journeyId);

        return strReturn;
    }


    public static Map<Id, List<Participant_Milestone__c>> getJourneyParticipants(Id journeyId){
        Map<Id, List<Participant_Milestone__c>> mapParticipantMilestonesByIds = new Map<Id, List<Participant_Milestone__c>>();
        for(Participant_Milestone__c pm : [SELECT Id, Name, Type__c, Contact__c, Milestone__c,
                                            (SELECT Id, Metric_Used__c, Completion_Date__c FROM Participant_Milestone_Metrics__r)
                                            FROM Participant_Milestone__c
                                            WHERE Journey__c =: journeyId]){
            if(!mapParticipantMilestonesByIds.containsKey(pm.Contact__c)){
                List<Participant_Milestone__c> lstParticipantMilestones = new List<Participant_Milestone__c>();
                lstParticipantMilestones.add(pm);
                mapParticipantMilestonesByIds.put(pm.Contact__c, lstParticipantMilestones);
            }else{
                mapParticipantMilestonesByIds.get(pm.Contact__c).add(pm);
            }
        }
        return mapParticipantMilestonesByIds;
    }
    /*Gab*/
    public void sync(Id journeyId){
        List<Participant_Milestone_Metric__c> forUpdateList = New List<Participant_Milestone_Metric__c>();
        
        List<Participant_Milestone_Metric__c> participantList = [Select Completion_Date__c, Metric_Used__c, Milestone__c, Milestone__r.Event__c, Milestone__r.Milestone__c, Milestone__r.Name ,Milestone__r.Journey__r.Contact__c, Milestone__r.Journey__c, Milestone__r.Type__c FROM Participant_Milestone_Metric__c where Milestone__r.Journey__c =: journeyId];
        //Need to check event, comminucation, survey if the participant has record if yes populate participant milestone metric
        for(Participant_Milestone_Metric__c partMilesMetric:participantList) {
            eventMilestone eventMilestoneRec = new eventMilestone();
            If(partMilesMetric.Milestone__r.Type__c == 'Event'){
                eventMilestoneRec = getEventDetails(partMilesMetric.Milestone__r.Name, partMilesMetric.Milestone__r.Journey__c, partMilesMetric.Milestone__r.Journey__r.Contact__c);
                If(partMilesMetric.Metric_Used__c == 'Date Invited'){
                   partMilesMetric.Completion_Date__c = eventMilestoneRec.dateInvited;
                }
                If(partMilesMetric.Metric_Used__c == 'Date Attended'){
                   partMilesMetric.Completion_Date__c = eventMilestoneRec.dateAttented;
                }
                If(partMilesMetric.Metric_Used__c == 'Date Registered'){
                   partMilesMetric.Completion_Date__c = eventMilestoneRec.dateRegistered;
                }
               forUpdateList.add(partMilesMetric);
            }
        }           
        update forUpdateList;
    }
    
    Public eventMilestone getEventDetails(String MilesstoneName, String MilestoneJourney, String con){
        eventMilestone eventMilestoneRec = new eventMilestone();
        Session_Participant__c sesPart = [Select Contact__c, Event__r.Name, Session__r.Name, Event__r.Journey__c, Invitation_Date__c, Registration_Date__c, Attendance_Date__c from Session_Participant__c where Session__r.Name =: MilesstoneName AND Event__r.Journey__c =: MilestoneJourney AND Contact__c =: con LIMIT 1];
        eventMilestoneRec.dateInvited = sesPart.Invitation_Date__c;
        eventMilestoneRec.dateAttented = sesPart.Attendance_Date__c;
        eventMilestoneRec.dateRegistered = sesPart.Registration_Date__c;
        system.debug('eventMilestoneRec' + eventMilestoneRec);
        return eventMilestoneRec;
    }
    
    public class eventMilestone{
        dateTime dateInvited;
        dateTime dateAttented;
        dateTime dateRegistered;
    }
}