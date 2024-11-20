/*******************************************************************************************
  * @name: SurveyParticipantTriggerHandler
  * @author: 
  * @created: 06-01-2022
  * @description: Handler for all the logic of the trigger for the Survey Participant object
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *       		No.   Date(dd-mm-yyy) 	Author         	   	  Description
  *       		----  ---------------   --------------------  ---------------------------------
  * @version    1.0	  06-01-2022		Ruth Lugpatan		  [CCN-1049] Initial Creation
*********************************************************************************************/
public class SurveyParticipantTriggerHandler {
    
    public static void onBeforeInsert(List<Survey_Participant__c> newsurveyParticipantList, Map<Id,Survey_Participant__c> newsurveyParticipantMap, List<Survey_Participant__c> oldsurveyParticipantList, Map<Id,Survey_Participant__c> oldsurveyParticipantMap){
        
        syncSurveyRichTextFields(newsurveyParticipantList);                                        
        
    }
    
    /**
    * @description - [CCN-1049] method to sync Rich Text Fields from Survey
    * @author RLugpatan | 06/01/2022 
    * @param newsurveyParticipantList 
    * @return List<Survey_Participant__c>
    **/
    public static void syncSurveyRichTextFields(List<Survey_Participant__c> newsurveyParticipantList) {
        Set<Id> surveyIdSet = new Set<Id>();
        Map<Id, Survey__c> surveyMap = new Map<Id, Survey__c>();
        
        for(Survey_Participant__c surveyParticipant : newsurveyParticipantList) {
            surveyIdSet.add(surveyParticipant.Survey__c);
        }
        
        if (surveyIdSet.isEmpty()){
            return;
        }
        
        for(Survey__c survey : [SELECT Id, Survey_Thank_You_Message__c, Survey_Catchup_Message__c, Survey_Catchup_Reminder_Message__c, Survey_Reminder_Message__c
                                FROM Survey__c WHERE Id IN :surveyIdSet]) {
            surveyMap.put(survey.Id, survey);	                                          
        }
        
        for(Survey_Participant__c surveyParticipant : newsurveyParticipantList) {
            if (surveyMap.containsKey(surveyParticipant.Survey__c)){
                surveyParticipant.Survey_Thank_You_Message__c = surveyMap.get(surveyParticipant.Survey__c).Survey_Thank_You_Message__c;
                surveyParticipant.Survey_Catchup_Message__c = surveyMap.get(surveyParticipant.Survey__c).Survey_Catchup_Message__c;
                surveyParticipant.Survey_Catchup_Reminder_Message__c = surveyMap.get(surveyParticipant.Survey__c).Survey_Catchup_Reminder_Message__c;
                surveyParticipant.Survey_Reminder_Message__c = surveyMap.get(surveyParticipant.Survey__c).Survey_Reminder_Message__c;
            }
        }
    }
}