/*******************************************************************************
* @author           Christian Doctolero
* @date             07.30.2021
* @description      Utlity Handler Class for Case 
* @param        
* @Trigger Class    CaseTrigger
* @Handler Class    CaseTriggerHandler      
*******************************************************************************/

public class CaseTriggerUtility {
    /*******************************************************************************
    * @author           Christian Doctolero
    * @date             07.30.2021
    * @description      CAPM-49
    * @param        
    *******************************************************************************/
    public static void createStoryFromACase(Map<Id,Case> newCaseMap){
        Project_Task__c projTaskRec = new Project_Task__c();
        List<Project_Task__c> projTaskListToAdd = new List<Project_Task__c>();
        Id bugRecTypeId = [SELECT Id FROM RecordType WHERE Name = 'Bug'].Id;
        Id storyRecTypeId = [SELECT Id FROM RecordType WHERE Name = 'Story'].Id;
        Map<String, Id> projViaCodeMap = new Map<String, Id>(); 
        
        //Create a map of projects that has project code as its key
        for(Project__c prk: [SELECT Id, Project_Code__c FROM Project__c]){
            projViaCodeMap.put(prk.Project_Code__c, prk.Id);
        }

        for(Case cs: newCaseMap.values()){
            if(cs.Type == 'Incident'){
                projTaskRec.RecordTypeId = bugRecTypeId;
            }
            else if(cs.Type == 'New feature'){
                projTaskRec.RecordTypeId = storyRecTypeId;
                projTaskRec.Status__c = 'New'; 
            }
            projTaskRec.Title__c = cs.Subject;
            projTaskRec.Organization__c = 'Production';
            projTaskRec.Description__c = cs.Description;
            projTaskRec.OwnerId = cs.OwnerId;
            projTaskRec.Case__c = cs.Id;
            projTaskRec.Project__c = projViaCodeMap.get(cs.Application__c);

            projTaskListToAdd.add(projTaskRec);
        }

        insert projTaskListToAdd;
    }
    
    /*******************************************************************************
    * @author           Christian Doctolero
    * @date             07.30.2021
    * @description      CAPM-49
    * @param        
    *******************************************************************************/
    @future
    public static void updateCaseMovedToCAPM(Set<Id> caseIds){
        
        Map<Id, Id> projTaskViaCaseIdMap = new Map<Id, Id>();
        List<Case> casesToUpdateList = new List<Case>();
        
        for(Project_Task__c prj: [SELECT Id, Case__c FROM Project_Task__c WHERE Case__c != NULL]){
            projTaskViaCaseIdMap.put(prj.Case__c, prj.Id);
        }
        
        for(Case cs: [SELECT Id, Project_Task__c, Status, Resolution__c, Type, Create_Project_Task__c 
                        FROM Case WHERE Create_Project_Task__c = true]){

            if(cs.Type == 'Incident' || cs.Type == 'New Feature'){

                cs.Project_Task__c = projTaskViaCaseIdMap.get(cs.Id);
                cs.Status = 'Closed';
                cs.Resolution__c = 'Moved to CAPM';
                casesToUpdateList.add(cs);
            }
        }
        update casesToUpdateList;
    }
    
	/*******************************************************************************
    * @author           Iamca Cagurangan
    * @date             08.12.21
    * @description      CPM-55 Save automation error message to case field: Onboarding_Automation_Error__c  
    * @param        
    *******************************************************************************/
    @future
    public static void captureErrorMsg(String errorMsg, String objectName, String caseMap) {
        Map<Id,Case> newCases = (Map<Id,Case>)JSON.deserialize(caseMap, Map<Id,Case>.class);
        List<Case> caseToUpdate = new List<Case>();
        for(Case caseRec : newCases.values()){
            switch on objectName {
                when 'User' {
                    caseRec.Onboarding_Automation_Error__c = 'Error inserting user: '+errorMsg;
                }	
                when 'Contact' {
                    caseRec.Onboarding_Automation_Error__c = 'Error inserting contact: '+errorMsg;
                }
                when 'Project Resource' {
                    caseRec.Onboarding_Automation_Error__c = 'Error inserting project resource: '+errorMsg;
                }
            }
            caseToUpdate.add(caseRec);
        }
        
        update caseToUpdate;
    }
}