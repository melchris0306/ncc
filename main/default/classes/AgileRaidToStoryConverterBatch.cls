/*******************************************************************************************
  * @name: AgileRaidToStoryConverterBatch
  * @author: m.punzal@ulapp.co
  * @created: 26-09-2023
  * @description: Batch Class that Converts Agile RAID to Story
  *
  * Changes (version)
  * -------------------------------------------------------------------------------------------
  *            No.  Date(dd-mm-yyy) Author                Description
  *            ---- ----------       --------------------  -----------------------------
  * @version   1.0  26-09-2023      m.punzal@ulapp.co    [CAPM-AGL-841-DV] Initial version.
  * 		   2.0  16-10-2023      m.punzal@ulapp.co    [CAPM-AGL-915-DV] Added Email alert on finish method.

  *********************************************************************************************/
global class AgileRaidToStoryConverterBatch implements Database.Batchable<SObject>, Database.Stateful {

    List<Project_Task__c> convertedProjectTasks = new List<Project_Task__c>();
    List<Agile_Raid__c> failedAgileRaidConversions = new List<Agile_Raid__c>();
    
    // Start method to initialize and query records
    global Database.QueryLocator start(Database.BatchableContext BC) {
       // String query = 'SELECT Id, CAPM_Project__c, Epic__c, Raised_By__c, Raised_By_Email__c, Date_Raised__c, Description__c FROM Agile_RAID__c WHERE Id=\'a7G1F0000000fTzUAI\'';
        String query = 'SELECT Id, Notes__c, Name, CAPM_Project__r.Project_Code__c,  CAPM_Project__r.Starting_Task_Number__c, CAPM_Project__c, Epic__c, Raised_By__c, Raised_By_Email__c, Date_Raised__c, Description__c FROM Agile_RAID__c WHERE Status__c != \'Converted\' AND (Type__c=\'Requirement\' OR Type__c=\'Idea\')';
        return Database.getQueryLocator(query);
    }

    // Execute method to process each batch of records
    global void execute(Database.BatchableContext BC, List<Agile_Raid__c> scope) {
        // Process each record in the batch
        Map<Id, Agile_Raid__c> mapOfIdAndRaid = new Map<Id, Agile_Raid__c>();
        Map<Id, Project_Task__c> mapOfSourceRAIDAndProjectTaskName = new Map<Id, Project_Task__c>();
        List<Project_Task__c> projectTasksForInsert = new List<Project_Task__c>();
        List<Agile_Raid__c> agileRaidForUpdate = new List<Agile_Raid__c>();
        Id storyRecTypeId = [SELECT Id FROM RecordType WHERE Name = 'Story'].Id;
        Set<Id> agileRaidIds = new Set<Id>();
        Set<Id> raidIdsForChecking = new Set<Id>();
        Set<Id> failedRaidIds = new Set<Id>();
        Group projectTaskQueue = [select Id from Group where DeveloperName='Functional_Team_Queue'];
        
        for (Agile_Raid__c raid : scope) {
        	agileRaidIds.add(raid.Id);
            mapOfIdAndRaid.put(raid.Id, raid);    
        }
        
        Map<Id, Id> mapOfRaidAndProjectTask = new Map<Id, Id>();
        //Get Existing Project Tasks
        for(Project_Task__c projTask: [SELECT Id, Name, Title__c, SourceRAID__r.Id, SourceRAID__c FROM Project_Task__c WHERE SourceRAID__c IN :agileRaidIds]){
            mapOfRaidAndProjectTask.put(projTask.SourceRAID__r.Id, projTask.Id);
        }
        
        
        for (Agile_Raid__c raid : scope) {
            
            if(mapOfRaidAndProjectTask.containsKey(raid.Id)){
            	continue;    
            }
            
            Project_Task__c projTask = new Project_Task__c();
            projTask.Project__c = raid.CAPM_Project__c;
            projTask.Name = raid.CAPM_Project__r.Project_Code__c + ' - ' + raid.CAPM_Project__r.Starting_Task_Number__c;
            projTask.Epic__c = raid.Epic__c;
            projTask.Testing_Types__c = 'Other';
            projTask.RecordTypeId = storyRecTypeId;
            projTask.Requested_By__c = raid.Raised_By__c;
            projTask.Description__c = raid.Description__c;
            projTask.Title__c = String.isNotBlank(raid.Description__c) ? removeHTMLTags(raid.Description__c).left(255) : '';
            projTask.SourceRAID__c = raid.Id;
            projTask.OwnerId = projectTaskQueue.Id;
            projectTasksForInsert.add(projTask);  
        }
        
        Database.SaveResult[] saveResult = Database.insert(projectTasksForInsert, False);
        String errors = '';
        for(Database.SaveResult sr: saveResult){
            if(!sr.isSuccess()){
                for(Database.Error err : sr.getErrors()) {
                    errors += err.getMessage()+'<br/>';
                }
            }
        }
        
        for(Project_Task__c projTask: [SELECT Id, Name, Title__c, SourceRAID__r.Id, SourceRAID__c FROM Project_Task__c WHERE SourceRAID__c IN :agileRaidIds]){
            raidIdsForChecking.add(projTask.SourceRAID__r.Id);
            mapOfSourceRAIDAndProjectTaskName.put(projTask.SourceRAID__c, projTask);
        }
        
        for(Id raidId: agileRaidIds){
            if(!raidIdsForChecking.contains(raidId) && mapOfIdAndRaid.containsKey(raidId)){
                failedAgileRaidConversions.add(mapOfIdAndRaid.get(raidId));
                failedRaidIds.add(raidId);
            }
        }
        for (Agile_Raid__c raid : scope) {
            Agile_Raid__c nRaid = new Agile_Raid__c();
            nRaid.Id = raid.Id;
            
            if(failedRaidIds.contains(raid.Id)){
                String failNote = String.valueOf(DateTime.now().format('MM/dd/yyyy')) + ' - The system attempted to convert this Agile RAID to a Project Task but failed.<br/>'+errors;
                String appendedNote = String.isNotBlank(raid.Notes__c) ? raid.Notes__c + '<br/>' + failNote : failNote;
                nRaid.Notes__c = appendedNote;
            }else{
                
            	nRaid.DateConverted__c = DateTime.now();
                if(mapOfSourceRAIDAndProjectTaskName.containsKey(nRaid.Id)){
                    nRaid.Resolution__c = 'Created Project Task Story - ('+mapOfSourceRAIDAndProjectTaskName.get(nRaid.Id).Name+')';
                    nRaid.ProjectTask__c = mapOfSourceRAIDAndProjectTaskName.get(nRaid.Id).Id;
                    convertedProjectTasks.add(mapOfSourceRAIDAndProjectTaskName.get(nRaid.Id));
                }
                nRaid.Status__c = 'Converted';    
            }

			agileRaidForUpdate.add(nRaid);            
        }
        
        update agileRaidForUpdate;
    }
    
    //Sanitizes HTML Tags on Description field
    private static String removeHTMLTags(String input) {
        // Define a regular expression to match HTML tags
        String regex = '<[^>]+>';
        
        // Replace HTML tags with an empty string
        String sanitizedString = input.replaceAll(regex, '');
        
        return sanitizedString;
    }

    //START - CAPM-AGL-915-DV
    // Finish method to handle any post-processing tasks
    global void finish(Database.BatchableContext BC) {
        String fullRecordURL = URL.getOrgDomainURL().toExternalForm() + '/';
        List<String> sendToEmails = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(User queueMember: [SELECT Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Functional_Team_Queue')]){
            sendToEmails.add(queueMember.Email);
        }
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(sendToEmails);
        // Specify the subject line for your email address.
        mail.setSubject('List of Project Tasks converted from Agile RAIDs for '+String.valueOf(DateTime.now().format('MM/dd/yyyy'))+' batch run for your review');
        // Set to True if you want to BCC yourself on the email.
        mail.setBccSender(false);
        // Specify the text content of the email.
        //mail.setPlainTextBody('Your Case: ' + case.Id +' has been updated.');
      
        String htmlBody = '';
        if(!convertedProjectTasks.isEmpty()){
        	htmlBody += 'The following Project Tasks have been converted from the Agile RAID conversion batch run:<br/>';
            for(Project_Task__c projTask: convertedProjectTasks){
                htmlBody+='<a href="'+(fullRecordURL+projTask.Id)+'">'+projTask.Name+' - ' + projTask.Title__c + '</a><br/>';
            }
            htmlBody+='<br/>Please click on the Project Task links to review and assign as appropriate.';    
        }

        if(!failedAgileRaidConversions.isEmpty()){
            htmlBody+='<br/><br/>Some Agile RAIDs failed to convert to Project Tasks, click on the link below to review:';
                for(Agile_Raid__c raid : failedAgileRaidConversions){
                
                htmlBody+='<p><a href="'+(fullRecordURL+raid.Id)+'">'+raid.Name + (String.isNotBlank(raid.Description__c) ? ' - ' + removeHTMLTags(raid.Description__c) : '') + '</a></p>';
        	}
        }
        
        if(failedAgileRaidConversions.isEmpty() && convertedProjectTasks.isEmpty()){
            htmlBody = 'No Agile RAIDs to convert for today.';
        }
        
        mail.setHtmlBody(htmlBody);
        
        emailList.add(mail);
        Messaging.sendEmail(emailList, false);
    }
    //END - CAPM-AGL-915-DV
}