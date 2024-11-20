/**
* @description Trigger Handler Class for ProjectTaskTrigger 
* 
*           05/11/2021 - Kyzer Buhay - TriggerHandler Creation
*           Trigger class: ProjectTaskTrigger
**/
public class ProjectTaskTriggerHandler{
    // @author: [CCN-???] Updated by dinoBrinas
    // @description: This is used to avoid the recursive on the apex trigger.
    // @date: Nov052021
    public static boolean bPreventAI = false;
    public static boolean bPreventAU = false;
    public static boolean bPreventBI = false;
    public static boolean bPreventBU = false;
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  25-01-2022   VonPernicia          [CAPM-101] added projectIDForEpic and projectIDForFeature to pass new param
    * @version   2.1  09-08-2022   Rianno Rizarri       [CAPM-384] added assignOwnerToQATask..
    * @version   2.2  29-03-2023   Von Pernicia         [CAPM-AGL-453-DV]: added support logic
    * @version   2.3  03-04-2023   Von Pernicia         [CAPM-465]: update from Epic__c to Feature__c
    * @version   2.4  31-05-2023   Von Pernicia         [CAPM-PMG-579-DV]: This will compute Total_Open_Project_Tasks__c
                                                        [CAPM-677]: Total_Proposed_Hours__c
                                                        [CAPM-548]: This will auto populate project, epic, campaign and order
    ******************************************************************************/
    public static void onBeforeInsert(List<Project_Task__c> newProjectTaskList, Map<Id,Project_Task__c> newProjectTaskMap, 
                                      List<Project_Task__c> oldProjectTaskList, Map<Id,Project_Task__c> oldProjectTaskMap){
                                          
        List<Project_Task__c> projTaskRecordsOwner = new List<Project_Task__c>();        
        List<Project_Task__c> projTaskRecordsAssignedTo = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToInitializeSTN = new List<Project_Task__c>();                     
        List<Project_Task__c> projTaskRecordSprint = new List<Project_Task__c>();
        List<Project_Task__c> functionalityFromButtonList = new List<Project_Task__c>();
        List<Project_Task__c> bugFromButtonList = new List<Project_Task__c>();
        List<Project_Task__c> devFromButtonList = new List<Project_Task__c>();
        Set<Id> assignedToIDs = new Set<Id>();
        Set<Id> ownerIDs = new Set<Id>();
        Set<Id> projectIDs = new Set<Id>();
        Set<Id> projectIDForSTN = new Set<Id>();
        Set<Id> caseIDSet = new Set<Id>();
        Set<Id> projectIDForEpic = new Set<Id>();
        Set<Id> projectIDForFeature = new Set<Id>();
        
        // Start CAPM-677/CAPM-548/CAPM-PMG-579-DV
        List<Project_Task__c> ptWorkplanList = new List<Project_Task__c>();
        List<Id> workplanlist = new List<Id>();
        // End CAPM-677/CAPM-548/CAPM-PMG-579-DV

        //Id functionalityRecTypId = [SELECT Id From RecordType WHERE DeveloperName = 'Functionality' LIMIT 1].Id;                  
        // Start CAPM-AGL-453-DV: Von Pernicia - Added Support        
        Map<Id, RecordType> caseAutomationRecTypes = new Map<Id, RecordType>([Select Id, Name from RecordType WHERE Name IN ('Feature', 'Functionality', 'QA', 'Dev', 'Story', 'Bug', 'Support')]);
        // End CAPM-AGL-453-DV: Von Pernicia - Added Support
        try {                         
            for(Project_Task__c projTaskRecord : newProjectTaskList){
                if(!String.isBlank(projTaskRecord.Assigned_To__c)){
                    projTaskRecordsOwner.add(projTaskRecord);
                    assignedToIDs.add(projTaskRecord.Assigned_To__c);
                }
                
                if(String.isBlank(projTaskRecord.Assigned_To__c)){
                    projTaskRecordsAssignedTo.add(projTaskRecord);
                    ownerIDs.add(projTaskRecord.OwnerId);
                }
                
                if(String.isBlank(projTaskRecord.Sprint__c)){
                    projTaskRecordSprint.add(projTaskRecord);
                    projectIDs.add(projTaskRecord.Project__c);
                }
                if((caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Feature' && projTaskRecord.Convert_To_Feature__c == false) 
                    || (caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Functionality' && projTaskRecord.Convert_To_Functionality__c == false && projTaskRecord.From_Functionality_Button__c == false) 
                    || (caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Dev' && projTaskRecord.Convert__c == false && projTaskRecord.From_DevQA_Button_Story__c == false && projTaskRecord.From_DevQA_Button_Functionality__c == false)
                    || (caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Story') 
                    || (caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Bug' && projTaskRecord.From_Bug_Button__c == false)
                    || (caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Support') // Start/End CAPM-AGL-453-DV: Von Pernicia - Added Support   
                    || (caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'QA') ){  // Start CAPM-685: Von Pernicia - Added new logic for QA if not related to any Dev task
                          
                    projTaskListToInitializeSTN.add(projTaskRecord);
                }    
                if(!String.isBlank(projTaskRecord.Case__c)){
                    caseIDSet.add(projTaskRecord.Case__c);
                }
                if(caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Functionality' && projTaskRecord.From_Functionality_Button__c == true  ){
                    functionalityFromButtonList.add(projTaskRecord);
                }
                if(caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Bug' && projTaskRecord.From_Bug_Button__c == true  ){
                    bugFromButtonList.add(projTaskRecord);
                }
                if(caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'Dev' && (projTaskRecord.From_DevQA_Button_Story__c == true || projTaskRecord.From_DevQA_Button_Functionality__c == true)){
                    devFromButtonList.add(projTaskRecord);
                }
                /* Start CAPM-PMG-662-DV 5/23/23: added new condition to validate if Dev task is populated when created from Project Task tab*/
                if (caseAutomationRecTypes.get(projTaskRecord.RecordTypeId).Name == 'QA' 
                    && projTaskRecord.Dev_Task__c <> NULL
                    && (projTaskRecord.From_DevQA_Button_Story__c == false || projTaskRecord.From_DevQA_Button_Functionality__c == false)) {
                        projTaskRecord.AddError ('You are not allowed to populate Dev task field when creating QA manually.');
                }
                /* End CAPM-PMG-662-DV 5/23/23 */

                // Start CAPM-677/CAPM-548/CAPM-PMG-579-DV
                if (!String.isBlank(projTaskRecord.Workplan__c)) {
                    ptWorkplanList.add(projTaskRecord);
                    workplanlist.add(projTaskRecord.Workplan__c);
                }
                // End CAPM-677/CAPM-548/CAPM-PMG-579-DV

                projectIDForSTN.add(projTaskRecord.Project__c); 
                projectIDForEpic.add(projTaskRecord.Epic__c);
                projectIDForFeature.add(projTaskRecord.Feature__c); // Start/End CAPM-465: Von Pernicia - update from Epic__c to Feature__c
            }         

            // Start CAPM-677/CAPM-548/CAPM-PMG-579-DV
            if(ptWorkplanList.size() > 0){
                ProjectTaskTriggerUtility.assignPTFromWorkplan(ptWorkplanList, workplanlist, true);
            }
            // End CAPM-677/CAPM-548/CAPM-PMG-579-DV

            if(projTaskRecordsOwner.size() > 0){
                ProjectTaskTriggerUtility.processAssignedToAsOwner(projTaskRecordsOwner, assignedToIDs);
            }

            if(projTaskRecordsAssignedTo.size() > 0){
                ProjectTaskTriggerUtility.updateAssignedTo(projTaskRecordsAssignedTo, ownerIDs);
            }
                                
            if(projTaskRecordSprint.size() > 0 && ptWorkplanList.size() == 0){
                ProjectTaskTriggerUtility.processSprint(projTaskRecordSprint, projectIDs);
            }
                                
            if(projTaskListToInitializeSTN.size() > 0 && ptWorkplanList.size() == 0){
                ProjectTaskTriggerUtility.initializeProjectTaskNumber(projTaskListToInitializeSTN, projectIDForSTN, projectIDForEpic, projectIDForFeature);
            }
            if(caseIDSet.size() > 0){
                CaseTriggerUtility.updateCaseMovedToCAPM(caseIDSet);
            }
            if(functionalityFromButtonList.size() > 0){
                ProjectTaskTriggerUtility.createFunctionalityTaskFromFeature(oldProjectTaskMap, functionalityFromButtonList);
            }
            if(bugFromButtonList.size() > 0){
                ProjectTaskTriggerUtility.createBugTaskFromQA(oldProjectTaskMap, bugFromButtonList);
            }
            if(devFromButtonList.size() > 0){
                ProjectTaskTriggerUtility.createDevTaskFromButton(oldProjectTaskMap, devFromButtonList);
            }
            ProjectTaskTriggerUtility.removeDueDatesWhenBacklog(null, newProjectTaskList);
            ProjectTaskTriggerUtility.updateDueDatesBySprint(oldProjectTaskMap, newProjectTaskList);
            //Start CAPM-384: Rianno Rizarri
            ProjectTaskTriggerUtility.assignOwnerToQATask(newProjectTaskList);
            //End CAPM-384: Rianno Rizarri
        } catch (Exception e) {
            //validate(newProjectTaskList);
        }
        
    }

    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  25-01-2022   VonPernicia          [CAPM-101] updated filter criteria to update projTaskToReparent
    *                                                   [CAPM-101] commented out updateFunctionalityName
    *            3.0  28-03-2022   Von Pernicia         [CAPM-229] added validation for QA recordtype to prevent the user to update project, epic and dev QA record is related to dev
    *            4.0  23-05-2023   Von Pernicia         [CAPM-PMG-662-DV] Removed trigger validation
    ******************************************************************************/
    public static void onBeforeUpdate(List<Project_Task__c> newProjectTaskList, Map<Id,Project_Task__c> newProjectTaskMap,
                                    List<Project_Task__c> oldProjectTaskList, Map<Id,Project_Task__c> oldProjectTaskMap){
                                       
        List<Project_Task__c> projTaskRecordsOwner = new List<Project_Task__c>();
        List<Project_Task__c> projTaskRecordsAssignedTo = new List<Project_Task__c>();
        List<Project_Task__c> projTaskRecordSprint = new List<Project_Task__c>();
        List<Project_Task__c> projTaskToReparent = new List<Project_Task__c>();
        List<Project_Task__c> projTaskToWorkTasks = new List<Project_Task__c>();
        Set<Id> assignedToIDs = new Set<Id>();
        Set<Id> ownerIDs = new Set<Id>();
        Set<Id> projectIDs = new Set<Id>();
        Set<Id> projectIDForSTN = new Set<Id>();
        Set<Id> projectIDForEpic = new Set<Id>();
        Set<Id> projectIDForFeature = new Set<Id>();
        Set<Id> projectIDForQAValidation = new Set<Id>();

        Id recordTypeIDFunctionality = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Functionality').getRecordTypeId();
        Id recordTypeIDQA = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('QA').getRecordTypeId();
        
        try {
            for(Project_Task__c projTaskRecord : newProjectTaskMap.values()){

                if(!String.isBlank(projTaskRecord.Assigned_To__c)
                    && projTaskRecord.Assigned_To__c != oldProjectTaskMap.get(projTaskRecord.Id).Assigned_To__c){
                    projTaskRecordsOwner.add(projTaskRecord);
                    assignedToIDs.add(projTaskRecord.Assigned_To__c);
                }
                
                if(String.isBlank(projTaskRecord.Assigned_To__c) || projTaskRecord.OwnerId != oldProjectTaskMap.get(projTaskRecord.Id).OwnerId){
                    projTaskRecordsAssignedTo.add(projTaskRecord);
                    ownerIDs.add(projTaskRecord.OwnerId);
                }

                if(String.isBlank(projTaskRecord.Sprint__c)){
                    projTaskRecordSprint.add(projTaskRecord);
                    projectIDs.add(projTaskRecord.Project__c);
                }

                if(projTaskRecord.Project__c != oldProjectTaskMap.get(projTaskRecord.Id).Project__c || projTaskRecord.Epic__c != oldProjectTaskMap.get(projTaskRecord.Id).Epic__c
                || (projTaskRecord.Feature__c != oldProjectTaskMap.get(projTaskRecord.Id).Feature__c && projTaskRecord.RecordTypeId == recordTypeIDFunctionality)
                ){
                    projTaskToReparent.add(projTaskRecord);
                }

                /* Start CAPM-PMG-662-DV 5/23/23: Removed projTaskRecord.Dev_Task__c != oldProjectTaskMap.get(projTaskRecord.Id).Dev_Task__c)*/
                // Start CAPM-229
                if((projTaskRecord.Project__c != oldProjectTaskMap.get(projTaskRecord.Id).Project__c 
                  || projTaskRecord.Epic__c != oldProjectTaskMap.get(projTaskRecord.Id).Epic__c)
                  && projTaskRecord.Dev_Task__c <> NULL
                  && projTaskRecord.RecordTypeId == recordTypeIDQA ){
                    
                    projTaskRecord.AddError ('You are not allowed to change Project or Epic field.');
                }
                // End CAPM-229
                /* End CAPM-PMG-662-DV 5/23/23 */
                
                projectIDForSTN.add(projTaskRecord.Project__c);
                projectIDForEpic.add(projTaskRecord.Epic__c);
                projectIDForFeature.add(projTaskRecord.Feature__c);
            }

            if(projTaskRecordsOwner.size() > 0){
                ProjectTaskTriggerUtility.processAssignedToAsOwner(projTaskRecordsOwner, assignedToIDs);
            }
                                
            if(projTaskRecordsAssignedTo.size() > 0){
                ProjectTaskTriggerUtility.updateAssignedTo(projTaskRecordsAssignedTo, ownerIDs);
            }
                                
            if(projTaskRecordSprint.size() > 0){
                ProjectTaskTriggerUtility.processSprint(projTaskRecordSprint, projectIDs);
            }

            if(projTaskToReparent.size() > 0){
                ProjectTaskTriggerUtility.initializeProjectTaskNumber(projTaskToReparent, projectIDForSTN, projectIDForEpic, projectIDForFeature);
            }

            //ProjectTaskTriggerUtility.createDevTask(oldProjectTaskMap, newProjectTaskMap);
            ProjectTaskTriggerUtility.createFeatureTask(oldProjectTaskMap, newProjectTaskList);
            ProjectTaskTriggerUtility.createFunctionalityTask(oldProjectTaskMap, newProjectTaskList);
            ProjectTaskTriggerUtility.storePreviousTaskNumber(oldProjectTaskMap, newProjectTaskList);
            ProjectTaskTriggerUtility.removeDueDatesWhenBacklog(oldProjectTaskMap, newProjectTaskList);
            ProjectTaskTriggerUtility.updateDueDatesBySprint (oldProjectTaskMap, newProjectTaskList);
            //ProjectTaskTriggerUtility.updateFunctionalityName(oldProjectTaskMap, newProjectTaskMap);   

        } catch (Exception e) {
            //validate(newProjectTaskList);
        }
    }

    public static void validate(List<Project_Task__c> newProjectTaskList) {

        String errorMsg;
        Id recordTypeIDDev = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Dev').getRecordTypeId();
        Id recordTypeIDFeature = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Feature').getRecordTypeId();
        Id recordTypeIDFunctionality = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Functionality').getRecordTypeId();

        for(Project_Task__c projTaskRecord : newProjectTaskList){

            errorMsg = '';
            if (projTaskRecord.RecordTypeId == recordTypeIDDev || projTaskRecord.RecordTypeId == recordTypeIDFeature || projTaskRecord.RecordTypeId == recordTypeIDFunctionality) {
                
                if (String.isEmpty(String.valueOf(projTaskRecord.Project__c))) {
                    errorMsg = 'Project';
                }

                if (String.isEmpty(String.valueOf(projTaskRecord.Epic__c))) {
                    if (!String.isEmpty(errorMsg)) {
                        errorMsg += ', Epic';
                    } else {
                        errorMsg += 'Epic';
                    }
                }
            }

            if (projTaskRecord.RecordTypeId == recordTypeIDFunctionality) {
                if (String.isEmpty(String.valueOf(projTaskRecord.Feature__c))) {
                    if (!String.isEmpty(errorMsg)) {
                        errorMsg += ', Feature';
                    } else {
                        errorMsg += 'Feature';
                    }
                }
            }

            if (!String.isEmpty(errorMsg)) {
                projTaskRecord.AddError ('Please populate the following field(s): "' + errorMsg + '"');
            }
        }  
    }

    public static void onAfterInsert(List<Project_Task__c> newProjectTaskList, Map<Id,Project_Task__c> newProjectTaskMap,
                                    List<Project_Task__c> oldProjectTaskList, Map<Id,Project_Task__c> oldProjectTaskMap){
        List<Project_Task__c> prjTaskToTransferAtchList = new List<Project_Task__c>();
        List<Project_Task__c> projTaskListToInitializeSTN = new List<Project_Task__c>();
        List<Project_Task__c> qaPartnerList = new List<Project_Task__c>();
        Set<Id> convertedStorySet = new Set<Id>();
        Set<Id> computeStoryEstmatedHrIdSet = new Set<Id>(); 
        Map<Id, RecordType> caseAutomationRecTypes = new Map<Id, RecordType>([Select Id, Name from RecordType WHERE Name IN ('Feature', 'Functionality', 'QA', 'Dev', 'Story', 'Bug')]);

        for(Project_Task__c prjTsk: newProjectTaskList){
            if(!String.isBlank(prjTsk.Case__c)){
                prjTaskToTransferAtchList.add(prjTsk);
            }
            if(prjTsk.From_DevQA_Button_Story__c == true && caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Dev'){
                convertedStorySet.add(prjTsk.Source_Story__c);
            }
            if(prjTsk.Estimated_Hours__c > 0){
                computeStoryEstmatedHrIdSet.add(prjTsk.Id);
            }
        }

        if(prjTaskToTransferAtchList.size()>0){
            ProjectTaskTriggerUtility.transferAttachFromCase(prjTaskToTransferAtchList); 
        }
        if(convertedStorySet.size()>0){
            ProjectTaskTriggerUtility.updateStoryToConverted(convertedStorySet);
        }
                                        
        ProjectTaskTriggerUtility.incrementStartingTaskNum(newProjectTaskList);
        ProjectTaskTriggerUtility.createQATask(newProjectTaskList);
        if (!computeStoryEstmatedHrIdSet.isEmpty()) {
            ProjectTaskTriggerUtility.computeStoryEstimatedHrs(computeStoryEstmatedHrIdSet);
            ProjectTaskTriggerUtility.computeSprintEstimatedHrs(computeStoryEstmatedHrIdSet); //CAPM-AGL-350-DV
        }
                                        
        // Start CAPM-AGL-852-DV
        ProjectTaskTriggerUtility.assignedToNotification(newProjectTaskMap, null);
        // End CAPM-AGL-852-DV       
    }
    
    /******************************************************************************    
    * Changes (version)
    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  ??           ??                   Initial version.
    * @version   2.0  25-01-2022   VonPernicia          [CAPM-101] added updateQATask to update Project Task Number for QA whenever dev Project Task Number is updated
    * @version   3.0  23-04-2022   VonPernicia          [CAPM-AGL-277-DV] added computeStoryEstmatedHrIdSet to update Story Project Task Estimated Hrs
                                                        and submit approval once Status is set to "For Approval"
    * @version   4.0  31-05-2023   Von Pernicia         [CAPM-PMG-579-DV]: This will compute Total_Open_Project_Tasks__c
                                                        [CAPM-677]: Total_Proposed_Hours__c
                                                        [CAPM-548]: This will auto populate project, epic, campaign and order                                                    
    ******************************************************************************/
    public static void onAfterUpdate(List<Project_Task__c> newProjectTaskList, Map<Id,Project_Task__c> newProjectTaskMap, 
                                     List<Project_Task__c> oldProjectTaskList, Map<Id,Project_Task__c> oldProjectTaskMap){

        List<Project_Task__c> prjTaskList = new List<Project_Task__c>();
        List<Project_Task__c> prjTaskForApprovalList = new List<Project_Task__c>();
        Set<Id> computeStoryEstmatedHrIdSet = new Set<Id>();
        Id recordTypeIDStory = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Story').getRecordTypeId();
        
        // Start CAPM-677/CAPM-548/CAPM-PMG-579-DV
        List<Project_Task__c> ptWorkplanList = new List<Project_Task__c>();
        List<Id> workplanlist = new List<Id>();
        // End CAPM-677/CAPM-548/CAPM-PMG-579-DV
 
        for(Project_Task__c projTask: newProjectTaskList){
            // CAPM-101 added epic to trigger update of project task number
            // CAPM-AGL-11-DV added status and qa smoke sign-off to trigger update of proj task
            if(oldProjectTaskMap.get(projTask.Id).Project__c != projTask.Project__c || oldProjectTaskMap.get(projTask.Id).Epic__c != projTask.Epic__c ||
                oldProjectTaskMap.get(projTask.Id).Status__c != projTask.Status__c || projTask.Sign_off_Smoke__c == TRUE){
                prjTaskList.add(projTask);
            }

            // CAPM-AGL-277-DV added computeStoryEstmatedHrIdSet to update Story Project
            if(oldProjectTaskMap.get(projTask.Id).Estimated_Hours__c != projTask.Estimated_Hours__c ){
                computeStoryEstmatedHrIdSet.add(projTask.Id);
            }
            // CAPM-AGL-277-DV added submit approval once Status is set to "For Approval"
            if(oldProjectTaskMap.get(projTask.Id).Status__c != projTask.Status__c
                && !String.isEmpty(oldProjectTaskMap.get(projTask.Id).Status__c)
                && projTask.Status__c == 'For Approval' 
                && projTask.RecordTypeId == recordTypeIDStory){
                prjTaskForApprovalList.add(projTask);
            }

            // Start CAPM-677/CAPM-548/CAPM-PMG-579-DV
            if (!String.isBlank(projTask.Workplan__c)) {

                if (projTask.Proposed_Hours__c != oldProjectTaskMap.get(projTask.Id).Proposed_Hours__c) {
                    ptWorkplanList.add(projTask);
                    workplanlist.add(projTask.Workplan__c);
                }

                if (projTask.Workplan__c != oldProjectTaskMap.get(projTask.Id).Workplan__c) {
                    ptWorkplanList.add(projTask);
                    workplanlist.add(projTask.Workplan__c);
                    workplanlist.add(oldProjectTaskMap.get(projTask.Id).Workplan__c);
                }

                if (projTask.Status__c != oldProjectTaskMap.get(projTask.Id).Status__c) {
                    ptWorkplanList.add(projTask);
                    ptWorkplanList.add(oldProjectTaskMap.get(projTask.Id));
                    workplanlist.add(projTask.Workplan__c);
                }
            }
            
            // End CAPM-677/CAPM-548/CAPM-PMG-579-DV
        }

        // Start CAPM-677/CAPM-548/CAPM-PMG-579-DV
        if(ptWorkplanList.size() > 0){
            ProjectTaskTriggerUtility.assignPTFromWorkplan(ptWorkplanList, workplanlist, false);
        }
        // End CAPM-677/CAPM-548/CAPM-PMG-579-DV

        if(prjTaskList.size() > 0){
            ProjectTaskTriggerUtility.incrementStartingTaskNum(prjTaskList);
            // CAPM-101 added new method to update of QA project task number if dev project task number is updated
            ProjectTaskTriggerUtility.updateQATask(newProjectTaskMap);

            // CAPM-AGL-11-DV added new method to update related QA/Dev/Bug task status
            ProjectTaskTriggerUtility.updateRelatedProjTasks(prjTaskList);
        }

        // CAPM-AGL-277-DV added computeStoryEstmatedHrIdSet to update Story Project
        if (!computeStoryEstmatedHrIdSet.isEmpty()) {
            ProjectTaskTriggerUtility.computeStoryEstimatedHrs(computeStoryEstmatedHrIdSet);
            ProjectTaskTriggerUtility.computeSprintEstimatedHrs(computeStoryEstmatedHrIdSet); //CAPM-AGL-350-DV
        }
        

        // CAPM-AGL-277-DV added submit approval once Status is set to "For Approval"
        if (!prjTaskForApprovalList.isEmpty()) {
            ProjectTaskTriggerUtility.submitApprovalProcess(prjTaskForApprovalList);
        }
                                         
        // Start CAPM-AGL-852-DV
        ProjectTaskTriggerUtility.assignedToNotification(newProjectTaskMap, oldProjectTaskMap);
        // End CAPM-AGL-852-DV       
    }
    
    /******************************************************************************
    * @author       Von Pernicia
    * @date         31-05-2023
    * @description  This will workplan counts

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  31-05-2023   Von Pernicia         [CAPM-PMG-579-DV]: This will compute Total_Open_Project_Tasks__c
                                                        [CAPM-677]: Total_Proposed_Hours__c
                                                        [CAPM-548]: This will auto populate project, epic, campaign and order
    ******************************************************************************/
    public static void onAfterDelete(List<Project_Task__c> newProjectTaskList, Map<Id,Project_Task__c> newProjectTaskMap, 
                                     List<Project_Task__c> oldProjectTaskList, Map<Id,Project_Task__c> oldProjectTaskMap){

        List<Project_Task__c> ptWorkplanList = new List<Project_Task__c>();
        List<Id> workplanlist = new List<Id>();
        
        for(Project_Task__c projTask: oldProjectTaskList){
            ptWorkplanList.add(projTask);
            workplanlist.add(projTask.Workplan__c);            
        }

        if(ptWorkplanList.size() > 0){
            ProjectTaskTriggerUtility.assignPTFromWorkplan(ptWorkplanList, workplanlist, false);
        }
    }
    
    /*public static void onBeforeDelete(List<Project_Task__c> newProjectTaskList, Map<Id,Project_Task__c> newProjectTaskMap, 
                                      List<Project_Task__c> oldProjectTaskList, Map<Id,Project_Task__c> oldProjectTaskMap){
    }
    public static void onAfterUndelete(List<Project_Task__c> newProjectTaskList, Map<Id,Project_Task__c> newProjectTaskMap, 
                                       List<Project_Task__c> oldProjectTaskList, Map<Id,Project_Task__c> oldProjectTaskMap){
    }*/
}