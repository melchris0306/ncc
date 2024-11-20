/**
* @description Utlity Handler Class for ProjectTaskTriggerHandler 
* 
*           05/12/2021 - Kyzer Buhay - Utility creation
*           Trigger class: ProjectTaskTrigger
d ProjectTaskTriggerHandler
**/
public class ProjectTaskTriggerUtility { 

    /*******************************************************************************
    * @author       Kyzer Buhay
    * @date         05.12.2021
    * @description  Updates Project Task Owner with Community User's User record
    * @param        projectTasks - Project Task Records where Assigned_To__c fields are changed
    *               assignedToIDs - Compiled Assigned_To__c (Contact) Ids to be used to query their user record
    *******************************************************************************/
    public static void processAssignedToAsOwner(List<Project_Task__c> projectTasks, Set<Id> assignedToIDs){        
        
        List<User> userRecords = [SELECT Id, ContactId FROM User WHERE ContactId IN: assignedToIDs];
        
        Map<Id, Id> contactUserMap = new Map<Id, Id>();
        for(User u : userRecords){
            contactUserMap.put(u.ContactId, u.Id);
        }
        
        List<Project_Task__c> noUserProjectTask = new List<Project_Task__c>();
        Set<Id> contactIdWithoutUserSet = new Set<Id>();
        for(Project_Task__c pt : projectTasks){
            if(!String.isBlank(contactUserMap.get(pt.Assigned_To__c))){
                pt.OwnerId = contactUserMap.get(pt.Assigned_To__c);
            }else{
                noUserProjectTask.add(pt);
                contactIdWithoutUserSet.add(pt.Assigned_To__c);
            }
            pt.Is_Assigned_To_Manually_Updated__c = true;
        }
        
        List<Project_Task__c> projectOwnerAsOwnerPT = new List<Project_Task__c>();
        Set<Id> projId = new Set<Id>();
        
        if(noUserProjectTask.size() > 0){
            List<Contact> conList = [SELECT Id, Email FROM Contact WHERE Id IN: contactIdWithoutUserSet];
            Map<String, Id> emailContactMap = new Map<String, Id>();
            for(Contact con : conList){
                emailContactMap.put(con.Email, con.Id);
            }
            
            List<User> userList = [SELECT Id, Email FROM User WHERE Email IN: emailContactMap.keySet()];
            Map<String, Id> emailUserMap = new Map<String, Id>();
            for(User userRec : userList){              
                emailUserMap.put(emailContactMap.get(userRec.Email), userRec.Id);
            }
            
            
            for(Project_Task__c projTask : noUserProjectTask){
                if(!String.isBlank(emailUserMap.get(projTask.Assigned_To__c))){
                    projTask.OwnerId = emailUserMap.get(projTask.Assigned_To__c);
                }else{
                    projectOwnerAsOwnerPT.add(projTask);
                    projId.add(projTask.Project__c);
                }
            }
        }
        
        if(projectOwnerAsOwnerPT.size() > 0){
     
            Map<Id, Project__c> projectMap = new Map<Id, Project__c>([SELECT Id, OwnerId FROM Project__c WHERE Id IN: projId]);
            for(Project_Task__c projTaskAssignOwner : projectOwnerAsOwnerPT){
                projTaskAssignOwner.OwnerId = projectMap.get(projTaskAssignOwner.Project__c).OwnerId;
            }
        }
        
        
    }
    
    /*******************************************************************************
    * @author       Kyzer Buhay
    * @date         05.12.2021
    * @description  Updates Project Task Sprint with the Active Sprint else falls in a criteria on which Sprint to use
    * @param        projectTasks - Project Task Records where Sprint fields are blank
    *******************************************************************************/
    public static void processSprint(List<Project_Task__c> projectTasks, Set<Id> projectIDs){        
        List<Sprint__c> sprintRecords = [SELECT Id, Start_Date__c, End_Date__c, Project__c FROM Sprint__c WHERE Project__r.Id IN: projectIDs];
        Map<Id, Project__c> projectRecordsMap = new Map<Id, Project__c>([SELECT Id, Name, Default_Backlog__c, Do_Not_Require_Sprint__c FROM Project__c WHERE Id IN: projectIDs]);
        
        Map<Id, Sprint__c> activeMapSprint = new Map<Id, Sprint__c>();
        Map<Id, Sprint__c> futureMapSprint = new Map<Id, Sprint__c>();
        
        for(Sprint__c sprint : sprintRecords){
            if(sprint.Start_Date__c <=  System.today() && sprint.End_Date__c > System.today()){
                activeMapSprint.put(sprint.Project__c, sprint);
            }else if(sprint.Start_Date__c > System.today() && sprint.End_Date__c > System.today()){
                
                if(!futureMapSprint.containsKey(sprint.Project__c) || 
                   (futureMapSprint.get(sprint.Project__c).Start_Date__c > sprint.Start_Date__c)){
                    futureMapSprint.put(sprint.Project__c, sprint);
                }
            }
        }
        
        for(Project_Task__c projectTask : projectTasks){
            if(!projectRecordsMap.get(projectTask.Project__c).Do_Not_Require_Sprint__c){
                if(projectTask.Status__c != 'Backlog' && activeMapSprint.get(projectTask.Project__c) != null){
                    projectTask.Sprint__c = activeMapSprint.get(projectTask.Project__c).Id;
                }else if(projectTask.Status__c != 'Backlog' && activeMapSprint.get(projectTask.Project__c) == null){
                    if(futureMapSprint.get(projectTask.Project__c) != null){
                        projectTask.Sprint__c = futureMapSprint.get(projectTask.Project__c).Id;
                    }else{
                        projectTask.addError('No Active or Future Sprint Found related to ' + projectRecordsMap.get(projectTask.Project__c).Name);
                    }
                    
                }else{
                    projectTask.Sprint__c = projectRecordsMap.get(projectTask.Project__c).Default_Backlog__c;
                }
            }
        }
    }
    
    /*******************************************************************************
    * @author       Kyzer Buhay
    * @date         05.18.2021
    * @description  Updates Project Task Assigned To with a contact record that matches with the current record Owner
    * @param        projectTasks - Project Task Records where Assigned To is Empty or if OwnerId has been changed
    *******************************************************************************/
    public static void updateAssignedTo(List<Project_Task__c> projectTasks, Set<Id> ownerId){
        List<User> userRecords = [SELECT Id, Email, ContactId FROM User WHERE Id IN: ownerId];

        Map<String, Id> userEmailMap = new Map<String, Id>();
        for(User userRec : userRecords){
            if(String.isEmpty(userRec.ContactId)){
                userEmailMap.put(userRec.Email, userRec.Id);
            }
        }
        
        Map<String, Id> emailUserMap = new Map<String, Id>();
        List<Contact> conRecords = [SELECT Id, Email FROM Contact WHERE Email IN: userEmailMap.keySet()];
        for(Contact con : conRecords){
            emailUserMap.put(userEmailMap.get(con.Email), con.Id);
        }
        
        for(Project_Task__c ptRecord : projectTasks){
            ptRecord.Assigned_To__c = emailUserMap.get(ptRecord.OwnerId);
        }
    }
    
    /******************************************************************************
    * @author       Christian Doctolero
    * @date         05.28.2021
    * @description  Creates a unique identifier for the Project Task Number field using the formats in Project object
    * @param        projectTasks, projectIds, epicIds, featureIds

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  28-05-2021   Christian Doctolero  Initial version.
    * @version   2.0  25-01-2022   VonPernicia          [CAPM-101] added dev, functionality, feature recordtype in the logic to update name field whenever 
    *                                                   one of these fields (feature, epic and project fields) is updated.
    *                                                   [CAPM-101] added these param: projectIds, epicIds, featureIds
    * @version   2.2  29-03-2023   Von Pernicia         [CAPM-AGL-453-DV]: added support logic
    * @version   2.3  05-05-2023   Von Pernicia         [CAPM-685]: Added new logic for QA if not related to any Dev task
    ******************************************************************************/
    public static void initializeProjectTaskNumber(List<Project_Task__c> projectTaskList, Set<Id> projectIds, Set<Id> epicIds, Set<Id> featureIds){
    
        Map<Id, Project__c> projMap = new Map<Id, Project__c>([SELECT Id, Starting_Task_Number__c,Task_Number_Display_Format__c,Project_Code__c, Feature_Count__c, Functionality_Count__c FROM Project__c WHERE Id IN: projectIds]);
        
        DateTime dt = System.now();
        
        String stn;
        String tndf;
        String pc;
        String tndfm = dt.format('MM');    
        String tndfd = String.valueOf(dt.day());    
        String tndfy = dt.format('YYYY');
        
        Integer zeroSize; 
     
        Id recordTypeIDDev = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Dev').getRecordTypeId();
        Id recordTypeIDFeature = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Feature').getRecordTypeId();
        Id recordTypeIDFunctionality = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Functionality').getRecordTypeId();
        // Start CAPM-AGL-453-DV: Von Pernicia - Added Support
        Id recordTypeIDSupport = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Support').getRecordTypeId();
        // End CAPM-AGL-453-DV: Von Pernicia - Added Support

        Id recordTypeIDQA = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('QA').getRecordTypeId();
        
        Map<Id, String> featureCodeMap = new Map<Id, String>();        
        Map<Id, Epic__c> epicCodeMap = new Map<Id, Epic__c>([SELECT Id, Epic_Code__c FROM Epic__c WHERE Id IN: epicIds]);
        
        for(Project_Task__c pt: [SELECT Id, Feature_Code__c FROM Project_Task__c WHERE Id IN: featureIds]){
           
            featureCodeMap.put(pt.Id, pt.Feature_Code__c);
        }
        
        for(Project_Task__c pt : projectTaskList){
            
            pc = String.valueOf(projMap.get(pt.Project__c).Project_Code__c);
            tndf = String.valueOf(projMap.get(pt.Project__c).Task_Number_Display_Format__c);
            stn = String.valueOf(projMap.get(pt.Project__c).Starting_Task_Number__c);
            
            // Start CAPM-AGL-453-DV: Von Pernicia - Moved position of this logic to this line
            if(String.isBlank(stn)){
                stn = '1';
                projMap.get(pt.Project__c).Starting_Task_Number__c = 2;
            }
            else{
                stn = String.valueOf(projMap.get(pt.Project__c).Starting_Task_Number__c);
                projMap.get(pt.Project__c).Starting_Task_Number__c ++;
            }
            // End CAPM-AGL-453-DV: Von Pernicia - Moved position of this logic to this line
        
            if (pt.RecordTypeId == recordTypeIDDev ) { 
                
                pt.Name = pc + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c  + '-' + stn + '-DV';                
            } else if (pt.RecordTypeId == recordTypeIDFeature) {

                pt.Name = pc + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c + '-'  + String.valueOf(projMap.get(pt.Project__c).Feature_Count__c);
            } else if (pt.RecordTypeId == recordTypeIDFunctionality) {  
                
                String feature = featureCodeMap.containsKey(pt.Feature__c)? String.valueOf(featureCodeMap.get(pt.Feature__c)): '<FEA>';
                pt.Name = pc + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c + '-' + feature + '-' +  String.valueOf(projMap.get(pt.Project__c).Functionality_Count__c);
            } 
            // Start CAPM-AGL-453-DV: Von Pernicia - Added new logic for support
            else if (pt.RecordTypeId == recordTypeIDSupport) {  
                
                pt.Name = pc + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c + '-' + stn;
            } 
            // End CAPM-AGL-453-DV: Von Pernicia - Added new logic for support

            // Start CAPM-685: Von Pernicia - Added new logic for QA if not related to any Dev task
            else if (pt.RecordTypeId == recordTypeIDQA && pt.Dev_Task__c == null) {  
                pt.Name = pc + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c  + '-' + stn + '-QA';  
            } 
            // End CAPM-685: Von Pernicia - Added new logic for QA if not related to any Dev task
            else {
                
                if(String.isBlank(tndf)){
                    pt.Name = pc + '-' + stn;
                }
                else if(String.isNotBlank(stn) && String.isNotBlank(pc) && String.isNotBlank(tndf)){
                    tndf = tndf.toLowerCase();
                    zeroSize = tndf.countMatches('0');
                    stn = stn.leftPad(zeroSize, '0');
                    tndf = tndf.replaceAll('[0+]', '');
                    tndf = tndf.replace('{mm}', tndfm);
                    tndf = tndf.replace('{dd}', tndfd);
                    tndf = tndf.replace('{yyyy}', tndfy);
                    tndf = tndf.replace('{}', stn);
                    pt.Name = pc + '-' + tndf;
                }
            }
        }
    }
    
    /******************************************************************************
    * @author       Christian Doctolero
    * @date         06.1.2021
    * @description  Increments the Starting Task Number field in Project Object whenever a new project task is created
    * @param        projectTasks 
    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  01-06-2021   Christian Doctolero  Initial version.
    * @version   2.0  25-01-2022   VonPernicia          [CAPM-101] updated incremental logic for dev to use Starting_Task_Number__c instead of Dev_Count__c 
    ******************************************************************************/
    public static void incrementStartingTaskNum(List<Project_Task__c> projectTaskList){
        
        Map<Id, RecordType> caseAutomationRecTypes = new Map<Id, RecordType>([Select Id, Name from RecordType WHERE Name IN ('Feature', 'Functionality', 'QA', 'Dev', 'Story', 'Bug', 'Support' ,'Template')]);
        Set<Id> projIdSet = new Set<Id>();
        Set<Id> QATaskIds = new Set<Id>();
        
        for(Project_task__c prjTsk: projectTaskList)   
        {
            projIdSet.add(prjTsk.Project__c);
            QATaskIds.add(prjTsk.QA_Task__c);
        }
        
        Map<Id, Project__c> projMap = new map<Id, Project__C>([SELECT Id, Starting_Task_Number__c, Project_Code__c,Dev_Count__c, Feature_Count__c, Functionality_Count__c, Bug_Count__c FROM Project__c
                                                              WHERE Id IN: projIdSet]);
        
        
        Map<Id, Project_Task__c> bugCountMap = new Map<Id, Project_Task__c>([SELECT Id, Bug_Count__c FROM Project_Task__c WHERE Id IN: QATaskIds]);

        for(Project_task__c prjTsk: projectTaskList)   
        {
            if(
                //Nikki - Remove for fix in CAPM-101
                //(caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Feature' && prjTsk.Convert_To_Feature__c == false) || 
                //(caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Functionality' && prjTsk.Convert_To_Functionality__c == false && prjTsk.From_Functionality_Button__c == false) || 
            (caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Dev' && prjTsk.Convert__c == false && prjTsk.From_DevQA_Button_Story__c == false && prjTsk.From_DevQA_Button_Functionality__c == false)
            || (caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Dev')
            || (caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Story') 
            || (caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Support') 
            || (caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Bug' && prjTsk.From_Bug_Button__c == false)){  
                if(projMap.containsKey(prjTsk.Project__c)){
                    if(projMap.get(prjTsk.Project__c).Starting_Task_Number__c != NULL){
                        projMap.get(prjTsk.Project__c).Starting_Task_Number__c++;
                    }
                    else{
                        projMap.get(prjTsk.Project__c).Starting_Task_Number__c = 2;
                    }
                }
            }
            else{
                
                if(caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Dev'){
                    
                    if(projMap.get(prjTsk.Project__c).Starting_Task_Number__c != NULL){
                        projMap.get(prjTsk.Project__c).Starting_Task_Number__c++;
                    }
                    else{
                        projMap.get(prjTsk.Project__c).Starting_Task_Number__c = 2;
                    }
                } else if(caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Feature'){
                    if(projMap.containsKey(prjTsk.Project__c)){
                        if(projMap.get(prjTsk.Project__c).Feature_Count__c != NULL){
                            projMap.get(prjTsk.Project__c).Feature_Count__c++;
                        }
                        else{
                            projMap.get(prjTsk.Project__c).Feature_Count__c = 2;
                        }
                    }
                }
                else if(caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Functionality'){
                    if(projMap.get(prjTsk.Project__c).Functionality_Count__c != NULL){
                        projMap.get(prjTsk.Project__c).Functionality_Count__c++;
                    }
                    else{
                        projMap.get(prjTsk.Project__c).Functionality_Count__c = 2;
                    }
                }
                else if(caseAutomationRecTypes.get(prjTsk.RecordTypeId).Name == 'Bug'){
                    if(bugCountMap.get(prjTsk.QA_Task__c).Bug_Count__c != NULL){
                        bugCountMap.get(prjTsk.QA_Task__c).Bug_Count__c++;
                    }
                    else{
                        bugCountMap.get(prjTsk.QA_Task__c).Bug_Count__c = 2;
                    }
                }
            }
        }
        
        update projMap.values();
        update bugCountMap.values();
    }
    
    /******************************************************************************
    * @author       Christian Doctolero
    * @date         07.15.2021
    * @description  Whenever the status is equal to Backlog, remove the dates on the Build Due Date, UAT Due Date, and PROD Due Date.
    * @param        projectTasks 
    ******************************************************************************/
    public static void removeDueDatesWhenBacklog(Map<Id, Project_Task__c> oldProjTaskMap, List<Project_Task__c> newProjTaskList){
        
        for(Project_Task__c prjtsk: newProjTaskList){
           if(Trigger.isBefore && Trigger.isInsert){    
                if(oldProjTaskMap == null && prjtsk.Status__c == 'Backlog'){
                    prjtsk.Build_Due_Date__c = null;
                    prjtsk.UAT_Due_Date__c = null;
                    prjtsk.PROD_Due_Date__c = null;
                    //prjtsk.Sprint__c = null;
                }
            }
            else if(Trigger.isBefore && Trigger.isUpdate){
                if(prjtsk.Status__c != oldProjTaskMap.get(prjtsk.Id).Status__c && prjtsk.Status__c == 'Backlog'){
                    prjtsk.Build_Due_Date__c = null;
                    prjtsk.UAT_Due_Date__c = null;
                    prjtsk.PROD_Due_Date__c = null;
                    prjtsk.Sprint__c = null;
                }
            }
        }
    }
    
    /******************************************************************************
    * @author       Christian Doctolero
    * @date         07.16.2021
    * @description  Update the due dates whenever we populate or update the Sprint in a Project Task
    * @param        projectTasks 
    ******************************************************************************/
    public static void updateDueDatesBySprint(Map<Id, Project_Task__c> oldProjTaskMap, List<Project_Task__c> newProjTaskList){        
        Map<Id, Sprint__c> sprintMap = new Map<Id, Sprint__c>([SELECT End_Date__c FROM Sprint__c]);
        
        for(Project_Task__c prjtsk: newProjTaskList){
           if(Trigger.isBefore && Trigger.isInsert){    
                if(oldProjTaskMap == null && (prjtsk.Sprint__c != NULL) && (prjtsk.Status__c == null)){
                    prjtsk.PROD_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c;
                    prjtsk.UAT_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-5);
                    prjtsk.Build_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-8);
                    prjtsk.Status__c = 'New';
                }
                else if(oldProjTaskMap == null && (prjtsk.Sprint__c != NULL) && (prjtsk.Status__c != 'Backlog')){
                    prjtsk.PROD_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c;
                    prjtsk.UAT_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-5);
                    prjtsk.Build_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-8);
                }
            }
            else if(Trigger.isBefore && Trigger.isUpdate){
                    if(prjtsk.Sprint__c != oldProjTaskMap.get(prjtsk.Id).Sprint__c && (prjtsk.Sprint__c != NULL) && (prjtsk.Status__c == 'Backlog'|| prjtsk.Status__c == null)){
                    prjtsk.PROD_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c;
                    prjtsk.UAT_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-5);
                    prjtsk.Build_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-8);
                    prjtsk.Status__c = 'New';
                }
                else if(prjtsk.Sprint__c != oldProjTaskMap.get(prjtsk.Id).Sprint__c && (prjtsk.Sprint__c != NULL) && (prjtsk.Status__c != 'Backlog')){
                    prjtsk.PROD_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c;
                    prjtsk.UAT_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-5);
                    prjtsk.Build_Due_Date__c = sprintMap.get(prjtsk.Sprint__c).End_Date__c.addDays(-8);
                }
            }
        }
    }

    /******************************************************************************
    * @author       Christian Doctolero
    * @date         08.4.2021
    * @description  Transfer attachments from cases
    * @param        projectTasks 
    ******************************************************************************/
    public static void transferAttachFromCase(List<Project_Task__c> projectTaskList){
        
        Map<Id, ContentDocumentLink> atchViaEIDCaseMap = new Map<Id, ContentDocumentLink>();
        Map<Id, Id> casePrjTaskMap = new Map<Id, Id>();
        Set<Id> caseIds = new Set<Id>();
        List<ContentDocumentLink> cdlinkToAdd = new List<ContentDocumentLink>();
        List<ContentDocumentLink> cdlinkToDelete = new List<ContentDocumentLink>();
        
        for(Project_task__c prjTsk: projectTaskList)   
        {
            caseIds.add(prjTsk.Case__c);
            casePrjTaskMap.put(prjTsk.Case__c, prjTsk.Id);
        }
        
        for(ContentDocumentLink atch: [SELECT Id, ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink 
                                        where LinkedEntityId in: caseIds and LinkedEntity.Type='Case']){
            atchViaEIDCaseMap.put(atch.LinkedEntityId, atch);
            ContentDocumentLink newclnk = atch.clone();
            newclnk.LinkedEntityId = casePrjTaskMap.get(atch.LinkedEntityId);
            cdlinkToAdd.add(newclnk);
            cdlinkToDelete.add(atch);
        }

        insert cdlinkToAdd;
        delete cdlinkToDelete;
    }

    // /******************************************************************************
    // * @author       Christian Doctolero
    // * @date         08.19.2021
    // * @description  Whenever the Convert checkbox is enabled, create a dev task from a functionality
    // * @param        projectTasks 
    // ******************************************************************************/
    // public static void createDevTask(Map<Id, Project_task__c> oldProjTaskMap, Map<Id, Project_Task__c> newProjTaskMap){
    //     Id functionalityRecTypId = [SELECT Id From RecordType WHERE DeveloperName = 'Functionality' LIMIT 1].Id;  
    //     Id devRecTypeId = [SELECT Id From RecordType WHERE DeveloperName = 'Dev' LIMIT 1].Id;  
    //     Id defaultOwner = [SELECT Id, Name From User WHERE Email = 'kay@ulapp.co' AND IsActive = True LIMIT 1].Id; 
    //     Set<Id> projectIds = new Set<Id>();
    //     Set<Id> epicIds = new Set<Id>();
    //     Set<Id> featureIds = new Set<Id>();
    //     String recCount;

    //     Map<Id, Project_Task__c> projTaskMap = new Map<Id, Project_Task__c>([SELECT Id, Project__r.Project_Code__c, Epic__r.Epic_Code__c, Feature__r.Feature_Code__c, Project__r.Dev_Count__c FROM Project_Task__c WHERE Id IN: newProjTaskMap.keySet()]);

    //     String devTitle;
    //     List<Project_Task__c> devTaskToCreate = new List<Project_Task__c>();
    //     for(Project_Task__c pt: newProjTaskMap.values()){
    //         if(pt.Convert__c != oldProjTaskMap.get(pt.Id).Convert__c && pt.RecordTypeId == functionalityRecTypId){
    //             devTitle = pt.Title__c.replace('FU','DEV');

    //             if(projTaskMap.get(pt.Id).Project__r.Dev_Count__c == null ){
    //                 projTaskMap.get(pt.Id).Project__r.Dev_Count__c = 1;
    //             }

    //             devTaskToCreate.add(new Project_Task__c(
    //                 RecordTypeId = devRecTypeId,
    //                 //Parent_Project_Task__c = pt.Id,
    //                 Project__c = pt.Project__c, //To clarify
    //                 Epic__c = pt.Epic__c,
    //                 Functionality__c = pt.Id,
    //                 Feature__c = pt.Feature__c,
    //                 Priority__c = 'Normal',
    //                 Description__c = pt.Description__c,
    //                 Status__c = 'New',
    //                 OwnerId = defaultOwner,
    //                 Title__c = devTitle,
    //                 Convert__c = True,
    //                 Name = projTaskMap.get(pt.Id).Project__r.Project_Code__c + '-' + projTaskMap.get(pt.Id).Epic__r.Epic_Code__c + '-' + projTaskMap.get(pt.Id).Feature__r.Feature_Code__c 
    //                     + '-' + pt.Functionality_Code__c + '-DEV-' + projTaskMap.get(pt.Id).Project__r.Dev_Count__c
    //             ));
    //             projTaskMap.get(pt.Id).Project__r.Dev_Count__c ++;
    //         }
    //     }
    //     Insert devTaskToCreate;
    // }

    /******************************************************************************
    * @author       Christian Doctolero
    * @date         08.19.2021
    * @description  Whenever the Convert checkbox is enabled, create a dev task from a functionality
    * @param        projectTasks 
    ******************************************************************************/
    public static void createDevTaskFromButton(Map<Id, Project_task__c> oldProjTaskMap, List<Project_Task__c> newProjTaskList){
        Id functionalityRecTypId = [SELECT Id From RecordType WHERE DeveloperName = 'Functionality' LIMIT 1].Id;  
        Id devRecTypeId = [SELECT Id From RecordType WHERE DeveloperName = 'Dev' LIMIT 1].Id;  
        Id defaultOwner = [SELECT Id, Name From User WHERE Email = 'kay@ulapp.co' AND IsActive = True LIMIT 1].Id; 
        Set<Id> projectIds = new Set<Id>();
        Set<Id> epicIds = new Set<Id>();
        Set<Id> featureFunctionalityIds = new Set<Id>();
        String recCount;
        String devTitle;

        for(Project_Task__c pt: newProjTaskList){
            projectIds.add(pt.Project__c);
            epicIds.add(pt.Epic__c);
            featureFunctionalityIds.add(pt.Feature__c);
            featureFunctionalityIds.add(pt.Functionality__c);
        }

        Map<Id, Project__c> projCodeMap = new Map<Id, Project__c>([SELECT Id, Project_Code__c, Dev_Count__c, Starting_Task_Number__c FROM Project__c WHERE Id IN: projectIds]);
        Map<Id, Epic__c> epicCodeMap = new Map<Id, Epic__c>([SELECT Id, Epic_Code__c FROM Epic__c WHERE Id IN: epicIds]);
        //Map<Id, Project_Task__c> featureFunctionalityMap = new Map<Id, Project_Task__c>([SELECT Id, Feature_Code__c, Functionality_Code__c FROM Project_Task__c WHERE Id IN: featureFunctionalityIds]);
        
        for(Project_Task__c pt: newProjTaskList){
            if(pt.From_DevQA_Button_Story__c == true){
                devTitle = 'DV: ' + pt.Title__c;
            }
            else if(pt.From_DevQA_Button_Functionality__c == true){
                devTitle = pt.Title__c.replace('FU:','DV:');
            }

            if(projCodeMap.get(pt.Project__c).Starting_Task_Number__c == null ){
                projCodeMap.get(pt.Project__c).Starting_Task_Number__c = 1;
            }
            
            if(projCodeMap.size()>0 && epicCodeMap.size()>0){
                pt.Name = projCodeMap.get(pt.Project__c).Project_Code__c + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c + '-' + projCodeMap.get(pt.Project__c).Starting_Task_Number__c + '-DV';
            }
            pt.OwnerId = defaultOwner;
            pt.Title__c = devTitle;
            projCodeMap.get(pt.Project__c).Starting_Task_Number__c ++;
        }
    }

    /******************************************************************************
    * @author       Christian Doctolero
    * @date         11.26.2021
    * @description  Update story status to converted when a dev record is created from the story
    * @param        projectTasks 
    ******************************************************************************/
    @future
    public static void updateStoryToConverted(Set<Id> storyRecIds){

        List<Project_Task__c> ptToUpdate = new List<Project_Task__c>();

        for(Project_Task__c pt: [SELECT Id, Status__c FROM Project_Task__c WHERE Id IN: storyRecIds]){
            pt.Status__c = 'Converted';
            ptToUpdate.add(pt);
        }

        update ptToUpdate;

    }
    /******************************************************************************
    * @author       Rianno Rizarri
    * @date         08.09.2022
    * @description  [CAPM-384] Whenever a qa project task is created, assign Project__c.QA_User__c if not empty. Set running user as owner if otherwise.
    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author                Description
    *           ----  ---------       --------------------  -----------------------------
    * @version   1.0  30-03-2022      Rianno Rizarri        [CAPM-384] Whenever a qa project task is created, assign Project__c.QA_User__c if not empty. Set running user as owner if otherwise.
    ******************************************************************************/
    public static void assignOwnerToQATask(List<Project_Task__c> newProjTaskList){
        Set<Id> projectIds = new Set<Id>();
        Id QARecordTypeId = Schema.SObjectType.Project_Task__c.getRecordTypeInfosByName().get('QA').getRecordTypeId();

        for(Project_Task__c pt: newProjTaskList){
            if(pt.RecordTypeId == QARecordTypeId){
                projectIds.add(pt.Project__c);
            }
            
        }

        if(projectIds.size() > 0){
            Map<Id, Project__c> projCodeMap = new Map<Id, Project__c>([SELECT Id, QA_User__c FROM Project__c WHERE Id IN: projectIds]);
            for(Project_Task__c pt: newProjTaskList){
                pt.OwnerId = projCodeMap.get(pt.Project__c).QA_User__c != NULL ? projCodeMap.get(pt.Project__c).QA_User__c : UserInfo.getUserId();
            }
        }
    }

    
    /******************************************************************************
    * @author       Christian Doctolero
    * @date         08.19.2021
    * @description  Whenever a dev task is created, create a qa task from a functionality
    * @param        projectTasks 
    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.1  30-03-2022   Nikki Badilla         [CAPM-AGL-8-DV] Update to create QA Tasks for Bug Task.
    * @version   1.2  05-08-2022   Rianno Rizarri        [CAPM-384] Set QA Task owner to Project__c.QA_User__c if not empty. Set running user as owner if otherwise.
    ******************************************************************************/
    public static void createQATask(List<Project_Task__c> newProjTaskList){
        Id devRecTypeId = [SELECT Id From RecordType WHERE DeveloperName = 'Dev' LIMIT 1].Id;
        Id bugRecTypeId = [SELECT Id From RecordType WHERE DeveloperName = 'Bug' LIMIT 1].Id;
        Id qaRecType = [SELECT Id From RecordType WHERE DeveloperName = 'QA' LIMIT 1].Id;
        String qaTitle;
        List<Project_Task__c> qaTaskToCreate = new List<Project_Task__c>();
        //Start CAPM-384: Rianno Rizarri
        Set<Id> projectIds = new Set<Id>();

        for(Project_Task__c pt: newProjTaskList){
            projectIds.add(pt.Project__c);
        }

        Map<Id, Project__c> projCodeMap = new Map<Id, Project__c>([SELECT Id, QA_User__c FROM Project__c WHERE Id IN: projectIds]);
        //End CAPM-384: Rianno Rizarri
        for(Project_Task__c pt: newProjTaskList){
            if((pt.RecordTypeId == devRecTypeId && 
                pt.Status__c != 'Backlog') ||
                pt.RecordTypeId == bugRecTypeId
            ){
                qaTaskToCreate.add(new Project_Task__c(
                    Name = (pt.RecordTypeId == bugRecTypeId? pt.Name +'-QA' : pt.Name.replace('-DV', '-QA')),
                    RecordTypeId = qaRecType,
                    Dev_Task__c = pt.Id,
                    Project__c = pt.Project__c, //To clarify
                    Epic__c = pt.Epic__c,
                    Functionality__c = pt.Functionality__c,
                    Feature__c = pt.Feature__c,
                    Priority__c = pt.Priority__c,
                    Description__c = 'Test Execution Steps',
                    Status__c = 'New',
                    //Start CAPM-384: Rianno Rizarri
                    OwnerId = projCodeMap.containsKey(pt.Project__c) && projCodeMap.get(pt.Project__c).QA_User__c  != null ? projCodeMap.get(pt.Project__c).QA_User__c : UserInfo.getUserId(),
                    //End CAPM-384: Rianno Rizarri
                    Title__c = (pt.RecordTypeId == bugRecTypeId? 'QA:' + pt.Title__c : pt.Title__c.replace('DV:','QA:')),
                    Source_Story__c = pt.Source_Story__c,
                    Requested_By__c = pt.Requested_By__c
                ));
            }
        }
        Insert qaTaskToCreate;
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         01.21.2022
    * @description  Update Project Task Number for QA whenever dev Project Task Number is updated
    * @param        newProjTaskList, oldProjectTaskMap

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  21-01-2022   Von Pernicia         [CAPM-101] Initial version.
    ******************************************************************************/
    public static void updateQATask(Map<Id,Project_Task__c> newProjectTaskMap){
        Id recordTypeIDDev = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Dev').getRecordTypeId();
        Map<String, Project_Task__c> devPrjTaskMap = new Map<String, Project_Task__c>();
        List<Project_Task__c> qaPrjTaskList = new List<Project_Task__c>();
        String qaPrjName;

        try {

            for (Project_Task__c qaProjTask: [SELECT Id, Name, Project__c, Epic__c, Dev_Task__c FROM Project_Task__c WHERE Dev_Task__c IN: newProjectTaskMap.keySet()]) {
                
                qaProjTask.Project__c = newProjectTaskMap.get(qaProjTask.Dev_Task__c).Project__c;
                qaProjTask.Epic__c = newProjectTaskMap.get(qaProjTask.Dev_Task__c).Epic__c;
                qaProjTask.Name = newProjectTaskMap.get(qaProjTask.Dev_Task__c).name.replace('DV','QA');
                qaPrjTaskList.add(qaProjTask);
            }
            
            if (!qaPrjTaskList.isEmpty()) {
                update qaPrjTaskList;
            }
        } catch (Exception e) {
            system.debug('TRY-CATCH-updateQATask' + e);
        }
        
    }

    /******************************************************************************
    * @author       Nikki Badilla
    * @date         02.18.2022
    * @description  Update Related QA Tasks' Status if Dev/Bug Task Status is For QA.
                    Update Related Dev/Bug tasks' Status if QA Task Status = Pass and Smoke QA Sign-off = true
    * @param        projTaskList

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  18-02-2022   Nikki Badilla         [CAPM-AGL-11-DV] Initial version.
    *            2.0  09-08-2022   Von Pernicia          [CAPM-AGL-380-DV] added/updated condition 
                                                         When QA task status = QA Smoke, change Dev task status = For Release
                                                         When QA task status = Pass, change Dev task status = Completed 
	*            3.0  05-10-2023   Miguel Punzal         [CAPM-PMG-877-DV] Updated the Status Conditions 
                                                         Changed QA Smoke to Prod Validation
														 Added Fail Status then Set Dev Task to In Progress
    ******************************************************************************/
    public static void updateRelatedProjTasks(List<Project_Task__c> projTaskList){
        
        Set<Id> devPrjIdsForQA = new Set<Id>();
        Set<Id> devPrjIdsForDevForRelease = new Set<Id>();
        Set<Id> devPrjIdsForDevForInProgress = new Set<Id>();
        Set<Id> devPrjIdsForDevCompleted = new Set<Id>();
        List<Project_Task__c> updatePrjTaskList = new List<Project_Task__c>();

        Id recordTypeIDDev = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Dev').getRecordTypeId();
        Id recordTypeIDBug = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('Bug').getRecordTypeId();
        Id recordTypeIDQa = Schema.getGlobalDescribe().get('Project_Task__c').getDescribe().getRecordTypeInfosByName().get('QA').getRecordTypeId();

        try {
        
            
            for (Project_Task__c projTask: projTaskList) {

                // check if status is For QA
                if (projTask.Status__c == 'For QA' &&
                    (projTask.RecordTypeId == recordTypeIDDev ||
                    projTask.RecordTypeId == recordTypeIDBug)) { 
                        devPrjIdsForQA.add(projTask.Id);
                }

                // Start CAPM-AGL-380-DV: Von Pernicia
                // check if status is QA Smoke and Sign off QA Smoke is checked
                // 10/04/2023 - CAPM-PMG-877-DV - Updated by MGP
                //if (projTask.Status__c == 'QA Smoke' &&
                
                
                if (projTask.Status__c == 'Prod Validation' &&
                    /*projTask.Sign_off_Smoke__c == TRUE &&*/
                    projTask.RecordTypeId == recordTypeIDQa) { 
                        devPrjIdsForDevForRelease.add(projTask.Dev_Task__c);
                }
                
                // 10/04/2023 - CAPM-PMG-877-DV - Added by MGP
                if (projTask.Status__c == 'Fail' &&
                    projTask.RecordTypeId == recordTypeIDQa) { 
                        devPrjIdsForDevForInProgress.add(projTask.Dev_Task__c);
                }

                // check if status is Pass and Sign off QA Smoke is checked
                if (projTask.Status__c == 'Pass' &&
                    /*projTask.Sign_off_Smoke__c == TRUE &&*/
                    projTask.RecordTypeId == recordTypeIDQa) { 
                        devPrjIdsForDevCompleted.add(projTask.Dev_Task__c);
                }
                // End CAPM-AGL-380-DV: Von Pernicia
            }

            if(devPrjIdsForQA.size() > 0){
                for (Project_Task__c qaProjTask: [SELECT Id, Status__c FROM Project_Task__c WHERE Dev_Task__c IN: devPrjIdsForQA]) {
                
                    qaProjTask.Status__c = 'QA Integration';
                    updatePrjTaskList.add(qaProjTask);
                }
            }

            // Start CAPM-AGL-380-DV: Von Pernicia
            if(devPrjIdsForDevForRelease.size() > 0){
                for (Project_Task__c devProjTask: [SELECT Id, Status__c FROM Project_Task__c WHERE Id IN: devPrjIdsForDevForRelease]) {
                
                    devProjTask.Status__c = 'For Release';
                    updatePrjTaskList.add(devProjTask);
                }
            }
            
            // 10/04/2023 - CAPM-PMG-877-DV - Added by MGP
            if(devPrjIdsForDevForInProgress.size() > 0){
                for (Project_Task__c devProjTask: [SELECT Id, Status__c FROM Project_Task__c WHERE Id IN: devPrjIdsForDevForInProgress]) {
                
                    devProjTask.Status__c = 'In Progress';
                    updatePrjTaskList.add(devProjTask);
                }
            }

            if(devPrjIdsForDevCompleted.size() > 0){
                for (Project_Task__c devProjTask: [SELECT Id, Status__c FROM Project_Task__c WHERE Id IN: devPrjIdsForDevCompleted]) {
                
                    devProjTask.Status__c = 'Completed';
                    updatePrjTaskList.add(devProjTask);
                }
            }
            // End CAPM-AGL-380-DV: Von Pernicia

            if (!updatePrjTaskList.isEmpty()) {
                update updatePrjTaskList;
            }
        } catch (Exception e) {
            system.debug('TRY-CATCH-updateRelatedQATasks' + e);
        }
        
    }


    /******************************************************************************
    * @author       Christian Doctolero
    * @date         08.19.2021
    * @description  Whenever the Convert checkbox is enabled, create a feature and functionality from a story
    * @param        projectTasks 
    ******************************************************************************/
    public static void createFeatureTask(Map<Id, Project_task__c> oldProjTaskMap, List<Project_Task__c> newProjTaskList){
        Id featureRecTypeId = [SELECT Id From RecordType WHERE DeveloperName = 'Feature' LIMIT 1].Id;  
        Id storyRecTypeId = [SELECT Id From RecordType WHERE DeveloperName = 'Story' LIMIT 1].Id; 
        Id defaultOwner = [SELECT Id From User WHERE Name = 'Mark Cads' AND IsActive = True LIMIT 1].Id;  
        Set<Id> projectIds = new Set<Id>();
        Set<Id> epicIds = new Set<Id>();
        
        for(Project_Task__c pt: newProjTaskList){
            if(pt.Convert_To_Feature__c != oldProjTaskMap.get(pt.Id).Convert_To_Feature__c && pt.Convert_To_Feature__c == True 
                && pt.RecordTypeId == storyRecTypeId && pt.Epic__c != Null){
                projectIds.add(pt.Project__c);
                epicIds.add(pt.Epic__c);
                if(pt.RecordTypeId == storyRecTypeId){
                    pt.Status__c = 'Converted';
                }
            }
        }

        Map<Id, Project__c> projCodeMap = new Map<Id, Project__c>([SELECT Id, Project_Code__c, Feature_Count__c FROM Project__c WHERE Id IN: projectIds]);
        Map<Id, Epic__c> epicCodeMap = new Map<Id, Epic__c>([SELECT Id, Epic_Code__c FROM Epic__c WHERE Id IN: epicIds]);

        List<Project_Task__c> featureList = new List<Project_Task__c>();
        for(Project_Task__c pt: newProjTaskList){
            if(pt.Convert_To_Feature__c != oldProjTaskMap.get(pt.Id).Convert_To_Feature__c && pt.Convert_To_Feature__c == True 
                && pt.RecordTypeId == storyRecTypeId && pt.Epic__c != Null){
                    
                    if(projCodeMap.get(pt.Project__c).Feature_Count__c == null ){
                        projCodeMap.get(pt.Project__c).Feature_Count__c = 1;
                    }

                    featureList.add(new Project_Task__c(
                    RecordTypeId = featureRecTypeId,
                    Project__c = pt.Project__c, //To clarify
                    Epic__c = pt.Epic__c,
                    Status__c = 'New',
                    Title__c = 'FE: ' + pt.Title__c,
                    Source_Story__c = pt.Id,
                    OwnerId = defaultOwner,
                    Convert_To_Feature__c = True,
                    Name = projCodeMap.get(pt.Project__c).Project_Code__c + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c + '-'  + projCodeMap.get(pt.Project__c).Feature_Count__c
                ));
                projCodeMap.get(pt.Project__c).Feature_Count__c ++;
            }
        }
        Insert featureList;
    }


    /******************************************************************************
    * @author       Christian Doctolero
    * @date         08.19.2021
    * @description  Whenever the Convert checkbox is enabled, create a feature and functionality from a story
    * @param        projectTasks 
    ******************************************************************************/
    public static void createFunctionalityTask(Map<Id, Project_task__c> oldProjTaskMap, List<Project_Task__c> newProjTaskList){
        Id functionalityRecTypId = [SELECT Id From RecordType WHERE DeveloperName = 'Functionality' LIMIT 1].Id;  
        Id storyRecTypeId = [SELECT Id From RecordType WHERE DeveloperName = 'Story' LIMIT 1].Id;  
        Id defaultOwner = [SELECT Id From User WHERE Name = 'Mark Cads' AND IsActive = True LIMIT 1].Id; 
        List<Project_Task__c> functionalityList = new List<Project_Task__c>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> epicIds = new Set<Id>();

        String featureCode;

        for(Project_Task__c pt: newProjTaskList){
            if(pt.Convert_To_Functionality__c != oldProjTaskMap.get(pt.Id).Convert_To_Functionality__c && pt.Convert_To_Functionality__c == True 
                && pt.RecordTypeId == storyRecTypeId && pt.Epic__c != Null){
                projectIds.add(pt.Project__c);
                epicIds.add(pt.Epic__c);
                if(pt.RecordTypeId == storyRecTypeId){
                    pt.Status__c = 'Converted';
                }
            }
        }

        Map<Id, Project__c> projCodeMap = new Map<Id, Project__c>([SELECT Id, Project_Code__c, Functionality_Count__c FROM Project__c WHERE Id IN: projectIds]);
        Map<Id, Epic__c> epicCodeMap = new Map<Id, Epic__c>([SELECT Id, Epic_Code__c FROM Epic__c WHERE Id IN: epicIds]);

        for(Project_Task__c pt: newProjTaskList){
            if(pt.Convert_To_Functionality__c != oldProjTaskMap.get(pt.Id).Convert_To_Functionality__c && pt.Convert_To_Functionality__c == True 
                && pt.RecordTypeId == storyRecTypeId && pt.Epic__c != Null){

                if(projCodeMap.get(pt.Project__c).Functionality_Count__c == null ){
                    projCodeMap.get(pt.Project__c).Functionality_Count__c = 1;
                }

                functionalityList.add(new Project_Task__c(
                    RecordTypeId = functionalityRecTypId,
                    Project__c = pt.Project__c, //To clarify
                    Epic__c = pt.Epic__c,
                    Status__c = 'New',
                    Title__c = 'FU: ' + pt.Title__c,
                    Source_Story__c = pt.Id,
                    OwnerId = defaultOwner,
                    Convert_To_Functionality__c = True,
                    Name = projCodeMap.get(pt.Project__c).Project_Code__c + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c + '-<FEA>-' +  projCodeMap.get(pt.Project__c).Functionality_Count__c
                ));
                projCodeMap.get(pt.Project__c).Functionality_Count__c ++;
            }
        }
        Insert functionalityList;
    }

    /******************************************************************************
    * @author       Christian Doctolero
    * @date         11.19.2021
    * @description  Create a functionality record when the New Functionality Button from Feature record is pressed
    * @param        projectTasks 
    ******************************************************************************/
    public static void createFunctionalityTaskFromFeature(Map<Id, Project_task__c> oldProjTaskMap,  List<Project_Task__c> newProjTaskList){
        Id defaultOwner = [SELECT Id From User WHERE Name = 'Mark Cads' AND IsActive = True LIMIT 1].Id; 
        List<Project_Task__c> functionalityList = new List<Project_Task__c>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> epicIds = new Set<Id>();
        Set<Id> featureIds = new Set<Id>();
        String functionalityTitle;
        String featureCode;

        for(Project_Task__c pt: newProjTaskList){
            projectIds.add(pt.Project__c);
            epicIds.add(pt.Epic__c);
            featureIds.add(pt.Feature__c);
        }
        
        Map<Id, Project__c> projCodeMap = new Map<Id, Project__c>([SELECT Id, Project_Code__c, Functionality_Count__c FROM Project__c WHERE Id IN: projectIds]);
        Map<Id, Epic__c> epicCodeMap = new Map<Id, Epic__c>([SELECT Id, Epic_Code__c FROM Epic__c WHERE Id IN: epicIds]);
        Map<Id, Project_Task__c> featureCodeMap = new Map<Id, Project_Task__c>([SELECT Id, Feature_Code__c FROM Project_Task__c WHERE Id IN: featureIds]);

        for(Project_Task__c pt: newProjTaskList){
            functionalityTitle = pt.Title__c.replace('FE:','FU:');
            if(projCodeMap.get(pt.Project__c).Functionality_Count__c == null ){
                projCodeMap.get(pt.Project__c).Functionality_Count__c = 1;
            }
            pt.Name = projCodeMap.get(pt.Project__c).Project_Code__c + '-' + epicCodeMap.get(pt.Epic__c).Epic_Code__c + '-' + featureCodeMap.get(pt.Feature__c).Feature_Code__c + '-' + projCodeMap.get(pt.Project__c).Functionality_Count__c;
            pt.Title__c = functionalityTitle;
            projCodeMap.get(pt.Project__c).Functionality_Count__c ++;
        }
    }

    /******************************************************************************
    * @author       Christian Doctolero
    * @date         08.19.2021
    * @description  Update Functionality Name when Feature lookup is populated
    * @param        projectTasks
    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  19-08-2021   Christian Doctolero  Initial version.
    * @version   2.0  27-01-2022   Von Pernicia         [CAPM-101] transfered the logic to initializeProjectTaskNumber
    ******************************************************************************/
    /*public static void updateFunctionalityName(Map<Id, Project_task__c> oldProjTaskMap, Map<Id, Project_Task__c> newProjTaskMap){
        Id functionalityRecTypId = [SELECT Id From RecordType WHERE DeveloperName = 'Functionality' LIMIT 1].Id;  
        Set<Id> featureIds = new Set<Id>();
        String featureCode;

        for(Project_Task__c pt: newProjTaskMap.values()){
            if(pt.Feature__c != oldProjTaskMap.get(pt.Id).Feature__c && pt.RecordTypeId == functionalityRecTypId){
                featureIds.add(pt.Feature__c);
            }
        }

        Map<Id, Project_Task__c> featureCodeMap = new Map<Id, Project_Task__c>([SELECT Id, Feature_Code__c FROM Project_Task__c WHERE Id IN: featureIds]);

        for(Project_Task__c pt: newProjTaskMap.values()){
            if(pt.Feature__c != oldProjTaskMap.get(pt.Id).Feature__c && pt.RecordTypeId == functionalityRecTypId){
                pt.Name = pt.Name.replace('<FEA>', featureCodeMap.get(pt.Feature__c).Feature_Code__c);
            }
        }
    }*/

    /******************************************************************************
    * @author       Christian Doctolero
    * @date         08.20.2021
    * @description  Store the previous Task Number to External Rask Number field whenever reparented 
    * @param        projectTasks 
    ******************************************************************************/
    public static void storePreviousTaskNumber(Map<Id, Project_task__c> oldProjTaskMap, List<Project_Task__c> newProjTaskList){
        
        for(Project_Task__c pt: newProjTaskList){
            if(pt.Project__c != oldProjTaskMap.get(pt.Id).Project__c && !String.isBlank(pt.Project__c) || 
               pt.Epic__c != oldProjTaskMap.get(pt.Id).Epic__c && !String.isBlank(pt.Epic__c)
            ){
                
                if(String.isBlank(oldProjTaskMap.get(pt.Id).External_Task_Number__c)){
                    pt.External_Task_Number__c = oldProjTaskMap.get(pt.Id).Name;
                }
                else{
                    pt.External_Task_Number__c += ',' + oldProjTaskMap.get(pt.Id).Name;
                }
            }
        }
    }



    /******************************************************************************
    * @author       Christian Doctolero
    * @date         10.27.2021
    * @description  Whenever the Create Bug button is clicked, create a dev task from a functionality
    * @param        projectTasks 
    
    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.2  23-05-2022   Nikki Badilla         [CAPM-AGL-300-DV] Updated Bug Naming convention.
    ******************************************************************************/
    public static void createBugTaskFromQA(Map<Id, Project_task__c> oldProjTaskMap, List<Project_Task__c> newProjTaskList){
        Id qaRecType = [SELECT Id From RecordType WHERE DeveloperName = 'QA' LIMIT 1].Id;  
        Id defaultOwner = [SELECT Id, Name From User WHERE Email = 'kay@ulapp.co' AND IsActive = True LIMIT 1].Id; 
        Set<Id> projectIds = new Set<Id>();
        Set<Id> QATaskIds = new Set<Id>();
        Set<Id> epicIds = new Set<Id>();
        Set<Id> featureFunctionalityIds = new Set<Id>();
        String bugTitle;

        for(Project_Task__c pt: newProjTaskList){
            projectIds.add(pt.Project__c);
            QATaskIds.add(pt.QA_Task__c);
            epicIds.add(pt.Epic__c);
            featureFunctionalityIds.add(pt.Feature__c);
            featureFunctionalityIds.add(pt.Functionality__c);
        }
        
        Map<Id, Project__c> projCodeMap = new Map<Id, Project__c>([SELECT Id, Project_Code__c, Starting_Task_Number__c FROM Project__c WHERE Id IN: projectIds]); //CAPM-AGL-300-DV Nikki 05232022
        Map<Id, Project_Task__c> bugCountMap = new Map<Id, Project_Task__c>([SELECT Id, Bug_Count__c FROM Project_Task__c WHERE Id IN: QATaskIds]);
        Map<Id, Epic__c> epicCodeMap = new Map<Id, Epic__c>([SELECT Id, Epic_Code__c FROM Epic__c WHERE Id IN: epicIds]);
        //Map<Id, Project_Task__c> featureFunctionalityMap = new Map<Id, Project_Task__c>([SELECT Id, Feature_Code__c, Functionality_Code__c FROM Project_Task__c WHERE Id IN: featureFunctionalityIds]);

        for(Project_Task__c pt: newProjTaskList){
                /*bugTitle = pt.Title__c.replace('QA:','BUG:');
                if(bugCountMap.get(pt.QA_Task__c).Bug_Count__c == null ){
                    bugCountMap.get(pt.QA_Task__c).Bug_Count__c = 1;
                }

                if(bugCountMap.size()>0 && epicCodeMap.size()>0){
                    pt.Name = pt.Name  + '-BUG-' + bugCountMap.get(pt.QA_Task__c).Bug_Count__c ;
                }*/
                pt.Name = projCodeMap.get(pt.Project__c).Project_Code__c + '-' + projCodeMap.get(pt.Project__c).Starting_Task_Number__c; //CAPM-AGL-300-DV Nikki 05232022
                pt.Status__c = 'New';
                pt.Title__c = bugTitle;
                pt.OwnerId = defaultOwner;
                //bugCountMap.get(pt.QA_Task__c).Bug_Count__c ++;
                projCodeMap.get(pt.Project__c).Starting_Task_Number__c++; //CAPM-AGL-300-DV Nikki 05302022
        }

        update projCodeMap.values(); //CAPM-AGL-300-DV Nikki 05302022
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         23-04-2022
    * @description  This will compute Story estimated hrs base on related Project
                    task record estimated hrs. eg: QA and dev
    * @param        projTaskIdList

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  23-04-2022   Von Pernicia         [CAPM-AGL-277-DV] Initial version.
    ******************************************************************************/
    public static void computeStoryEstimatedHrs(Set<Id> projTaskIdList) {

        Set<Id> storyIdSet = new Set<Id>();
        List<Project_Task__c> projectTaskList = new List<Project_Task__c>();
       
        for (Project_Task__c pt: [SELECT Source_Story__c FROM Project_Task__c WHERE Id IN: projTaskIdList AND Source_Story__c <> NULL]) {
            storyIdSet.add(pt.Source_Story__c);
        }

        if (!storyIdSet.isEmpty()) {
            for (AggregateResult agg: [SELECT SUM(Estimated_Hours__c)Total, Source_Story__c
                                    FROM Project_Task__c
                                    WHERE Source_Story__c IN: storyIdSet
                                    GROUP BY Source_Story__c]) 
                                    
            {   
                Project_Task__c pt = new Project_Task__c(
                    Id = String.valueOf(agg.get('Source_Story__c')),
                    Estimated_Hours__c = Integer.valueOf(agg.get('Total'))
                );
                projectTaskList.add(pt);
            }
            
            if (!projectTaskList.isEmpty()) {
                update projectTaskList;
            }
        }
    }

    /******************************************************************************
    * @author       Nikki Badilla
    * @date         29-06-2022
    * @description  This will compute Sprint estimated hrs base on related Project
                    task record estimated hrs. eg: QA and dev
    * @param        projTaskIdList

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  29-06-2022   Nikki Badilla         [CAPM-AGL-350-DV] Initial version.
    ******************************************************************************/
    public static void computeSprintEstimatedHrs(Set<Id> projTaskIdList) {

        Set<Id> sprintIdSet = new Set<Id>();
        List<Sprint__c> sprintToUpdate = new List<Sprint__c>();
        List<String> recordTypesIncluded = new List<String>{'Dev', 'QA', 'Bug'};
       
        for (Project_Task__c pt: [SELECT Sprint__c FROM Project_Task__c WHERE Id IN: projTaskIdList AND Sprint__c <> NULL]) {
            sprintIdSet.add(pt.Sprint__c);
        }

        if (!sprintIdSet.isEmpty()) {
            for (AggregateResult agg: [SELECT SUM(Estimated_Hours__c)Total, Sprint__c
                                    FROM Project_Task__c
                                    WHERE Sprint__c IN: sprintIdSet
                                    AND RecordType.Name IN :recordTypesIncluded
                                    GROUP BY Sprint__c]) 
                                    
            {   
                Sprint__c sprint = new Sprint__c(
                    Id = String.valueOf(agg.get('Sprint__c')),
                    Estimated_Hours__c = Double.valueOf(agg.get('Total'))
                );
                sprintToUpdate.add(sprint);
            }
            
            if (!sprintToUpdate.isEmpty()) {
                update sprintToUpdate;
            }
        }
    }

    /******************************************************************************
    * @author       Von Pernicia
    * @date         23-04-2022
    * @description  This will submit Project Task Approval
    * @param        projTaskIdList

    * Changes (version)
    * -------------------------------------------------------------------------------------------

    *            No.  Date(dd-mm-yyy) Author            Description
    *           ----  ---------   --------------------  -----------------------------
    * @version   1.0  23-04-2022   Von Pernicia         [CAPM-AGL-277-DV] Initial version.
    * @version   1.0  23-04-2022   Mel Mallorca         [CAPM-548] Add new field to show the Approver Name:"Name of the Approver"  under the Status section.
    ******************************************************************************/
    public static void submitApprovalProcess(List<Project_Task__c> projTaskList) {

        Set<Id> campaignId = new Set<Id>();
        Map<Id, Id> campaignOwnerIdMap = new Map<Id, Id>();

        // retieve all campaign Ids from project task
        for (Project_Task__c projectTask: projTaskList) {
            
            if (!String.isEmpty(projectTask.Campaign__c)) {
                campaignId.add(projectTask.Campaign__c);
            }
        }

        // get campaign owner id to use as the approver
        Map<Id, String> approverNameMap = new Map<Id, String>();
        Map<Id, String> ptApproverNameMap = new Map<Id, String>();
        for (Campaign__c camp: [SELECT Id, CreatedById, CreatedBy.Name
                            FROM Campaign__c
                            WHERE Id IN: campaignId])
        {
            campaignOwnerIdMap.put(camp.Id, camp.CreatedById);
            approverNameMap.put(camp.CreatedById, camp.CreatedBy.Name);
        }
        
        Id groupId = [SELECT Id FROM Group WHERE Name= 'Project Task Approver'].Id;
        Id defaultApproverId = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =: groupId LIMIT 1].UserOrGroupId;
        String defaultApproverName = [SELECT Name FROM User Where Id =: defaultApproverId].Name;
        
        
        List<Id> projTaskListforUpdate = new List<Id>();
        String approverName;
        for (Project_Task__c projectTask: projTaskList) {

            Id approverId = (campaignOwnerIdMap.containsKey(projectTask.Campaign__c) ? campaignOwnerIdMap.get(projectTask.Campaign__c) : defaultApproverId);
            //CAPM-551 
            approverName = (approverNameMap.containsKey(approverId) ? approverNameMap.get(approverId) : defaultApproverName);
            ptApproverNameMap.put(projectTask.Id, approverName);
            projTaskListforUpdate.add(projectTask.Id);
            
            // Create an approval request for project task story
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(projectTask.id);
            req.setNextApproverIds(new Id[] { approverId });

            // Submit the approval request for  project task story
            Approval.ProcessResult result = Approval.process(req);
        }
        updateProjectTaskFields(projTaskListforUpdate, JSON.serialize(ptApproverNameMap));
        
    }
    
    //CAPM-551 04/22/2023 Mel Mallorca
    @future
    public static void updateProjectTaskFields(List<Id> ptIds, String approverName)
    {
        List<Project_Task__c> projTaskList = [SELECT Id FROM Project_Task__c WHERE Id IN: ptIds];
        Map<Id, String> ptApproverName = (Map<Id, String>)JSON.deserialize(approverName, Map<Id, String>.class);
        for(Project_Task__c pt: projTaskList){
            pt.Name_of_the_approver__c = (ptApproverName.containsKey(pt.Id) ? ptApproverName.get(pt.Id) : '');
        }
        
        update projTaskList;
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
    public static void assignPTFromWorkplan(List<Project_Task__c> projectTaskList, List<Id> workplanIdList, Boolean isCreated) {
        
        Map<Id, Decimal> orderMaxCountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> totalProposedHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> totalOpenWorkPlanMap = new Map<Id, Decimal>();
        List<Workplan__c> updateWorkplanList = new List<Workplan__c>();
        
        Map<Id, Workplan__c> ptWorkplanMap = new Map<Id, Workplan__c>(
                        [
                            SELECT  Id, 
                                    Project__c,
                                    Epic__c,
                                    Campaign__c
                            FROM    Workplan__c
                            WHERE   Id IN: workplanIdList
                        ]
        );

        List<Project_Task__c> ptList = 
                        [
                            SELECT  Id,
                                    Order__c,
                                    Proposed_Hours__c,
                                    Workplan__c,
                                    Status__c
                            FROM    Project_Task__c
                            WHERE   Workplan__c IN: workplanIdList
                        ];

        Map<String, Map<Id, Decimal>> resultMap1 = getworkPlanMapping(ptList, orderMaxCountMap, totalProposedHoursMap, totalOpenWorkPlanMap);
        if (resultMap1.size() > 0) {
            orderMaxCountMap.putAll(resultMap1.get('orderMaxCountMap'));
            totalProposedHoursMap.putAll(resultMap1.get('totalProposedHoursMap'));
            totalOpenWorkPlanMap.putAll(resultMap1.get('totalOpenWorkPlanMap'));
        }

        // update project task data points on create
        if (isCreated) {

            Set<Id> projectIds = new Set<Id>();
            Set<Id> epicIds = new Set<Id>();
            Set<Id> featureIds = new Set<Id>();

            Id approverId = [SELECT Id, UserOrGroupId
                            FROM GroupMember
                            WHERE GroupId IN (SELECT ID
                                            FROM Group
                                            WHERE DeveloperName = 'Project_Task_Approver')
                            ].UserOrGroupId;
                            
            Map<String, Map<Id, Decimal>> resultMap2 = getworkPlanMapping(projectTaskList, orderMaxCountMap, totalProposedHoursMap, totalOpenWorkPlanMap);
            orderMaxCountMap.putAll(resultMap2.get('orderMaxCountMap'));
            totalProposedHoursMap.putAll(resultMap2.get('totalProposedHoursMap'));
            totalOpenWorkPlanMap.putAll(resultMap2.get('totalOpenWorkPlanMap'));

            for (Project_Task__c pt: projectTaskList) {
                
                pt.Name_of_the_Approver__c = approverId;
                pt.Project__c = ptWorkplanMap.get(pt.Workplan__c).Project__c;
                pt.Epic__c = ptWorkplanMap.get(pt.Workplan__c).Epic__c;
                pt.Campaign__c = ptWorkplanMap.get(pt.Workplan__c).Campaign__c;
                pt.Order__c = orderMaxCountMap.get(pt.Workplan__c) + 1;

                projectIds.add(ptWorkplanMap.get(pt.Workplan__c).Project__c);
                epicIds.add(ptWorkplanMap.get(pt.Workplan__c).Epic__c);
            }

            initializeProjectTaskNumber(projectTaskList, projectIds, epicIds, featureIds);
        }

        for(Workplan__c workPlan : [SELECT  Id
                                    FROM    Workplan__c
                                    WHERE   Id in: workplanIdList]
        ) {
        
            workPlan.Total_Proposed_Hours__c = totalProposedHoursMap.get(workPlan.Id);
            workPlan.Total_Open_Project_Tasks__c = totalOpenWorkPlanMap.get(workPlan.Id);
            updateWorkplanList.add(workPlan);
        }

        if (!updateWorkplanList.isEmpty()) {
            update updateWorkplanList;
        }
    }

    public static Map<String, Map<Id, Decimal>> getworkPlanMapping(List<Project_Task__c> projectTaskList, Map<Id, Decimal> orderMap, Map<Id, Decimal> proposedHoursMap, Map<Id, Decimal> openWorkPlanMap) {

        Map<Id, Decimal> orderMaxCountMap = new Map<Id, Decimal>();
        Map<Id, Decimal> totalProposedHoursMap = new Map<Id, Decimal>();
        Map<Id, Decimal> totalOpenWorkPlanMap = new Map<Id, Decimal>();
        Map<String, Map<Id, Decimal>> resultMap = new Map<String, Map<Id, Decimal>>();
        Set<String> openProjectTaskStatuses = new Set<String>{'Completed', 'Withdrawn', 'Duplicate', 'Pass'};
        
        if (orderMap.size() > 0) {
            orderMaxCountMap.putAll(orderMap); 
        }

        if (proposedHoursMap.size() > 0) {
            totalProposedHoursMap.putAll(proposedHoursMap); 
        }

        if (openWorkPlanMap.size() > 0) {
            totalOpenWorkPlanMap.putAll(openWorkPlanMap); 
        }
        
        for (Project_Task__c pt: projectTaskList) {
        
            // get the order count with the highest order value related to workplan
            if (orderMaxCountMap.containsKey(pt.Workplan__c)) {
                if (pt.Order__c > orderMaxCountMap.get(pt.Workplan__c)) {
                    orderMaxCountMap.put(pt.Workplan__c, (pt.Order__c == null ? 0 : pt.Order__c));
                }
            } else {
                orderMaxCountMap.put(pt.Workplan__c, (pt.Order__c == null ? 0 : pt.Order__c));
            }

            resultMap.put('orderMaxCountMap', orderMaxCountMap);

            // compute total proposed plan hours per workplan
            Decimal proposeHrs = (pt.Proposed_Hours__c == null ? 0 : pt.Proposed_Hours__c);
            if (totalProposedHoursMap.containsKey(pt.Workplan__c)) {
                totalProposedHoursMap.put(pt.Workplan__c, totalProposedHoursMap.get(pt.Workplan__c) + proposeHrs);
            } else {
                totalProposedHoursMap.put(pt.Workplan__c, proposeHrs);
            }

            resultMap.put('totalProposedHoursMap', totalProposedHoursMap);

             // compute Total Open Workplan Tasks per workplan
            if (!openProjectTaskStatuses.contains(pt.Status__c)) {

                if (totalOpenWorkPlanMap.containsKey(pt.Workplan__c)) {

                    totalOpenWorkPlanMap.put(pt.Workplan__c, totalOpenWorkPlanMap.get(pt.Workplan__c) + 1);
                } else {
                    totalOpenWorkPlanMap.put(pt.Workplan__c, 1);
                }
            }

            resultMap.put('totalOpenWorkPlanMap', totalOpenWorkPlanMap);
        }
        

        return resultMap;
    }

    /******************************************************************************
    * @author       Gian Bata
    * @ticket		CAPM-AGL-852-DV
    * @date         28-09-2023
    * @description  This code handles sending email notifications for assigned tasks 
    *               and status changes. It includes record links in the email body for 
    *               tasks that are ready for specific statuses.
    ******************************************************************************/
    public static void assignedToNotification(Map<Id, Project_Task__c> projectTasks, Map<Id, Project_Task__c> oldProjectTasks) {
        // List to store email messages for task assignments
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        
        // List to store email messages for status changes with record links
        List<Messaging.SingleEmailMessage> emailMessages2 = new List<Messaging.SingleEmailMessage>();
    
        // Get the Salesforce base URL
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
    
        // Map to collect tasks with changed statuses
        Map<Id, Project_Task__c> tasksToUpdate = new Map<Id, Project_Task__c>();
        List<Id> contactIdList = new List<String>();
        
        for (Id taskId : projectTasks.keySet()) {
            Project_Task__c task = projectTasks.get(taskId);
            
            if (task.SIT_Assigned_To__c != null) {
                contactIdList.add(task.SIT_Assigned_To__c);
            }
            
            if (task.UAT_Assigned_To__c != null) {
                contactIdList.add(task.UAT_Assigned_To__c);
            }
            
            if (task.Prod_Validation_Assigned_To__c != null) {
                contactIdList.add(task.Prod_Validation_Assigned_To__c);
            }
        }
        
        Map<Id, String> getEmailMap = new Map<Id, String>();        
        for (Contact contact: [SELECT Id, Email
                                        FROM Contact
                                        WHERE Id in: contactIdList])
        {
            getEmailMap.put(contact.Id, contact.Email);
        }
    
        // Loop through the updated tasks to identify those with changed statuses
        for (Id taskId : projectTasks.keySet()) {
            Project_Task__c task = projectTasks.get(taskId);
            Project_Task__c oldTask = oldProjectTasks != null ? oldProjectTasks.get(taskId) : null;
    
            // Helper method to send email notification for a specific assignment field
            if (task.SIT_Assigned_To__c != null && (oldTask == null || task.SIT_Assigned_To__c != oldTask.SIT_Assigned_To__c)) {
                sendAssignmentNotification(task, getEmailMap, baseUrl, emailMessages, task.SIT_Assigned_To__c, 'SIT', task.Requestor_Name__c);
            }
            if (task.UAT_Assigned_To__c != null && (oldTask == null || task.UAT_Assigned_To__c != oldTask.UAT_Assigned_To__c)) {
                sendAssignmentNotification(task, getEmailMap, baseUrl, emailMessages, task.UAT_Assigned_To__c, 'UAT', task.Requestor_Name__c);
            }
            if (task.Prod_Validation_Assigned_To__c != null && (oldTask == null || task.Prod_Validation_Assigned_To__c != oldTask.Prod_Validation_Assigned_To__c)) {
                sendAssignmentNotification(task, getEmailMap, baseUrl, emailMessages, task.Prod_Validation_Assigned_To__c, 'Prod Validation', task.Requestor_Name__c);
            }
    
            // Check if the Status__c field has changed
            if (oldTask != null && task.Status__c != oldTask.Status__c) {
                tasksToUpdate.put(task.Id, task);
            }
        }
        
        // If there are tasks with changed statuses
        if (!tasksToUpdate.isEmpty()) {
            // Map to store assigned contacts
            Map<Id, Contact> assignedContacts = new Map<Id, Contact>();
    
            // Query tasks to identify assigned contacts
            for (Project_Task__c task : [SELECT Id, Name, Status__c, SIT_Assigned_To__c, UAT_Assigned_To__c, Prod_Validation_Assigned_To__c
                                         FROM Project_Task__c
                                         WHERE Id IN :tasksToUpdate.keySet()]) {
                if (task.Status__c == 'SIT' && task.SIT_Assigned_To__c != null) {
                    assignedContacts.put(task.SIT_Assigned_To__c, null);
                } else if (task.Status__c == 'UAT' && task.UAT_Assigned_To__c != null) {
                    assignedContacts.put(task.UAT_Assigned_To__c, null);
                } else if (task.Status__c == 'Prod Validation' && task.Prod_Validation_Assigned_To__c != null) {
                    assignedContacts.put(task.Prod_Validation_Assigned_To__c, null);
                }
            }
    
            // Query and populate Contact records for assigned Contacts
            for (Contact contact : [SELECT Id, Name, Email FROM Contact WHERE Id IN :assignedContacts.keySet()]) {
                assignedContacts.put(contact.Id, contact);
            }
    
            // Send emails based on the assigned contacts and statuses
            for (Project_Task__c task : tasksToUpdate.values()) {
                if (task.Status__c == 'SIT' && task.SIT_Assigned_To__c != null) {
                    Contact sitAssignedContact = assignedContacts.get(task.SIT_Assigned_To__c);
                    if (sitAssignedContact != null && sitAssignedContact.Email != null) {
                        // Construct email message body for SIT
                        String emailBody = 'Project Task ' + task.Name + ' has completed development and is now ready for your SIT. You may now start your testing.\n\n';
                        
                        // Add record link to the bottom of the email body
                        emailBody += 'Click on the link below to view the record:\n' + baseUrl + '/' + task.Id;
    
                        // Create and configure the email message for SIT
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setToAddresses(new String[] { sitAssignedContact.Email });
                        email.setSubject(task.Name + ' Ready for SIT');
                        email.setPlainTextBody(emailBody);
                        emailMessages2.add(email);
                    }
                } else if (task.Status__c == 'UAT' && task.UAT_Assigned_To__c != null) {
                    Contact uatAssignedContact = assignedContacts.get(task.UAT_Assigned_To__c);
                    if (uatAssignedContact != null && uatAssignedContact.Email != null) {
                        // Construct email message body for UAT
                        String emailBody = 'Project Task ' + task.Name + ' has completed SIT and is now ready for your UAT. You may now start your testing.\n\n';
                        
                        // Add record link to the bottom of the email body
                        emailBody += 'Click on the link below to view the record:\n' + baseUrl + '/' + task.Id;
    
                        // Create and configure the email message for UAT
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setToAddresses(new String[] { uatAssignedContact.Email });
                        email.setSubject(task.Name + ' Ready for UAT');
                        email.setPlainTextBody(emailBody);
                        emailMessages2.add(email);
                    }
                } else if (task.Status__c == 'Prod Validation' && task.Prod_Validation_Assigned_To__c != null) {
                    Contact prodValidationAssignedContact = assignedContacts.get(task.Prod_Validation_Assigned_To__c);
                    if (prodValidationAssignedContact != null && prodValidationAssignedContact.Email != null) {
                        // Construct email message body for UAT
                        String emailBody = 'Project Task ' + task.Name + ' has completed UAT and is now ready for your Production Validation. You may now start your testing\n\n';
                        
                        // Add record link to the bottom of the email body
                        emailBody += 'Click on the link below to view the record:\n' + baseUrl + '/' + task.Id;
    
                        // Create and configure the email message for Prod Validation
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setToAddresses(new String[] { prodValidationAssignedContact.Email });
                        email.setSubject(task.Name + ' Ready for Prod Validation');
                        email.setPlainTextBody(emailBody);
                        emailMessages2.add(email);
                    }
                }
            }
        }
    
        // Send the email messages for task assignments
        if (!emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }
    
        // Send the second set of email messages with record links
        if (!emailMessages2.isEmpty()) {
            Messaging.sendEmail(emailMessages2);
        }
    }
    
    // Helper method to send email notification for task assignment
    private static void sendAssignmentNotification(Project_Task__c task,  Map<Id, String> emailMap, String baseUrl, List<Messaging.SingleEmailMessage> emailMessages, Id contactId, String assignmentType, String requestor) {
           
        // Create a link to the record
        String recordLink = baseUrl + '/' + task.Id;
        String emailBody = 'Project Task ' + task.Name + ' has been assigned to you for ' + assignmentType + '. ';
        String completedAssignmentType = 'development';
        
        if (assignmentType == 'UAT') {
            completedAssignmentType = 'SIT';
        } else if (assignmentType == 'Prod Validation') {
            completedAssignmentType = 'UAT';
        }
        
        emailBody += 'Once ' + completedAssignmentType + ' has been completed, you will receive another email notification that the project task is ready for testing. \n\n';
        
        if (requestor != null && !String.isBlank(requestor)) {
            emailBody += 'Please review the project task details carefully and contact the requestor ' + requestor + ' if you have any clarifications.\n\n';
        } else {
            emailBody += 'Please review the project task details carefully and contact the requestor if you have any clarifications.\n\n';
        }

        emailBody += 'Click on the link below to view the record:\n' + recordLink;
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { emailMap.get(contactId) });
		email.setSubject(task.Name + ' Project Task assigned to you for ' + assignmentType);
        email.setPlainTextBody(emailBody);
        emailMessages.add(email);
    }
}