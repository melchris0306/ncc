/**
 * Created by angelorivera on 6/12/2022.
 * @revision     21/12/2022 - Von Pernicia [CCN-2429]: updated filter criteria to use "in" statement
 */
public class UpdateCheckpointProgressQueueable implements Queueable {

    public String queryString;
    public String journeyId;

    public UpdateCheckpointProgressQueueable(String jId) {
        journeyId = jId; 
        queryString = ' SELECT Id, Name, Completion_Date__c, Metric_Used__c, Milestone__c, System_Generated__c, ' +
                'Milestone__r.Name, ' +
                'Milestone__r.Journey__c, ' +
                'Milestone__r.Journey__r.Journey__c, ' +
                'Milestone__r.MileStone__r.Related_RecordId__c, ' +
                'Milestone__r.MileStone__r.Name, ' +
                'Milestone__r.Milestone__c, ' +
                'Milestone__r.Milestone__r.Parent__c, ' +
                'Milestone__r.Contact__c, ' +
                'Milestone__r.Type__c, ' +
                'Milestone__r.Checkpoint__c, ' +
                'Milestone__r.Sort_Order__c, ' +
                'Milestone__r.Progress__c, ' +
                'Milestone__r.Checkpoint_Name__c, ' +
                'Milestone__r.Checkpoint_Progress__c ' +
                'FROM Participant_Milestone_Metric__c ' +
            	 // Start CCN-2429: Von Pernicia
                'WHERE Milestone__r.Journey__r.Journey__c in (' + journeyId + ')' +
                 // End CCN-2429: Von Pernicia
                'AND Milestone__r.Is_Active__c = TRUE ' +
                'AND Milestone__r.Checkpoint_Name__c != NULL ' +
                'ORDER BY Milestone__r.Journey__c, Milestone__r.Contact__c, Milestone__r.Sort_Order__c ';
    }

    public void execute(QueueableContext qc) {
        UpdateCheckpointProgressBatch batchObj = new UpdateCheckpointProgressBatch();
        batchObj.strQuery = queryString;
        Id batchProcessId = Database.executeBatch(batchObj,2000);
    }
}