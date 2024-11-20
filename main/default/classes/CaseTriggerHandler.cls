public without sharing class CaseTriggerHandler {
    
    public static void onAfterUpdate(List<Case> newCaseList, Map<Id,Case> newCaseMap,List<Case> oldCaseList, Map<Id,Case> oldCaseMap){
        
        Map<Id, Case> caseMapToMove  = new Map<Id,Case>();

        for(Case cs: newCaseList){
            if(oldCaseMap.get(cs.Id).Create_Project_Task__c != cs.Create_Project_Task__c 
                            && cs.Create_Project_Task__c == true){
                caseMapToMove.put(cs.id,cs);
            }
        }

        if(caseMapToMove.size() > 0){
            CaseTriggerUtility.createStoryFromACase(caseMapToMove);
        }
        //Onboarding Automation Task 1
        
        //User - Contact - Project Resource - Work Schedule - Email
        
        //Full-Time/Contract/External
        //1. Create User
        //2. Assign the user to the case field – Onboarding User
        //3. Add permission sets to user
        //4. Add installed packaged license to user
        //5. Create a contact for the user
        //6. Assign the contact to the case field – Onboarding Contact
        //7. Create a Project Resource
        //8. Create Work Schedule
        //9. Add error case onboarding automation error field ------  PENDING!!!!!!!!!!!!!!!!!!!!!!!!!!!
        if(newCaseList[0].Subject != null && newCaseList[0].Subject.contains('Onboarding')) {
            System.enqueueJob(new ContactCreationQueueable(newCaseMap, oldCaseMap)); 
        } 
    }
}