public class ReleaseItemTriggerHandler {
    public static boolean bPreventAI = false;
    public static boolean bPreventAU = false;
    public static boolean bPreventBI = false;
    public static boolean bPreventBU = false;
   
    public static void onBeforeInsert(List<Release_Item__c> newReleaseItemList,Map<Id, Release_Item__c> newReleaseItemMap,List<Release_Item__c> oldReleaseItemList, Map<Id, Release_Item__c> oldReleaseItemMap){
        Set<Id> releaseItemIds = releaseItemId(newReleaseItemList);
        if(releaseItemIds.Size() > 0){
            ReleaseItemTriggerUtility.updateReleaseItemDate(releaseItemIds, newReleaseItemList);
        }
    }
    
    public static void onBeforeUpdate(List<Release_Item__c> newReleaseItemList, Map<Id, Release_Item__c> newReleaseItemMap, List<Release_Item__c> oldReleaseItemList, Map<Id, Release_Item__c> oldReleaseItemMap){
        Set<Id> releaseItemIds = releaseItemId(newReleaseItemList);
        if(releaseItemIds.Size() > 0){
            ReleaseItemTriggerUtility.updateReleaseItemDate(releaseItemIds, newReleaseItemList);
        }
    }
    
    public static void onAfterInsert(List<Release_Item__c> newReleaseItemList, Map<Id, Release_Item__c> newReleaseItemMap, List<Release_Item__c> oldReleaseItemList, Map<Id, Release_Item__c> oldReleaseItemMap){
        Set<Id> devTaskToUpdate = devTaskId(newReleaseItemList);
        if(devTaskToUpdate.Size() > 0){
            ReleaseItemTriggerUtility.updateDevStatusToComplete(devTaskToUpdate);
        }
    }
    
    public static void onAfterUpdate(List<Release_Item__c> newReleaseItemList, Map<Id, Release_Item__c> newReleaseItemMap, List<Release_Item__c> oldReleaseItemList, Map<Id, Release_Item__c> oldReleaseItemMap){
        Set<Id> devTaskToUpdate = devTaskId(newReleaseItemList);
        if(devTaskToUpdate.Size() > 0){
            ReleaseItemTriggerUtility.updateDevStatusToComplete(devTaskToUpdate);
        }
    }
    
    /*
    public static void onAfterDelete(List<Release_Item__c> newReleaseItemList, Map<Id,Release_Item__c> newReleaseItemMap, List<Release_Item__c> oldReleaseItemList, Map<Id,Release_Item__c> oldReleaseItemMap){
    }
    public static void onBeforeDelete(List<Release_Item__c> newReleaseItemList, Map<Id,Release_Item__c> newReleaseItemMap, List<Release_Item__c> oldReleaseItemList, Map<Id,Release_Item__c> oldReleaseItemMap){
    }
    public static void onAfterUndelete(List<Release_Item__c> newReleaseItemList, Map<Id,Release_Item__c> newReleaseItemMap, List<Release_Item__c> oldReleaseItemList, Map<Id,Release_Item__c> oldReleaseItemMap){
    }*/
    
    public static Set<Id> devTaskId (List<Release_Item__c> releaseItemList){
        Set<Id> devTaskToUpdate = new Set<Id>();
        for(Release_Item__c releaseItem : releaseItemList){  
            if(releaseItem.Release_Item_Status__c == 'Completed' || releaseItem.Release_Item_Status__c == 'Closed'){
                devTaskToUpdate.add(releaseItem.Project_Task__c);
            }
        }
        return devTaskToUpdate;
    }
    
    public static Set<Id> releaseItemId (List<Release_Item__c> releaseItemList){
        Set<Id> releaseItemsToUpdate = new Set<Id>();
        for(Release_Item__c releaseItem : releaseItemList){
            If(String.IsBlank(String.valueof(releaseItem.Release_Date__c)) && releaseItem.Release__c != null){
                releaseItemsToUpdate.add(releaseItem.Id);
            }
        }
        return releaseItemsToUpdate;
    }

}