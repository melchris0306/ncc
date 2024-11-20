global with sharing class CampaignHierarchyPage {
    
    @AuraEnabled     
    public static String objectType(Id recordIdVal){
        Schema.SObjectType objType = recordIdVal.getSobjectType(); 
        return String.valueOf(objType);
        //return objType != null ? String.valueOf(objType).split('__', 2)[1] : '';
    }
    
    @AuraEnabled     
    public static List<Campaign__c> searchForCampaign(Id recordIdVal){
        String objType = objectType(recordIdVal); 
        List<Campaign__c> campList = new List<Campaign__c>();
        if(String.valueOf(objType) == 'Campaign__c'){
            if(FlsUtils.isAccessible('Campaign__c', new List<String>{'Name'})){
                campList = [SELECT Id, Name FROM Campaign__c WHERE Id =: recordIdVal];
            }
        }

        return campList;
    }
    
    @AuraEnabled     
    public static List<Event__c> searchForEvent(Id recordIdVal){
        String objType = objectType(recordIdVal); 
        List<Event__c> eventList;

        if(FlsUtils.isAccessible('Event__c', new List<String>{'Name','Campaign__c','Start_Date_Time__c','End_Date_Time__c','Time_Zone__c'})){
            if(String.valueOf(objType) == 'Campaign__c'){
                eventList = [SELECT Id, Name, Campaign__c, Start_Date_Time__c, End_Date_Time__c, Time_Zone__c FROM Event__c WHERE Campaign__c =: recordIdVal];
            }
            else if(String.valueOf(objType) == 'Event__c'){
                eventList = [SELECT Id, Name, Campaign__c, Start_Date_Time__c, End_Date_Time__c, Time_Zone__c FROM Event__c WHERE Id =: recordIdVal];
            }  
        }

        return eventList;
    }
    
    @AuraEnabled 
    public static List<Session__c> searchForSession(List<Id> eventList, Id recordIdVal){

        List<Session__c> sessionList;

        if((FlsUtils.isAccessible('Event__c', new List<String>{'Campaign__c'}))  
                && FlsUtils.isAccessible('Session__c', new List<String>{'Name', 'Event__c', 'Start_Date_Time__c','End_Date_Time__c','Time_Zone__c'})){
            if(!eventList.isEmpty()){
                sessionList = [SELECT Id, Name, Event__c, Event__r.Campaign__c, Start_Date_Time__c, End_Date_Time__c, Time_Zone__c FROM Session__c WHERE Event__c IN: eventList];
            }
            else if(recordIdVal != null){
                sessionList = [SELECT Id, Name, Event__c, Event__r.Campaign__c, Start_Date_Time__c, End_Date_Time__c, Time_Zone__c FROM Session__c WHERE Id =: recordIdVal];
            } 
        }

        return sessionList;
    }
}