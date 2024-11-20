public with sharing class CommunicationTriggerHelper {
    public static void onBeforeInsert(List<Communication__c> newList){
        // 01103 - Ability to Add Date to Communications
        for(Communication__c newComm : newList){
            if(newComm.Email_Date__c == null && newComm.Status__c == 'Draft'){
                newComm.Email_Date__c = date.today().addDays(14);
            }
        }
    }
    // public static void onAfterInsert(Map<Id, Communication__c> newMap){
        
    // }
    // public static void onBeforeUpdate(Map<Id, Communication__c> newMap, Map<Id, Communication__c> oldMap){

    // }
    // public static void onAfterUpdate(Map<Id, Communication__c> newMap, Map<Id, Communication__c> oldMap){

    // }
    
    
}