public class ReleaseItemTriggerUtility {
    public static void updateDevStatusToComplete(Set<Id> DevTaskIdSet){
        List<Project_Task__c> projTaskList = [Select Id, Status__c from Project_Task__c where Id IN: DevTaskIdSet];
        for(Project_Task__c projTaskRec: projTaskList){
            projTaskRec.Sign_off_Technical_Review__c = true;
            //10/05/2023 - Updated by MGP - CAPM-PMG-877-DV
            //projTaskRec.Status__c = 'Completed';
            projTaskRec.Status__c = 'Deployed';
        }
        database.update(projTaskList);
    }
    
    public static void updateReleaseItemDate(Set<Id> releaseItemId, List<Release_Item__c> releaseItemList){
        Map<Id,Date> releaseItemMap = new Map<Id,Date>();
        List<Release_Item__c> releaseItemListToUpdate = [Select Id, Release_Date__c, Release__c, Release__r.Release_Date__c from Release_Item__c where Id IN: releaseItemId];
        for(Release_Item__c releaseItemRec: releaseItemListToUpdate){
            releaseItemMap.put(releaseItemRec.Id, releaseItemRec.Release__r.Release_Date__c); 
        }
        for(Release_Item__c releaseItemRec: releaseItemList){
            releaseItemRec.Release_Date__c = releaseItemMap.get(releaseItemRec.Id);
        }
    }
}