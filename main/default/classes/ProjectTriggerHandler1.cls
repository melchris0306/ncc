/**
* @description Trigger Handler Class for ProjectTrigger 
* 
*           05/27/2021 - Christian Doctolero - TriggerHandler Creation
*			Trigger class: ProjectTrigger1
**/
public class ProjectTriggerHandler1{
    
    public static void onBeforeInsert(List<Project__c> newProjectList, Map<Id,Project__c> newProjectMap,
                                     List<Project__c> oldProjectList, Map<Id,Project__c> oldProjectMap){
        ProjectTriggerUtility1.initializeStartingTaskNumber(newProjectList); 
        ProjectTriggerUtility1.assignRaidUrl(newProjectList, null); 
    }
    
    public static void onBeforeUpdate(List<Project__c> newProjectList, Map<Id,Project__c> newProjectMap, 
                                      List<Project__c> oldProjectList, Map<Id,Project__c> oldProjectMap){ 
        System.debug('TriggerHandler');
    	ProjectTriggerUtility1.initializeStartingTaskNumber(newProjectList);
        ProjectTriggerUtility1.assignRaidUrl(newProjectList, oldProjectMap);      
    }
	/*
	public static void onAfterInsert(List<Project__c> newProjectTaskList, Map<Id,Project__c> newProjectTaskMap){                                      
    }
    
    public static void onAfterDelete(List<Project__c> newProjectTaskList, Map<Id,Project__c> newProjectTaskMap, 
									 List<Project__c> oldProjectTaskList, Map<Id,Project__c> oldProjectTaskMap){
    }
	public static void onBeforeDelete(List<Project__c> newProjectTaskList, Map<Id,Project__c> newProjectTaskMap, 
									  List<Project__c> oldProjectTaskList, Map<Id,Project__c> oldProjectTaskMap){
    }
    public static void onAfterUndelete(List<Project__c> newProjectTaskList, Map<Id,Project__c> newProjectTaskMap, 
									   List<Project__c> oldProjectTaskList, Map<Id,Project__c> oldProjectTaskMap){
    }*/
}