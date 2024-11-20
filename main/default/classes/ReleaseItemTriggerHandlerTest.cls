@IsTest
public class ReleaseItemTriggerHandlerTest {

    @TestSetup
    static void createData(){
        Apex_Trigger_Switch__c switchh = new Apex_Trigger_Switch__c();
        switchh.Name = 'ReleaseItemTrigger';
        switchh.Active__c = true;
        insert switchh;
        
        Project__c projRecord = new Project__c();
        projRecord.Project_Code__c = '0000';
        projRecord.Name = 'Test Project #A';
        projRecord.Starting_Task_Number__c = 0;
        projRecord.Task_Number_Display_Format__c = '{mm}';
        insert projRecord;
        
        Sprint__c dBacklogSprint = new Sprint__c();
        dBacklogSprint.Name = 'Backlog (Test Project #A)';
        dBacklogSprint.Project__c = projRecord.Id;
        dBacklogSprint.End_Date__c = system.today();
        insert dBacklogSprint;
        
        Epic__c epic = new Epic__c();
        epic.Project__c = projRecord.Id;
        epic.Epic_Code__c = 'E1';
        insert epic;
        
        Project_Task__c projTask = new Project_Task__c();
        projTask.Sprint__c = dBacklogSprint.Id;
        projTask.Project__c = projRecord.Id;
        projTask.Epic__c = epic.Id;
        projTask.Status__c = 'New';
        projTask.RecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType='Project_Task__c' AND DeveloperName LIKE '%Story%' LIMIT 1].Id;
        projTask.Feature_Code__c = 'Test';
        insert projTask;
        
        Release__c release = new Release__c();
        release.Project__c = projRecord.Id;
        release.Release_Date__c = System.today();        
        insert release;
    }

    @IsTest
    static void ApexTriggerSwitchTest(){
        // Commented by dinoBrinas Nov52021
        //Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance('ReleaseItemTrigger');
        //switchh.Active__c = true;
        //update switchh;
        
        
        
        Project_Task__c devTaskRec = [Select Id, Status__c from Project_Task__c Limit 1];
        Release__c releaseRec = [Select Id, Release_Date__c from Release__c Limit 1];
        List<Release_Item__c> releaseItemList = new List<Release_Item__c>();
        for(Integer i = 0; i < 3; i ++){
            Release_Item__c newReleaseItemRec = new Release_Item__c();
            newReleaseItemRec.Project_Task__c = devTaskRec.id;
            newReleaseItemRec.Release__c = releaseRec.Id;
            newReleaseItemRec.Release_Item_Status__c = 'Completed';
            releaseItemList.add(newReleaseItemRec);
        }
        insert releaseItemList;
    }

    @IsTest
    static void releaseItemInsertTest(){
        Project_Task__c devTaskRec = [Select Id, Status__c from Project_Task__c Limit 1];
        Release__c releaseRec = [Select Id, Release_Date__c from Release__c Limit 1];
        List<Release_Item__c> releaseItemList = new List<Release_Item__c>();
        for(Integer i = 0; i < 3; i ++){
            Release_Item__c newReleaseItemRec = new Release_Item__c();
            newReleaseItemRec.Project_Task__c = devTaskRec.id;
            newReleaseItemRec.Release__c = releaseRec.Id;
            newReleaseItemRec.Release_Item_Status__c = 'Completed';
            releaseItemList.add(newReleaseItemRec);
        }
        insert releaseItemList;
    }
    
    @IsTest
    static void releaseItemUpdateTest(){
        Project_Task__c devTaskRec = [Select Id, Status__c from Project_Task__c Limit 1];
        Release__c releaseRec = [Select Id, Release_Date__c from Release__c Limit 1];
        List<Release_Item__c> releaseItemList = new List<Release_Item__c>();
        for(Integer i = 0; i < 3; i ++){
            Release_Item__c newReleaseItemRec = new Release_Item__c();
            newReleaseItemRec.Project_Task__c = devTaskRec.id;
            newReleaseItemRec.Release__c = releaseRec.Id;
            newReleaseItemRec.Release_Item_Status__c = 'Completed';
            releaseItemList.add(newReleaseItemRec);
        }
        insert releaseItemList;
        
        List<Release_Item__c> releaseListUp = [Select Id, Status__c from Release_Item__c];
        for(Release_Item__c releaseItem : releaseListUp){
            releaseItem.Release_Item_Status__c = 'Completed';
        }
        update releaseListUp;
    }
}