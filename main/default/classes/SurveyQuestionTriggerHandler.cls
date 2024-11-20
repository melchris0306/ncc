public with sharing class SurveyQuestionTriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    //Checks to see if the trigger has been disabled either by custom setting or by running code
    public Boolean IsDisabled(){
         return TriggerDisabled;
    }
 
    public static void onBeforeInsert(List<SObject> newItems, Map<Id, SObject> newItemsMap, 
                             List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
        SurveyQuestionTriggerHelper.checkDuplicateSortingOrder((List<Survey_Question__c>)newItems);
    }
 
    public static void onBeforeUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, 
                             List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
        // Check if the sorting order has been updated
        Map<Id, Survey_Question__c> newQuestions = (Map<Id, Survey_Question__c>)newItemsMap;
        Map<Id, Survey_Question__c> oldQuestions = (Map<Id, Survey_Question__c>)oldItemsMap;
        List<Survey_Question__c> questionsToProcess = new List<Survey_Question__c>();
        for (Survey_Question__c sq : newQuestions.values()){
            if (sq.Sorting_Order__c != oldQuestions.get(sq.Id).Sorting_Order__c){
                questionsToProcess.add(sq);
            }
        }
        SurveyQuestionTriggerHelper.checkDuplicateSortingOrder(questionsToProcess);
    }
 	/*
    public static void onBeforeDelete(List<SObject> newItems, Map<Id, SObject> newItemsMap, 
                             List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
                                 
    }
 
    public static void onAfterInsert(List<SObject> newItems, Map<Id, SObject> newItemsMap, 
                             List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
                                 
    }
 
    public static void onAfterUpdate(List<SObject> newItems, Map<Id, SObject> newItemsMap, 
                             List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
                                 
    }
 
    public static void onAfterDelete(List<SObject> newItems, Map<Id, SObject> newItemsMap, 
                             List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
                                 
    }
 
    public static void onAfterUndelete(List<SObject> newItems, Map<Id, SObject> newItemsMap, 
                             List<SObject> oldItems, Map<Id, SObject> oldItemsMap) {
                                 
    }*/
}