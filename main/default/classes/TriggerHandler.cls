public with sharing virtual class TriggerHandler {
    @testVisible
    private TriggerOperation triggerContext = Trigger.operationType;
    
    @testVisible
    protected TriggerHandler() {
        if(!Trigger.isExecuting && !Test.isRunningTest()) {
            throw new TriggerHandlerException('TriggerHandler used outside of triggers / testing');
        }
    }
    
    public void execute() {
        switch on triggerContext {
            when BEFORE_INSERT {
                this.beforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                this.beforeUpdate(Trigger.newMap, Trigger.oldMap);
            }
            when BEFORE_DELETE {
                this.beforeDelete(Trigger.oldMap);
            }
            when AFTER_INSERT {
                this.afterInsert(Trigger.newMap);
            }
            when AFTER_UPDATE {
                this.afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
            when AFTER_DELETE {
                this.afterDelete(Trigger.oldMap);
            }
            when AFTER_UNDELETE {
                this.afterUndelete(Trigger.newMap);
            }
        }
    }
    
    protected virtual void beforeInsert(List<SObject> newRecords) {}
    protected virtual void beforeUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {}
    protected virtual void beforeDelete(Map<Id, SObject> deletedRecordsMap) {}
    protected virtual void afterInsert(Map<Id, SObject> newRecordsMap) {}
    protected virtual void afterUpdate(Map<Id, SObject> updatedRecordsMap, Map<Id, SObject> oldRecordsMap) {}
    protected virtual void afterDelete(Map<Id, SObject> deletedRecordsMap) {}
    protected virtual void afterUndelete(Map<Id, SObject> undeletedRecordsMap) {}
    
    protected List<SObject> getUpdatedRecordsWithChangedField(SObjectField field) {
        return this.getUpdatedRecordsWithChangedFields(new List<SObjectField>{ field });
    }
    
    protected List<SObject> getUpdatedRecordsWithChangedFields(List<SObjectField> fields) {
        List<SObject> updatedRecords = new List<SObject>();
        
        for(SObject record : Trigger.new) {
            SObject oldRecord = Trigger.oldMap.get(record.Id);
            for(SObjectField field : fields) {
                if(record.get(field) != oldRecord.get(field)) {
                    updatedRecords.add(record);
                }
            }
        }
        return updatedRecords;
    }
    private class TriggerHandlerException extends Exception {
    }
}