public with sharing class SurveyTriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean IsDisabled(){
        if (TriggerSettings__c.getInstance().SurveyTriggerDisabled__c)
            return true;
        else
            return TriggerDisabled;
    }
 
    public static void onBeforeInsert(List<SObject> newItems, Map<Id, SObject> newItemMap) {
        // Check if Active__c is checked
        List<Survey__c> surveysToProcess = new List<Survey__c>();
        for (Survey__c s : (List<Survey__c>)newItems){
            if (s.Active__c) surveysToProcess.add(s);
        }
        SurveyTriggerHelper.checkExistingActiveSurveys(surveysToProcess);

        SurveyTriggerHelper.setSurveyCode(newItems);

        //XEN REYES CCN-SUR-3235-DV 14 July 2023
        SurveyTriggerHelper.setSiteValues(newItems);
    }

    public static void onBeforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
        // Check if the Active__c field has been updated and checked
        Map<Id, Survey__c> newSurveys = (Map<Id, Survey__c>)newItemsMap;
        Map<Id, Survey__c> oldSurveys = (Map<Id, Survey__c>)oldItemsMap;
        List<Survey__c> surveysToProcess = new List<Survey__c>();
        for (Survey__c s : newSurveys.values()){
            if ((s.Active__c == true) && (s.Active__c != oldSurveys.get(s.Id).Active__c)){
                surveysToProcess.add(s);
            }
        }
        SurveyTriggerHelper.checkExistingActiveSurveys(surveysToProcess);

        SurveyTriggerHelper.setSurveyCode(newItems);
    }
 
    /**
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {}
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    **/
    
    // Added by RLugpatan [CCN-1049] Jan052022
    public static void syncSurveyRichTextFields(Map<Id,Survey__c > newMap) {
        Map<Id, Survey__c> eventToSurveyMap = new Map<Id, Survey__c>();
        List<sObject> recordsToUpdate = new List<sObject>();
        
        for(Survey_Participant__c sp : [SELECT Id, Survey_Thank_You_Message__c, Survey_Catchup_Reminder_Message__c, Survey_Catchup_Message__c, 
                                         Survey_Reminder_Message__c, Survey__r.Survey_Thank_You_Message__c, Survey__r.Survey_Catchup_Reminder_Message__c, 
                                         Survey__r.Survey_Catchup_Message__c, Survey__r.Survey_Reminder_Message__c
                                         FROM Survey_Participant__c WHERE Survey__c IN :newMap.keySet()]) { 
                                             sp.Survey_Thank_You_Message__c = sp.Survey__r.Survey_Thank_You_Message__c;
                                             sp.Survey_Catchup_Message__c = sp.Survey__r.Survey_Catchup_Message__c;
                                             sp.Survey_Catchup_Reminder_Message__c = sp.Survey__r.Survey_Catchup_Reminder_Message__c;
                                             sp.Survey_Reminder_Message__c = sp.Survey__r.Survey_Reminder_Message__c;
                                             recordsToUpdate.add(sp);
                                         }
        
        // Added by PQuiambao [CCN-1049] Jan082022
        for(Survey__c s : newMap.values()) {
            eventToSurveyMap.put(s.Event__c, s);
        }
        
        // Added by PQuiambao [CCN-1049] Jan082022
        for(Participant__c p : [SELECT Id, Event__c, Survey_Catchup_Message__c, Survey_Catchup_Reminder_Message__c, Survey_Reminder_Message__c, Survey_Thank_You_Message__c
                                FROM Participant__c WHERE Event__c IN :eventToSurveyMap.keySet()]) {
                                    Survey__c survey = eventToSurveyMap.get(p.Event__c);
                                    p.Survey_Thank_You_Message__c = survey.Survey_Thank_You_Message__c;
                                    p.Survey_Catchup_Message__c = survey.Survey_Catchup_Message__c;
                                    p.Survey_Catchup_Reminder_Message__c = survey.Survey_Catchup_Reminder_Message__c;
                                    p.Survey_Reminder_Message__c = survey.Survey_Reminder_Message__c;
                                    recordsToUpdate.add(p);
                                }
        try{
            if(!recordsToUpdate.isEmpty()){
                update recordsToUpdate;
            }
        }catch (Exception err) {
            System.Debug('TRY-CATCH-Exception-->' + err);
        }
        
    }
}