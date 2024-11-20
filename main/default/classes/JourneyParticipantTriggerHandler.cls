/**
* @description TriggerHandler Class for Journey_Participant__c Object Trigger
* @revision
*           10.09.2020 - APRivera - Initial Creation
**/

public class JourneyParticipantTriggerHandler {

    /*******************************************************************************
    * @description  handles all before insert events. Filter event criteria here
    * @param        newMap - Trigger.newMap context variable
    * @revision     10.09.2020 - APRivera - Created
    *******************************************************************************/
    public static void handleAfterInsert(Map<Id, Journey_Participant__c> newMap) {
        processNewJourneyParticipants(newMap);

        String strJourneyCommunityURL = JourneyParticipantServices.getCommunityURL( JourneyParticipantServices.UserJourneyCommunitySettings.Community_Name__c );
        Set<Id> setJourneyIds = new Set<Id>();
        for(Journey_Participant__c usrJourney : newMap.values()){
            setJourneyIds.add(usrJourney.Journey__c);
        }

        Map<Id, Journey__c> mapJourneysByIds = new Map<Id, Journey__c>();
        for(Journey__c j : [SELECT Id, Description__c FROM Journey__c WHERE Id IN: setJourneyIds]){
            mapJourneysByIds.put(j.Id, j);
        }

        List<Journey_Participant__c> lstJourneyParticipants = new List<Journey_Participant__c>();
        for(Journey_Participant__c usrJourney : newMap.values()){
            if(mapJourneysByIds.containsKey(usrJourney.Journey__c) && usrJourney.Journey__c != null){
                Journey_Participant__c newJP = new Journey_Participant__c();
                newJP.Id = usrJourney.Id;
                newJP.Description__c = usrJourney.Description__c != null ? usrJourney.Description__c : mapJourneysByIds.get(usrJourney.Journey__c).Description__c;
                newJP.Journey_URL__c = strJourneyCommunityURL + '/s/journey?journeyId=' + usrJourney.Id;
                lstJourneyParticipants.add(newJP);
            }
        }
        update lstJourneyParticipants;
    }


    /*******************************************************************************
    * @author       Angelo Rivera
    * @date         10.09.2020
    * @description  Process User Journeys
    * @param        newMap - map of the new records
    * @revision     10.09.2020 - APRivera - Created
    *******************************************************************************/
    public static void processNewJourneyParticipants(Map<Id, Journey_Participant__c> newMap){
        List<Journey_Participant__c> lstUserJourneys = new List<Journey_Participant__c>();
        Set<Id> setJourneyTemplateId = new Set<Id>();
        Set<Id> setIds = new Set<Id>();

        for(Journey_Participant__c usrJourney : newMap.values()){
            if(usrJourney.Journey__c != null){
                setJourneyTemplateId.add(usrJourney.Journey__c);
                lstUserJourneys.add(usrJourney);
                setIds.add(usrJourney.Id);
            }
        }

        if(!lstUserJourneys.isEmpty()){
            JourneyParticipantServices.processNewUserJourneys(lstUserJourneys, setJourneyTemplateId, setIds);
        }
    }
}