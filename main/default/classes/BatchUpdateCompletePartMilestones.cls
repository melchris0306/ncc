/*******************************************************************************
 * @author       Angelo Rivera
 * @date         18.08.2021
 * @description  CCN-JOU-1245-DV - Updated Completed Milestone Flag in Participant Milestones
 * @revision     21.04.2022- APRivera - Created
 *******************************************************************************/

global class BatchUpdateCompletePartMilestones implements Database.Batchable<SObject>, Schedulable, Database.Stateful{

    public String strQuery = '';
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        
        //CCN-2359 XEN REYES 2.DEC.2022
        strQuery = 'SELECT Id, Milestone_Completed__c, End_Date__c FROM Participant_Milestone__c ' + 
                    'WHERE End_Date__c < TODAY ' +
                    'AND Milestone_Completed__c = FALSE ' + 
                    'AND ((Parent_Milestone__c != null AND Parent_Milestone__r.Is_Active__c = true AND Parent_Milestone__r.RecordType.Name = \'Milestone\') OR Parent_Milestone__c = null)';

        System.debug(LoggingLevel.DEBUG, 'QUERY: ' + strQuery);
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        List<Participant_Milestone__c> lstMilestones = (List<Participant_Milestone__c>)scope;
        List<Participant_Milestone__c> lstMilestonesToUpdate = new List<Participant_Milestone__c>();
        
        if (!lstMilestones.isEmpty()) {
            for(Participant_Milestone__c m : lstMilestones){
                m.Milestone_Completed__c = true;
                lstMilestonesToUpdate.add(m);
            }

            //CCN-2359 XEN REYES 2.DEC.2022
            Database.SaveResult[] srList = Database.update(lstMilestonesToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred. ' + sr.getId());                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage() + ' ' + err.getFields());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {

    }

    global void execute(SchedulableContext sc) {
        BatchUpdateCompletePartMilestones  batchObj = new  BatchUpdateCompletePartMilestones ();
        Id batchProcessId = Database.executeBatch(batchObj,100);
    }
}