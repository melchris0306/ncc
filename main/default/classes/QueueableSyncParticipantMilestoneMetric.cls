global class QueueableSyncParticipantMilestoneMetric implements System.Queueable {

    public String journeyId;
    public Set<String> journeyIds = new Set<String>();

    public List<SObject> paricipantMilestoneRecsQueueList = new List<SObject>();

    public QueueableSyncParticipantMilestoneMetric(List<SObject> paricipantMilestoneRecs, String journeyId, Set<String> journeyIds) {
        this.paricipantMilestoneRecsQueueList = paricipantMilestoneRecs;
        this.journeyId = journeyId;
        this.journeyIds = journeyIds;
     }

    global void execute(QueueableContext qc){

        BatchSyncParticipantMilestoneMetric batchSync = new BatchSyncParticipantMilestoneMetric();

        batchSync.process(paricipantMilestoneRecsQueueList, journeyId, journeyIds);
    }
}