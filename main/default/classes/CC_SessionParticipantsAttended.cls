/*******************************************************************************************
    * @name: CC_SessionParticipantsAttended 
    * @author: Heidi Tang
    * @created: 14-05-2021
    * @description: controller class that updates session participants status
    * 
    * Changes (version)
    * -------------------------------------------------------------------------------------------
    *               No.     Date(dd-mm-yyy) Author                  Description
    *               ----    ---------       --------------------    -----------------------------
    * @version      1.0     14-05-2021      Heidi Tang               Initial version.
    * @version      2.0     08-12-2021      Ruth Lugpatan            [CCN975] Get the Attended participant fields
*********************************************************************************************/
public with sharing class CC_SessionParticipantsAttended {

    @AuraEnabled
    public static List<Session_Participant__c> getSessionParticipants(String recordId){
        return [SELECT Id,Name,Contact_Name__c,Status__c,Session_Start_Date__c FROM Session_Participant__c 
                WHERE Session__c = :recordId AND Status__c != 'Attended' ORDER BY Contact_Name__c ];
    }

    @AuraEnabled
    public static List<Session_Participant__c> markSessionParticipantsToAttended(String recordId, List<Session_Participant__c> selectedParticipants){
        try {
            for(Session_Participant__c selectedParticipant : selectedParticipants) {
                selectedParticipant.Status__c = 'Attended';
            }    
            update selectedParticipants;
    
            return getSessionParticipants(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * @description  Get the Attended participant fields
    * @author       RLugpatan | 08/12/2021 | [CCN975]
    * @param sessionId
    **/
    @AuraEnabled
    public static String getEventAttendedParticipantFieldsJSON(Id sessionId){
        Event__c event = new Event__c();
        try{
            event = [SELECT Id, Attended_Participant_Fields_JSON__c FROM Event__c WHERE Id IN (SELECT Event__c FROM Session__c WHERE Id = :sessionId) LIMIT 1];
        }catch(Exception errorAPI){
            System.debug('TRY-CATCH-EventRecord-->' + errorAPI);
        }
        return event.Attended_Participant_Fields_JSON__c;
    }
    
    /**
    * @description  Used to get the picklist value.
    * @author       RLugpatan | 01/12/2021 | [CCN975]
    * @param fieldName
    **/
    @AuraEnabled
    public static List<String> getPickListValues(String fieldName){
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('Session_Participant__c').getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
            //pickListValuesList.add(new String(pickListVal.getLabel(), pickListVal.getValue()));
        }     
        return pickListValuesList;
    }
    
}