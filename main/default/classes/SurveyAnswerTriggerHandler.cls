public class SurveyAnswerTriggerHandler extends TriggerHandler{
    protected override void afterInsert(Map<Id, SObject> newRecordsMap){
        // @author: [CCN-858] Updated by dinoBrinas
        // @description: This is used to avoid the recursive on the apex trigger.
        // @date: oct082021
        if(!FlowCallout.bPreventAI){
            FlowCallout.bPreventAI = true;
            FlowCallout.doCallout(newRecordsMap.values());
        }
        // End of update on [CCN-858]
    }
    
    /***** MHM 05/12/2021 removed when update *****
    protected override void afterUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {
        FlowCallout.doCallout(updatedRecordsMap.values());
    }
    ***********************************************/
}